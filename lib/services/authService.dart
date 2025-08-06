import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
      showNoInternetToast();
    }
  }

  void updateConnectionStatus(List<ConnectivityResult> result) {
    if (result.contains(ConnectivityResult.none)) showNoInternetToast();
  }

  void showNoInternetToast() {
    Fluttertoast.showToast(
      msg: 'No internet connection detected',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Color(0xFFF2F2F2),
      textColor: Color(0xFF121212),
      fontSize: 16.0,
    );
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
      showNoInternetToast();
      throw Exception("No internet connection");
    }
    try {
      AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response;
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  // implement nga tayong bagong method nigga
  // putangina hihiwalay ko na lang to para malupet
  // so ito yung para sa Supabase Authentication kasi tangina niyong lahat
  Future<AuthResponse> signUpAuth(String email, String password,
      {Map<String, dynamic>? data}) async {
    try {
      // Check if phone number exists if provided
      if (data?['contact_number'] != null) {
        final existingPhoneData = await supabase
            .from('passenger')
            .select()
            .eq('contact_number', data!['contact_number'])
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
        // Then, insert into passenger table
        await supabase.from('passenger').upsert({
          'id': response.user!.id,
          'passenger_email': email,
          'display_name': data?['display_name'],
          'contact_number': data?['contact_number'],
          'avatar_url':
              data?['avatar_url'] ?? 'assets/svg/default_user_profile.svg',
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
      Fluttertoast.showToast(
        msg: 'No internet connection',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color(0xFFF5F5F5),
        textColor: Color(0xFF121212),
      );
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
              await passengersDatabase.insert({
                'id': user.id,
                'email': user.email,
                'display_name': displayName,
                'avatar_url': avatarUrl,
                'created_at': DateTime.now().toIso8601String(),
              });
            } else {
              await passengersDatabase.update({
                'avatar_url': avatarUrl,
                'display_name': displayName,
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

        return response;
      } else {
        return null;
      }
    } catch (e) {
      if (kDebugMode) ('Error fetching user data: $e');
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

      // update the passenger table
      await passengersDatabase.update({
        'display_name': displayName,
        'passenger_email': email,
        'contact_number': formattedMobileNumber,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
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
}
