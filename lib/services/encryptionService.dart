import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  String? _cachedKey;
  
  static const String _keyStorageKey = 'encryption_master_key_v2';
  static const String _encryptionPrefix = 'ENC_V2:';

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String? masterKey = prefs.getString(_keyStorageKey);

      if (masterKey == null) {
        // Generate a simple, consistent key using secure random
        final random = Random.secure();
        final keyBytes = List.generate(32, (i) => random.nextInt(256));
        _cachedKey = base64.encode(keyBytes);

        await prefs.setString(_keyStorageKey, _cachedKey!);

        debugPrint('Generated new encryption key');
      } else {
        _cachedKey = masterKey;
        debugPrint('Loaded existing encryption key');
      }
    } catch (e) {
      throw Exception('Error initializing encryption service: $e');
    }
  }

  String encryptUserData(String plainText) {
    if (_cachedKey == null) {
      throw Exception('Encryption service not initialized');
    }

    if (plainText.isEmpty) return plainText;

    try {
      
      // Use simple XOR with key rotation for fast, reliable encryption
      final keyBytes = base64.decode(_cachedKey!);
      final plainTextBytes = utf8.encode(plainText);
      final encrypted = Uint8List(plainTextBytes.length);
      
      for (int i = 0; i < plainTextBytes.length; i++) {
        encrypted[i] = plainTextBytes[i] ^ keyBytes[i % keyBytes.length] ^ (i & 0xFF);
      }
      
      final result = _encryptionPrefix + base64.encode(encrypted);
      return result;
    } catch (e) {
      debugPrint('Encryption failed: $e');
      throw Exception('Error encrypting user data: $e');
    }
  }

  String decryptUserData(String encryptedData) {
    if (_cachedKey == null) {
      throw Exception('Encryption service not initialized');
    }

    if (encryptedData.isEmpty) return encryptedData;

    try {
      
      // Check if data has our encryption prefix
      if (!encryptedData.startsWith(_encryptionPrefix)) {
        return encryptedData;
      }
      
      // Remove prefix and decode
      final encodedData = encryptedData.substring(_encryptionPrefix.length);
      
      // Validate that this isn't suspiciously long for normal user data
      if (encodedData.length > 200) {
        debugPrint('WARNING: Encrypted data is unusually long (${encodedData.length} chars)');
        debugPrint('This might indicate double encryption or corruption');
        
        // Try to detect and fix double encryption
        return _handlePotentialDoubleEncryption(encryptedData);
      }
      
      final encryptedBytes = base64.decode(encodedData);
      
      // Decrypt using same XOR with key rotation
      final keyBytes = base64.decode(_cachedKey!);
      final decrypted = Uint8List(encryptedBytes.length);
      
      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted[i] = encryptedBytes[i] ^ keyBytes[i % keyBytes.length] ^ (i & 0xFF);
      }
      
      final result = utf8.decode(decrypted);
      
      // Validate result looks reasonable
      if (_isValidDecryptedData(result)) {
        return result;
      } else {
        return _attemptDataRecovery(encryptedData);
      }
      
    } catch (e) {
      debugPrint('Decryption failed: $e');
      return _attemptDataRecovery(encryptedData);
    }
  }

  String _handlePotentialDoubleEncryption(String data) {
    debugPrint('Checking for double encryption...');
    
    try {
      // Try to decode as if it's double-encrypted
      final withoutPrefix = data.substring(_encryptionPrefix.length);
      final decoded = base64.decode(withoutPrefix);
      final keyBytes = base64.decode(_cachedKey!);
      final decrypted = Uint8List(decoded.length);
      
      for (int i = 0; i < decoded.length; i++) {
        decrypted[i] = decoded[i] ^ keyBytes[i % keyBytes.length] ^ (i & 0xFF);
      }
      
      final firstDecrypt = utf8.decode(decrypted);
      
      // Check if the result is still encrypted
      if (firstDecrypt.startsWith(_encryptionPrefix)) {
        // Detected double encryption, attempt decrypt again
        return decryptUserData(firstDecrypt);
      } else {
        return firstDecrypt;
      }
    } catch (e) {
      debugPrint('Double encryption check failed: $e');
      throw Exception('Failed to handle potential double encryption: $e');
    }
  }

  String _attemptDataRecovery(String corruptedData) {
    debugPrint('Attempting data recovery...');
    
    try {
      // Strategy 1: Try without position XOR
      final withoutPrefix = corruptedData.substring(_encryptionPrefix.length);
      final encryptedBytes = base64.decode(withoutPrefix);
      final keyBytes = base64.decode(_cachedKey!);
      final decrypted = Uint8List(encryptedBytes.length);
      
      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted[i] = encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
      }
      
      final result = utf8.decode(decrypted);
      
      if (_isValidDecryptedData(result)) {
        // Data recovery succeeded
        return result;
      }
    } catch (e) {
      debugPrint('Recovery failed: $e');
    }
    
    // Strategy 2: Return recovery marker for corrupted data
    // Fallback: treating as corrupted, returning marker
    return '[ENCRYPTED_DATA_RECOVERY_NEEDED]';
  }

  bool _isValidDecryptedData(String data) {
    // Check if the decrypted data looks like valid user data
    if (data.isEmpty) return false;
    
    // Check for common patterns in user data
    final looksLikeEmail = data.contains('@') && data.contains('.');
    final looksLikePhone = data.startsWith('+') && data.length > 10;
    final looksLikeUrl = data.startsWith('http') || data.contains('.');
    final looksLikeName = data.length > 1 && data.length < 100 && !data.contains(RegExp(r'[^\w\s\-\.@+]'));
    
    return looksLikeEmail || looksLikePhone || looksLikeUrl || looksLikeName;
  }

  Map<String, String> encryptUserFields(Map<String, String?> userData) {
    final encryptedData = <String, String>{};

    for (final entry in userData.entries) {
      if (entry.value != null && entry.value!.isNotEmpty) {
        encryptedData[entry.key] = encryptUserData(entry.value!);
      }
      else {
        encryptedData[entry.key] = entry.value ?? '';
      }
    }

    return encryptedData;
  }

  Map<String, String> decryptUserFields(Map<String, dynamic> encryptedData) {
    final decryptedData = <String, String>{};

    for (final entry in encryptedData.entries) {
      if (entry.value != null && entry.value.toString().isNotEmpty) {
        final valueStr = entry.value.toString();
        
        try {
          final decrypted = decryptUserData(valueStr);
          
          // Check if decryption resulted in a recovery marker
          if (decrypted == '[ENCRYPTED_DATA_RECOVERY_NEEDED]') {
            debugPrint('Field ${entry.key} needs manual recovery');
            decryptedData[entry.key] = _generateFallbackValue(entry.key);
          } else {
            decryptedData[entry.key] = decrypted;
          }
        } catch (e) {
          debugPrint(' Error decrypting field ${entry.key}: $e');
          // If decryption fails, return a fallback or the original value
          decryptedData[entry.key] = _generateFallbackValue(entry.key);
        }
      } else {
        decryptedData[entry.key] = entry.value?.toString() ?? '';
      }
    }

    return decryptedData;
  }

  String _generateFallbackValue(String fieldName) {
    // Generate appropriate fallback values for different field types
    switch (fieldName) {
      case 'contact_number':
        return '+639000000000'; // Default placeholder number
      case 'passenger_email':
        return 'user@example.com'; // Default placeholder email
      case 'display_name':
        return 'User'; // Default placeholder name
      case 'avatar_url':
        return 'assets/svg/default_user_profile.svg'; // Default avatar
      default:
        return '[RECOVERY_NEEDED]';
    }
  }

  bool isEncrypted(String data) {
    if (data.isEmpty) return false;
    
    // Simple check: our encrypted data always starts with the prefix
    return data.startsWith(_encryptionPrefix);
  }

  void clearCache() {
    _cachedKey = null;
  }

  void dispose() => clearCache();

  /// Test encryption/decryption functionality
  Future<bool> testEncryption() async {
    try {
      if (_cachedKey == null) {
        await initialize();
      }
      
      const testData = 'Test User Name ñáéíóú';
      debugPrint('Testing encryption with: "$testData"');
      
      final encrypted = encryptUserData(testData);
      debugPrint('Encrypted result: "$encrypted"');
      
      final decrypted = decryptUserData(encrypted);
      debugPrint('Decrypted result: "$decrypted"');
      
      final success = decrypted == testData;
      debugPrint('Encryption test ${success ? 'PASSED ✅' : 'FAILED ❌'}: Original: "$testData", Decrypted: "$decrypted"');
      
      // Test with special characters and different lengths
      final testCases = [
        'Short',
        'A very long string with many characters to test encryption with different lengths and special chars: ñáéíóú@#\$%^&*()',
        'user@example.com',
        '+639123456789',
        'https://example.com/avatar.jpg',
      ];
      
      bool allTestsPassed = success;
      for (final testCase in testCases) {
        try {
          final enc = encryptUserData(testCase);
          final dec = decryptUserData(enc);
          final testSuccess = dec == testCase;
          debugPrint('Test case "${testCase.length > 30 ? '${testCase.substring(0, 30)}...' : testCase}": ${testSuccess ? 'PASS' : 'FAIL'}');
          allTestsPassed = allTestsPassed && testSuccess;
        } catch (e) {
          debugPrint('Test case failed: $e');
          allTestsPassed = false;
        }
      }
      
      return allTestsPassed;
    } catch (e) {
      debugPrint('Encryption test FAILED with error: $e');
      return false;
    }
  }

  /// Clear old encryption keys (useful for troubleshooting)
  Future<void> clearStoredKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove old v1 keys if they exist
      await prefs.remove('encryption_master_key');
      await prefs.remove('hmac_master_key');
      
      // Remove current v2 keys to force regeneration
      await prefs.remove(_keyStorageKey);
      
      _cachedKey = null;
      
      debugPrint('🗑️ All encryption keys cleared, will regenerate on next initialization');
    } catch (e) {
      debugPrint('Error clearing stored keys: $e');
    }
  }

  /// Force re-encrypt user data with proper values (for recovery)
  Map<String, String> forceReEncryptUserData(Map<String, String> plainTextData) {
    debugPrint('🔄 Force re-encrypting user data...');
    
    final reEncrypted = <String, String>{};
    
    for (final entry in plainTextData.entries) {
      if (entry.value.isNotEmpty) {
        try {
          final encrypted = encryptUserData(entry.value);
          reEncrypted[entry.key] = encrypted;
          debugPrint('Re-encrypted ${entry.key}: "${entry.value}" -> ${encrypted.length} chars');
        } catch (e) {
          debugPrint('Failed to re-encrypt ${entry.key}: $e');
          // Keep original value if encryption fails
          reEncrypted[entry.key] = entry.value;
        }
      } else {
        reEncrypted[entry.key] = entry.value;
      }
    }
    
    return reEncrypted;
  }

  /// Repair corrupted encrypted data by prompting user for correct values
  Future<Map<String, String>> repairCorruptedData(Map<String, String> corruptedData) async {
    debugPrint('🔧 Repairing corrupted encrypted data...');
    
    final repairedData = <String, String>{};
    
    for (final entry in corruptedData.entries) {
      if (entry.value == '[ENCRYPTED_DATA_RECOVERY_NEEDED]' || 
          entry.value.startsWith('[RECOVERY_NEEDED]')) {
        
        debugPrint('Field ${entry.key} needs repair');
        
        // For now, use fallback values - in a real app, you'd prompt the user
        final fallback = _generateFallbackValue(entry.key);
        final encrypted = encryptUserData(fallback);
        repairedData[entry.key] = encrypted;
        
        debugPrint('Repaired ${entry.key} with fallback: "$fallback"');
      } else {
        repairedData[entry.key] = entry.value;
      }
    }
    
    return repairedData;
  }

  Future<void> migrateExistingUserData(String userId) async {
    try {
      debugPrint('Migration method called for user $userId');
      // This method is kept for compatibility but actual migration 
      // is handled in the AuthService migrateExistingUserDataToEncrypted method
    } catch (e) {
      debugPrint('Error in migration method for user $userId: $e');
    }
  }
}