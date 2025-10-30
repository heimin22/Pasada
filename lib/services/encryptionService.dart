import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  String? _cachedKey; // legacy device key (V2)
  late final SecretKey _aesKey; // global key for V3
  bool _v3Ready = false;

  static const String _keyStorageKey = 'encryption_master_key_v2';
  static const String _encryptionPrefixV2 = 'ENC_V2:'; // legacy XOR
  static const String _encryptionPrefixV3 = 'ENC_V3:'; // new AES-GCM
  static const String _envKeyName = 'ENCRYPTION_MASTER_KEY_B64';

  final AesGcm _aesGcm = AesGcm.with256bits();
  final Random _rng = Random.secure();

  Future<void> initialize() async {
    try {
      // Load V3 global key from env, only once
      if (!_v3Ready) {
        final envVal = dotenv.env[_envKeyName];
        if (envVal != null && envVal.isNotEmpty) {
          final keyBytes = base64.decode(envVal);
          if (keyBytes.length != 32) {
            throw Exception('$_envKeyName must be 32 bytes (base64)');
          }
          _aesKey = SecretKey(keyBytes);
          _v3Ready = true;
        } else {
          // quiet: missing env just disables V3
        }
      }

      // Load legacy device key (V2) for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      String? masterKey = prefs.getString(_keyStorageKey);
      if (masterKey == null) {
        final keyBytes = List.generate(32, (i) => _rng.nextInt(256));
        _cachedKey = base64.encode(keyBytes);
        await prefs.setString(_keyStorageKey, _cachedKey!);
        // quiet
      } else {
        _cachedKey = masterKey;
        // quiet
      }
    } catch (e) {
      throw Exception('Error initializing encryption service: $e');
    }
  }

  // Public API (async)
  Future<String> encryptUserData(String plainText) async {
    if (plainText.isEmpty) return plainText;
    if (_v3Ready) {
      return await _encryptV3(plainText);
    }
    // Fallback to legacy V2 if no global key available
    return _encryptV2(plainText);
  }

  Future<String> decryptUserData(String data) async {
    if (data.isEmpty) return data;

    try {
      if (data.startsWith(_encryptionPrefixV3)) {
        final payload = data.substring(_encryptionPrefixV3.length);
        return await _decryptV3(payload);
      }
      if (data.startsWith(_encryptionPrefixV2)) {
        return _decryptV2(data);
      }
      // plaintext or unknown prefix
      return data;
    } catch (e) {
      debugPrint('Decryption failed: $e');
      return '[ENCRYPTED_DATA_RECOVERY_NEEDED]';
    }
  }

  Future<Map<String, String>> encryptUserFields(
      Map<String, String?> userData) async {
    final out = <String, String>{};
    for (final entry in userData.entries) {
      if (entry.value != null && entry.value!.isNotEmpty) {
        out[entry.key] = await encryptUserData(entry.value!);
      } else {
        out[entry.key] = entry.value ?? '';
      }
    }
    return out;
  }

  Future<Map<String, String>> decryptUserFields(
      Map<String, dynamic> encryptedData) async {
    final out = <String, String>{};
    for (final entry in encryptedData.entries) {
      final val = entry.value?.toString() ?? '';
      if (val.isNotEmpty) {
        try {
          final dec = await decryptUserData(val);
          if (dec == '[ENCRYPTED_DATA_RECOVERY_NEEDED]') {
            debugPrint('Field ${entry.key} needs manual recovery');
            out[entry.key] = _generateFallbackValue(entry.key);
          } else {
            out[entry.key] = dec;
          }
        } catch (_) {
          out[entry.key] = _generateFallbackValue(entry.key);
        }
      } else {
        out[entry.key] = val;
      }
    }
    return out;
  }

  bool isEncrypted(String data) {
    if (data.isEmpty) return false;
    return data.startsWith(_encryptionPrefixV3) ||
        data.startsWith(_encryptionPrefixV2);
  }

  // V3 AES-GCM
  Future<String> _encryptV3(String plainText) async {
    final nonce = Uint8List(12);
    for (var i = 0; i < nonce.length; i++) {
      nonce[i] = _rng.nextInt(256);
    }
    final clear = utf8.encode(plainText);
    final secretBox = await _aesGcm.encrypt(
      clear,
      secretKey: _aesKey,
      nonce: nonce,
    );
    // Pack: nonce(12) | ciphertext | tag(16)
    final combined = BytesBuilder(copy: false)
      ..add(nonce)
      ..add(secretBox.cipherText)
      ..add(secretBox.mac.bytes);
    return _encryptionPrefixV3 + base64.encode(combined.toBytes());
  }

  Future<String> _decryptV3(String payloadB64) async {
    final raw = base64.decode(payloadB64);
    if (raw.length < 12 + 16) {
      throw const FormatException('Ciphertext too short');
    }
    final nonce = raw.sublist(0, 12);
    final mac = Mac(raw.sublist(raw.length - 16));
    final cipherText = raw.sublist(12, raw.length - 16);

    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    final clear = await _aesGcm.decrypt(secretBox, secretKey: _aesKey);
    return utf8.decode(clear);
  }

  // V2 legacy XOR (unchanged logic)
  String _encryptV2(String plainText) {
    if (_cachedKey == null) {
      throw Exception('Encryption service not initialized');
    }
    final keyBytes = base64.decode(_cachedKey!);
    final plainTextBytes = utf8.encode(plainText);
    final encrypted = Uint8List(plainTextBytes.length);
    for (int i = 0; i < plainTextBytes.length; i++) {
      encrypted[i] =
          plainTextBytes[i] ^ keyBytes[i % keyBytes.length] ^ (i & 0xFF);
    }
    return _encryptionPrefixV2 + base64.encode(encrypted);
  }

  String _decryptV2(String encryptedData) {
    if (_cachedKey == null) {
      throw Exception('Encryption service not initialized');
    }
    final encodedData = encryptedData.substring(_encryptionPrefixV2.length);
    final encryptedBytes = base64.decode(encodedData);
    final keyBytes = base64.decode(_cachedKey!);
    final decrypted = Uint8List(encryptedBytes.length);
    for (int i = 0; i < encryptedBytes.length; i++) {
      decrypted[i] =
          encryptedBytes[i] ^ keyBytes[i % keyBytes.length] ^ (i & 0xFF);
    }
    final result = utf8.decode(decrypted);
    if (_isValidDecryptedData(result)) {
      return result;
    }
    // attempt without index XOR
    for (int i = 0; i < encryptedBytes.length; i++) {
      decrypted[i] = encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return utf8.decode(decrypted);
  }

  bool _isValidDecryptedData(String data) {
    if (data.isEmpty) return false;
    final looksLikeEmail = data.contains('@') && data.contains('.');
    final looksLikePhone = data.startsWith('+') && data.length > 10;
    final looksLikeUrl = data.startsWith('http') || data.contains('.');
    final looksLikeName = data.length > 1 &&
        data.length < 100 &&
        !data.contains(RegExp(r'[^\w\s\-\.@+]'));
    return looksLikeEmail || looksLikePhone || looksLikeUrl || looksLikeName;
  }

  String _generateFallbackValue(String fieldName) {
    switch (fieldName) {
      case 'contact_number':
        return '+639000000000';
      case 'passenger_email':
        return 'user@example.com';
      case 'display_name':
        return 'User';
      case 'avatar_url':
        return 'assets/svg/default_user_profile.svg';
      default:
        return '[RECOVERY_NEEDED]';
    }
  }

  void clearCache() {
    _cachedKey = null;
  }

  void dispose() => clearCache();

  // Utility: quick self-test to ensure encryption/decryption works
  Future<bool> testEncryption() async {
    try {
      final sample = 'encryption-self-test';
      final enc = await encryptUserData(sample);
      final dec = await decryptUserData(enc);
      return dec == sample;
    } catch (_) {
      return false;
    }
  }

  // Utility: force re-encrypt a set of user fields (from plaintext)
  Future<Map<String, String>> forceReEncryptUserData(
      Map<String, String?> data) async {
    return await encryptUserFields(data);
  }
}
