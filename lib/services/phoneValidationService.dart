import 'package:flutter/foundation.dart';
import 'package:pasada_passenger_app/services/encryptionService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhoneValidationService {
  static final SupabaseClient supabase = Supabase.instance.client;

  /// Check if a phone number is already registered by decrypting existing phone numbers
  /// Returns true if phone number is available (not registered), false if already exists
  static Future<bool> isPhoneNumberAvailable(String phoneNumber) async {
    try {
      // Format the phone number consistently
      final formattedPhone =
          phoneNumber.startsWith('+63') ? phoneNumber : '+63$phoneNumber';

      // Get all passenger records with contact numbers
      final response = await supabase
          .from('passenger')
          .select('contact_number')
          .not('contact_number', 'is', null);

      if (response.isEmpty) {
        return true; // No existing phone numbers, so this one is available
      }

      // Initialize encryption service
      final encryptionService = EncryptionService();
      await encryptionService.initialize();

      // Check each existing phone number by decrypting it
      for (final record in response) {
        final encryptedPhone = record['contact_number'] as String?;
        if (encryptedPhone == null || encryptedPhone.isEmpty) continue;

        try {
          // Decrypt the stored phone number
          final decryptedPhone =
              await encryptionService.decryptUserData(encryptedPhone);

          // Check if it matches the phone number we're trying to register
          if (decryptedPhone == formattedPhone) {
            debugPrint('Phone number $formattedPhone is already registered');
            return false; // Phone number already exists
          }
        } catch (e) {
          // If decryption fails, check if it's plain text (for backward compatibility)
          if (encryptedPhone == formattedPhone) {
            debugPrint(
                'Phone number $formattedPhone is already registered (plain text)');
            return false; // Phone number already exists
          }
          debugPrint('Failed to decrypt phone number: $e');
        }
      }

      debugPrint('Phone number $formattedPhone is available');
      return true; // Phone number is available
    } catch (e) {
      debugPrint('Error checking phone number availability: $e');
      // In case of error, assume it's available to avoid blocking legitimate users
      // But log the error for investigation
      return true;
    }
  }

  /// Check if a phone number is already registered (for profile updates)
  /// Excludes the current user's phone number from the check
  static Future<bool> isPhoneNumberAvailableForUpdate(
      String phoneNumber, String currentUserId) async {
    try {
      // Format the phone number consistently
      final formattedPhone =
          phoneNumber.startsWith('+63') ? phoneNumber : '+63$phoneNumber';

      // Get all passenger records with contact numbers, excluding current user
      final response = await supabase
          .from('passenger')
          .select('contact_number')
          .not('contact_number', 'is', null)
          .neq('id', currentUserId);

      if (response.isEmpty) {
        return true; // No other phone numbers exist, so this one is available
      }

      // Initialize encryption service
      final encryptionService = EncryptionService();
      await encryptionService.initialize();

      // Check each existing phone number by decrypting it
      for (final record in response) {
        final encryptedPhone = record['contact_number'] as String?;
        if (encryptedPhone == null || encryptedPhone.isEmpty) continue;

        try {
          // Decrypt the stored phone number
          final decryptedPhone =
              await encryptionService.decryptUserData(encryptedPhone);

          // Check if it matches the phone number we're trying to update to
          if (decryptedPhone == formattedPhone) {
            debugPrint(
                'Phone number $formattedPhone is already registered by another user');
            return false; // Phone number already exists
          }
        } catch (e) {
          // If decryption fails, check if it's plain text (for backward compatibility)
          if (encryptedPhone == formattedPhone) {
            debugPrint(
                'Phone number $formattedPhone is already registered by another user (plain text)');
            return false; // Phone number already exists
          }
          debugPrint('Failed to decrypt phone number: $e');
        }
      }

      debugPrint('Phone number $formattedPhone is available for update');
      return true; // Phone number is available
    } catch (e) {
      debugPrint('Error checking phone number availability for update: $e');
      // In case of error, assume it's available to avoid blocking legitimate users
      // But log the error for investigation
      return true;
    }
  }
}
