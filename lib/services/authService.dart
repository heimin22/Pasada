import 'dart:async';
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

  void initState() {
    checkInitialConnectivity();
    connectivitySubscription =
        connectivity.onConnectivityChanged.listen(updateConnectionStatus);
  }

  Future<void> checkInitialConnectivity() async {
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none))
      showNoInternetToast();
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

  AuthService.internal() {
    if (kDebugMode) {
      print('Supabase Client Initialized: $supabase');
    }
  }

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
      if (kDebugMode) print('Error during login: $e');
      throw Exception('Failed to login');
    }
  }

  // implement nga tayong bagong method nigga
  // putangina hihiwalay ko na lang to para malupet
  // so ito yung para sa Supabase Authentication kasi tangina niyong lahat
  Future<AuthResponse> signUpAuth(String email, String password,
      {Map<String, dynamic>? data}) async {
    return await supabase.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<bool> checkNetworkConnection() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
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
            final existingUser = await supabase
                .from('passenger')
                .select()
                .eq('id', user.id)
                .maybeSingle();

            final userMetadata = user.userMetadata;
            final displayName = userMetadata?['full_name'] ?? '';

            if (existingUser == null) {
              await passengersDatabase.insert({
                'id': user.id,
                'email': user.email,
                'display_name': displayName,
                'created_at': DateTime.now().toIso8601String(),
              });
            } else if (existingUser['display_name'] == null) {
              await passengersDatabase.update({
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

  // Initialize deep link handling for auth callbacks
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
      if (kDebugMode) print('Logout successful');
    } catch (e) {
      if (kDebugMode) print('Error during logout: $e');
      throw Exception('Failed to logout');
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
}
