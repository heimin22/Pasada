import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:pasada_passenger_app/utils/toast_utils.dart';
import 'package:pasada_passenger_app/services/encryptionService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

extension on AppLinks {
  Future<Uri?> getInitialAppLink() async {
    return getInitialLink();
  }
}

class AuthService {
  // supabase client instance
  final SupabaseClient supabase = Supabase.instance.client;

  // singleton pattern
  static final AuthService _instance = AuthService.internal();

  // internet connection
  final Connectivity connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> connectivitySubscription;

  // database passengers
  final passengersDatabase = Supabase.instance.client.from('passenger');

  // rate limit for password reset
  final supabaseRateLimit = Supabase.instance.client;
  final _lastResetAttempts = <String, DateTime>{};

  void initState() {
    checkInitialConnectivity();
    connectivitySubscription =
        connectivity.onConnectivityChanged.listen(updateConnectionStatus);
  }

  Future<void> checkInitialConnectivity() async {
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      ToastUtils.showError('No internet connection detected. Please check your network settings.');
    }
  }

  void updateConnectionStatus(List<ConnectivityResult> result) {
    if (result.contains(ConnectivityResult.none)) {
      ToastUtils.showError('Internet connection lost. Please check your network settings.');
    }
  }

  factory AuthService() {
    return _instance;
  }

  AuthService.internal();

  // login with email and password
  Future<AuthResponse> login(String email, String password) async {
    // checking internet connection of the device
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      throw Exception("No internet connection");
    }
    
    try {
      AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed: No user data received');
      }

      return response;
    } on AuthException catch (e) {
      debugPrint('Auth error during login: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during login: $e');
      throw Exception('Failed to login: $e');
    }
  }

  // implement nga tayong bagong method nigga
  // putangina hihiwalay ko na lang to para malupet
  // so ito yung para sa Supabase Authentication kasi tangina niyong lahat
  Future<AuthResponse> signUpAuth(String email, String password,
      {Map<String, dynamic>? data}) async {
    try {
      // Check if phone number exists if provided (handles plain and encrypted)
      if (data?['contact_number'] != null) {
        final String plainPhone = data!['contact_number'];
        final encryptionService = EncryptionService();
        await encryptionService.initialize();

        final String encryptedPhone = await encryptionService.encryptUserData(plainPhone);

        final existingPhoneData = await supabase
            .from('passenger')
            .select()
            .or('contact_number.eq.$plainPhone,contact_number.eq.$encryptedPhone')
            .maybeSingle();

        if (existingPhoneData != null) {
          throw Exception('Phone number already registered');
        }
      }

      // Sign up the user
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: data,
      );

      if (response.user == null) {
        throw Exception('Failed to create account');
      }

      try {
        // Encrypt sensitive user data before storing
        final encryptionService = EncryptionService();
        await encryptionService.initialize();
        
        final encryptedData = await encryptionService.encryptUserFields({
          'display_name': data?['display_name'],
          'contact_number': data?['contact_number'],
          'passenger_email': email,
          'avatar_url': data?['avatar_url'] ?? 'assets/svg/default_user_profile.svg',
        });

        // Then, insert into passenger table with encrypted data
        await supabase.from('passenger').upsert({
          'id': response.user!.id,
          'passenger_email': encryptedData['passenger_email'],
          'display_name': encryptedData['display_name'],
          'contact_number': encryptedData['contact_number'],
          'avatar_url': encryptedData['avatar_url'],
          'created_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id');
      } catch (dbError) {
        // If passenger table insertion fails, delete the auth user
        await supabase.auth.admin.deleteUser(response.user!.id);
        throw Exception('Failed to create user profile');
      }

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<bool> checkNetworkConnection() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      ToastUtils.showError('No internet connection. Please check your network and try again.');
      return false;
    }
    return true;
  }

  Future<bool> signInWithGoogle() async {
    // check the internet connection
    if (!await checkNetworkConnection()) return false;

    try {
      final response = await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'pasada://login-callback',
        queryParams: {
          'access_type': 'offline',
          'prompt': 'consent',
          'close': 'true',
        },
        authScreenLaunchMode: LaunchMode.externalNonBrowserApplication,
      );

      if (!response) {
        debugPrint('Google sign-in failed');
        return false;
      }

      // wait for the auth state to change
      final completer = Completer<bool>();
      late StreamSubscription<AuthState> authSub;

      authSub = supabase.auth.onAuthStateChange.listen((AuthState state) async {
        debugPrint('Auth state changed: ${state.event}');
        if (state.event == AuthChangeEvent.signedIn && state.session != null) {
          final user = supabase.auth.currentUser;
          if (user != null) {
            final userMetadata = user.userMetadata;
            final avatarUrl = userMetadata?['picture'] ?? '';

            final existingUser = await supabase
                .from('passenger')
                .select()
                .eq('id', user.id)
                .maybeSingle();

            final displayName = userMetadata?['full_name'] ?? '';

            if (existingUser == null) {
              // Encrypt before insert
              final encryptionService = EncryptionService();
              await encryptionService.initialize();
              final encrypted = await encryptionService.encryptUserFields({
                'passenger_email': user.email,
                'display_name': displayName,
                'avatar_url': avatarUrl,
              });
              await passengersDatabase.insert({
                'id': user.id,
                'passenger_email': encrypted['passenger_email'],
                'display_name': encrypted['display_name'],
                'avatar_url': encrypted['avatar_url'],
                'created_at': DateTime.now().toIso8601String(),
              });
            } else {
              // Encrypt before update
              final encryptionService = EncryptionService();
              await encryptionService.initialize();
              final encrypted = await encryptionService.encryptUserFields({
                'avatar_url': avatarUrl,
                'display_name': displayName,
                'passenger_email': user.email,
              });
              await passengersDatabase.update({
                'avatar_url': encrypted['avatar_url'],
                'display_name': encrypted['display_name'],
                'passenger_email': encrypted['passenger_email'],
              }).eq('id', user.id);
            }
            completer.complete(true);
          }
        }
      });

      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Auth state change timeout');
          authSub.cancel();
          return false;
        },
      );
    } catch (e) {
      debugPrint('Error during Google sign-in: $e');
      return false;
    }
  }

  Future<bool> checkResetPasswordRateLimit(String email) async {
    final lastAttempt = _lastResetAttempts[email];
    final now = DateTime.now();

    if (lastAttempt != null && now.difference(lastAttempt).inSeconds < 60) {
      return false;
    }

    _lastResetAttempts[email] = now;
    return true;
  }

  // initialize deep link handling for auth callbacks
  Future<void> initDeepLinkHandling() async {
    try {
      final appLinks = AppLinks();

      // listen for app links while the app is running
      appLinks.uriLinkStream.listen((Uri? uri) async {
        if (uri != null &&
            uri.scheme == 'pasada' &&
            uri.host == 'login-callback') {
          // the app was opened via the redirect URL, handle the auth callback
          // Supabase SDK should automatically handle the session
          await supabase.auth.getSessionFromUrl(uri);
        }
      }, onError: (error) {
        return;
      });

      // check for initial link if the app was started from a link
      final initialLink = await appLinks.getInitialAppLink();
      if (initialLink != null &&
          initialLink.scheme == 'pasada' &&
          initialLink.host == 'login-callback') {
        // the app was opened from the redirect URL, handle the auth callback
        // Supabase SDK should automatically handle the session
        await supabase.auth.getSessionFromUrl(initialLink);
      }
    } catch (e) {
      return;
    }
  }

  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  // get current user email
  String? getCurrentUserEmail() {
    final session = supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  // gathering user information
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('passenger')
            .select()
            .eq('id', user.id)
            .single();

        // Decrypt sensitive user data
        final encryptionService = EncryptionService();
        await encryptionService.initialize();

        // Self-heal: if any fields are still plaintext, encrypt them in DB now
        final fieldsToCheck = {
          'display_name': response['display_name']?.toString() ?? '',
          'contact_number': response['contact_number']?.toString() ?? '',
          'passenger_email': response['passenger_email']?.toString() ?? '',
          'avatar_url': response['avatar_url']?.toString() ?? '',
        };
        final toEncryptUpdate = <String, String>{};
        for (final entry in fieldsToCheck.entries) {
          final key = entry.key;
          final value = entry.value;
          if (value.isNotEmpty && !encryptionService.isEncrypted(value)) {
            toEncryptUpdate[key] = await encryptionService.encryptUserData(value);
          }
        }
        if (toEncryptUpdate.isNotEmpty) {
          try {
            await passengersDatabase.update(toEncryptUpdate).eq('id', user.id);
          } catch (e) {
            debugPrint('Self-heal encryption update failed: $e');
          }
        }
        final decryptedData = await encryptionService.decryptUserFields({
          'display_name': response['display_name'],
          'contact_number': response['contact_number'],
          'passenger_email': response['passenger_email'],
          'avatar_url': response['avatar_url'],
        });

        // Return decrypted data with original structure
        return {
          ...response,
          'display_name': decryptedData['display_name'],
          'contact_number': decryptedData['contact_number'],
          'passenger_email': decryptedData['passenger_email'],
          'avatar_url': decryptedData['avatar_url'],
        };
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  Future<String?> uploadNewProfileImage(File imageFile) async {
    try {
      // generate a unique file name using timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExt = imageFile.path.split('.').last;
      final fileName = 'avatar_$timestamp.$fileExt';

      // upload the file to Supabase Storage
      final response =
          await supabase.storage.from('avatars').upload(fileName, imageFile);

      if (response.isEmpty) {
        throw Exception('Failed to upload image');
      }

      // get the public URL of the uploaded file
      final imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      throw Exception('Failed to upload profile image');
    }
  }

  Future<void> updateProfile({
    required String displayName,
    required String email,
    required String mobileNumber,
    String? avatarUrl,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // remove the '+63' prefix if it exists in the mobile number
      final formattedMobileNumber =
          mobileNumber.startsWith('+63') ? mobileNumber : '+63$mobileNumber';

      // Encrypt sensitive data before updating
      final encryptionService = EncryptionService();
      await encryptionService.initialize();
      final encryptedData = await encryptionService.encryptUserFields({
        'display_name': displayName,
        'passenger_email': email,
        'contact_number': formattedMobileNumber,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      });

      // update the passenger table with encrypted data
      await passengersDatabase.update({
        'display_name': encryptedData['display_name'],
        'passenger_email': encryptedData['passenger_email'],
        'contact_number': encryptedData['contact_number'],
        if (avatarUrl != null) 'avatar_url': encryptedData['avatar_url'],
      }).eq('id', user.id);

      // update auth metadata if needed
      await supabase.auth.updateUser(
        UserAttributes(
          email: email,
          data: {
            'display_name': displayName,
          },
        ),
      );
    } catch (e) {
      debugPrint('Error updating profile: $e');
      throw Exception('Failed to update profile');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: null,
      );

      // Update last attempt time after successful send
      _lastResetAttempts[email] = DateTime.now();
    } catch (e) {
      debugPrint('Error in sendPasswordResetEmail: $e');
      if (e.toString().contains('429')) {
        throw Exception('rate_limit');
      }
      rethrow;
    }
  }

  Future<void> verifyPasswordResetCode({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );

      if (response.session != null && newPassword.isNotEmpty) {
        await supabase.auth.updateUser(
          UserAttributes(password: newPassword),
        );
      }
    } catch (e) {
      debugPrint('Error in verifyPasswordResetCode: $e');
      if (e.toString().contains('429')) {
        throw Exception('rate_limit');
      } else if (e.toString().contains('Invalid')) {
        throw Exception('Invalid or expired authentication code');
      }
      throw Exception('Failed to verify password reset code');
    }
  }

  /// Check if the current user is linked to a Google account
  bool isGoogleLinkedAccount() {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return false;

    // Check if the provider is Google or if any identity is from Google
    return currentUser.appMetadata['provider'] == 'google' ||
        currentUser.identities
                ?.any((identity) => identity.provider == 'google') ==
            true;
  }

  /// Manually sync Google profile data for Google-linked accounts
  Future<bool> syncGoogleProfile() async {
    if (!isGoogleLinkedAccount()) {
      debugPrint('User is not linked to Google account');
      return false;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      final userMetadata = user.userMetadata;
      final avatarUrl = userMetadata?['picture'] ?? '';
      final displayName = userMetadata?['full_name'] ?? '';

      // Update the passenger table with latest Google data
      final encryptionService = EncryptionService();
      await encryptionService.initialize();
      final encrypted = await encryptionService.encryptUserFields({
        'passenger_email': user.email,
        'avatar_url': avatarUrl,
        'display_name': displayName,
      });
      await passengersDatabase.update({
        'passenger_email': encrypted['passenger_email'],
        'avatar_url': encrypted['avatar_url'],
        'display_name': encrypted['display_name'],
      }).eq('id', user.id);

      debugPrint('Google profile synced successfully');
      return true;
    } catch (e) {
      debugPrint('Error syncing Google profile: $e');
      return false;
    }
  }

  /// Enhanced update profile method that respects Google account constraints
  Future<void> updateProfileEnhanced({
    required String displayName,
    required String email,
    required String mobileNumber,
    String? avatarUrl,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final isGoogleAccount = isGoogleLinkedAccount();

      // For Google accounts, prevent email changes and sync from Google
      if (isGoogleAccount) {
        // Use the Google email instead of the provided email
        final googleEmail = user.email;
        if (googleEmail != null && googleEmail != email) {
          debugPrint(
              'Warning: Email change ignored for Google account. Using Google email: $googleEmail');
          email = googleEmail;
        }

        // Sync latest Google profile data
        await syncGoogleProfile();
      }

      // Format the mobile number
      final formattedMobileNumber =
          mobileNumber.startsWith('+63') ? mobileNumber : '+63$mobileNumber';

      // Encrypt sensitive data before updating
      final encryptionService = EncryptionService();
      await encryptionService.initialize();
      final encryptedData = await encryptionService.encryptUserFields({
        'display_name': displayName,
        'passenger_email': email,
        'contact_number': formattedMobileNumber,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      });

      // Update the passenger table with encrypted data
      await passengersDatabase.update({
        'display_name': encryptedData['display_name'],
        'passenger_email': encryptedData['passenger_email'],
        'contact_number': encryptedData['contact_number'],
        if (avatarUrl != null) 'avatar_url': encryptedData['avatar_url'],
      }).eq('id', user.id);

      // Update auth metadata if not a Google account
      if (!isGoogleAccount) {
        await supabase.auth.updateUser(
          UserAttributes(
            email: email,
            data: {
              'display_name': displayName,
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      throw Exception('Failed to update profile');
    }
  }

  Future<void> migrateExistingUserDataToEncrypted() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final encryptionService = EncryptionService();
      await encryptionService.initialize();
      
      // Fetch current user data
      final response = await supabase
          .from('passenger')
          .select()
          .eq('id', user.id)
          .single();

      // Check if data is already encrypted
      final fieldsToCheck = ['display_name', 'contact_number', 'passenger_email', 'avatar_url'];
      bool needsMigration = false;
      final unencryptedFields = <String>[];
      
      for (final field in fieldsToCheck) {
        final value = response[field]?.toString();
        if (value != null && 
            value.isNotEmpty && 
            !encryptionService.isEncrypted(value)) {
          needsMigration = true;
          unencryptedFields.add(field);
        }
      }

      if (needsMigration) {
        debugPrint('🔄 Migrating existing user data to encrypted format');
        debugPrint('Fields to encrypt: $unencryptedFields');
        
        // Log current field values (truncated for security)
        for (final field in unencryptedFields) {
          final value = response[field]?.toString() ?? '';
          debugPrint('$field: "${value.length > 20 ? '${value.substring(0, 20)}...' : value}"');
        }
        
        // Only encrypt fields that are not already encrypted
        final dataToEncrypt = <String, String?>{};
        for (final field in unencryptedFields) {
          dataToEncrypt[field] = response[field]?.toString();
        }
        
        final encryptedData = await encryptionService.encryptUserFields(dataToEncrypt);

        // Update only the fields that needed encryption
        if (encryptedData.isNotEmpty) {
          debugPrint('Updating ${encryptedData.length} encrypted fields in database');
          await passengersDatabase.update(encryptedData).eq('id', user.id);
          debugPrint('User data migration completed successfully for fields: ${encryptedData.keys}');
        }
      } else {
        debugPrint('User data is already encrypted, no migration needed');
      }
    } catch (e) {
      debugPrint('Error migrating user data: $e');
    }
  }

  /// Repair corrupted encrypted user data with fresh values
  Future<void> repairCorruptedUserData({
    required String displayName,
    required String email,
    required String mobileNumber,
    String? avatarUrl,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      debugPrint('Repairing corrupted user data...');

      final encryptionService = EncryptionService();
      await encryptionService.initialize();
      
      // Format the mobile number properly
      final formattedMobileNumber =
          mobileNumber.startsWith('+63') ? mobileNumber : '+63$mobileNumber';

      // Force re-encrypt with proper values
      final repairedData = await encryptionService.forceReEncryptUserData({
        'display_name': displayName,
        'passenger_email': email,
        'contact_number': formattedMobileNumber,
        'avatar_url': avatarUrl ?? 'assets/svg/default_user_profile.svg',
      });

      // Update the database with repaired data
      await passengersDatabase.update(repairedData).eq('id', user.id);

      debugPrint('User data repaired successfully');
      debugPrint('   Name: $displayName');
      debugPrint('   Email: $email');
      debugPrint('   Phone: $formattedMobileNumber');
      
    } catch (e) {
      debugPrint('Error repairing user data: $e');
      throw Exception('Failed to repair user data: $e');
    }
  }

  /// Check if user data needs repair (has recovery markers)
  Future<bool> userDataNeedsRepair() async {
    try {
      final userData = await getCurrentUserData();
      if (userData == null) return false;

      // Check for recovery markers
      final fieldsToCheck = ['display_name', 'contact_number', 'passenger_email', 'avatar_url'];
      
      for (final field in fieldsToCheck) {
        final value = userData[field]?.toString() ?? '';
        if (value.contains('[RECOVERY_NEEDED]') || 
            value.contains('[ENCRYPTED_DATA_RECOVERY_NEEDED]') ||
            value.startsWith('+639000000000') || // Default placeholder number
            value == 'user@example.com' || // Default placeholder email
            value == 'User') { // Default placeholder name
          debugPrint('Field $field needs repair: $value');
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking if user data needs repair: $e');
      return true; // Assume repair is needed if we can't check
    }
  }
}
