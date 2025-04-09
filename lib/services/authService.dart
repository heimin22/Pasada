import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
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

  Future<void> saveGoogleUsername(User user) async {

  }

  // Method to sign in with Google
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
        },
        scopes: 'profile email',
        authScreenLaunchMode: LaunchMode.externalNonBrowserApplication,
      );

      if (!response) {
        return false;
      }

      // wait for the auth state to change
      final completer = Completer<bool>();
      late StreamSubscription<AuthState> authSub;

      authSub = supabase.auth.onAuthStateChange.listen((AuthState state) async {
        if (state.event == AuthChangeEvent.signedIn && state.session != null) {
          final user = supabase.auth.currentUser;
          debugPrint('Google User Metadata: ${user?.userMetadata}'); // Debug log
          if (user != null) {
            final rawData = user.userMetadata ?? {};
            final fullName = rawData['full_name']?.split(' ') ?? [];
            final firstName = fullName.isNotEmpty ? fullName.first : null;
            final lastName = fullName.length > 1 ? fullName.last : null;

            final existingUser = await supabase.from('passenger')
                .select()
                .eq('id', user.id)
                .maybeSingle();

            if (existingUser == null) {
              await passengersDatabase.insert({
                'id': user.id,
                'passenger_email': user.email,
                'first_name': firstName,
                'last_name': lastName,
                'created_at': DateTime.now().toIso8601String(),
              });
            }
            completer.complete(true);
          }
        }
      });

      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          authSub.cancel();
          return false;
        },
      );
    } catch (e) {
      return false;
    }
  }

  // Initialize deep link handling for auth callbacks
  Future<void> initDeepLinkHandling() async {
    try {
      final appLinks = AppLinks();

      // Listen for app links while the app is running
      appLinks.uriLinkStream.listen((Uri? uri) {
        if (uri != null &&
            uri.scheme == 'pasada' &&
            uri.host == 'login-callback') {
          // The app was opened via the redirect URL, handle the auth callback
          // Supabase SDK should automatically handle the session
        }
      }, onError: (error) {
        return;
      });

      // Check for initial link if the app was started from a link
      final initialLink = await appLinks.getInitialAppLink();
      if (initialLink != null) {
        if (initialLink.scheme == 'pasada' &&
            initialLink.host == 'login-callback') {
          // The app was opened from the redirect URL, handle the auth callback
          // Supabase SDK should automatically handle the session
        }
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

  // generate or retrieve device ID
  Future<String> getDeviceID() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceID = prefs.getString('device_id');
    if (deviceID == null) {
      deviceID = const Uuid().v4();
      await prefs.setString('device_id', deviceID);
    }
    return deviceID;
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
