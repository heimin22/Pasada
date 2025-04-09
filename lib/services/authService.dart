import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

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
    if (connectivityResult == ConnectivityResult.none) showNoInternetToast();
  }

  void updateConnectionStatus(List<ConnectivityResult> result) {
    if (result == ConnectivityResult.none) showNoInternetToast();
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
    if (connectivityResult == ConnectivityResult.none) {
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

  // ito na yung method to sign in with google my niggas
  Future<bool> signInWithGoogle() async {
    // check the internet connection
    final hasConnection = await checkNetworkConnection();
    if (!hasConnection) return false;

    try {
      final response = await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'pasada://login-callback',
        queryParams: {
          'access_type': 'offline',
          'prompt': 'consent',
        },
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (!response) {
        debugPrint('Google sign-in failed');
        return false;
      }

      // wait natin yung auth state na magbago
      final completer = Completer<bool>();
      late StreamSubscription<AuthState> authSub;

      authSub = supabase.auth.onAuthStateChange.listen((data) async {
        final event = data.event;
        final session = data.session;

        if (event == AuthChangeEvent.signedIn && session != null) {
          try {
            final user = session.user;
            final metadata = user.userMetadata;

            if (metadata == null) {
              debugPrint('No user metadata available');
              completer.complete(false);
              return;
            }

            final firstName =
                metadata['full_name']?.toString().split(' ').first ?? '';
            final lastName =
                metadata['full_name']?.toString().split(' ').last ?? '';
            final email = user.email ?? '';

            await supabase.from('passenger').upsert({
              'id': user.id,
              'first_name': firstName,
              'last_name': lastName,
              'passenger_email': email,
              'contact_number': 'pending',
            });
            completer.complete(true);
          } catch (e) {
            debugPrint('Error creating user profile: $e');
            completer.complete(false);
          } finally {
            await authSub.cancel();
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
      debugPrint('Error during Google sign-in: $e');
      return false;
    }

    //   final completer = Completer<bool>();
    //   late final StreamSubscription? authSub;
    //   authSub = supabase.auth.onAuthStateChange.listen((authState) async {
    //     // wait muna sa sign-in event
    //     if (authState.event == AuthChangeEvent.signedIn) {
    //       // get yung current user
    //       final user = supabase.auth.currentUser;
    //       if (user != null) {
    //         // perform ng polling to make sure na handa na yung metadata
    //         await Future.delayed(Duration(seconds: 2));

    //         // extract na yung user's full name from metadata safely
    //         String fullName = user.userMetadata?['full_name'] ?? user.userMetadata?['name'];
    //         // provide ng fallback if hindi provided yung name
    //         fullName = fullName.trim();

    //         // parse na yung full name into parts
    //         final nameParts = fullName.split(' ');
    //         final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    //         final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    //         final uniquePlaceholder = "temp-${DateTime.now().millisecondsSinceEpoch}";

    //         if (supabase.auth.currentSession == null) {
    //           debugPrint('No active session when trying to create profile');
    //           return;
    //         }

    //         try {
    //           await supabase.from('passenger').upsert({
    //             'id': user.id,
    //             'first_name': firstName,
    //             'last_name': lastName,
    //             'passenger_email': user.email,
    //             'contact_number': uniquePlaceholder,
    //           });
    //           completer.complete(true);
    //         } catch (e) {
    //           debugPrint('Database error $e');
    //           completer.complete(false);
    //         }
    //       } else {
    //         completer.complete(false);
    //       }
    //       await authSub?.cancel();
    //     }
    //   });

    //   try {
    //     await supabase.auth.signInWithOAuth(
    //       OAuthProvider.google,
    //       redirectTo: kIsWeb ? null : 'pasada://login-callback',
    //       authScreenLaunchMode: kIsWeb ? LaunchMode.inAppWebView : LaunchMode.externalApplication,
    //     );
    //     return true;
    //   } catch (e) {
    //     debugPrint('Error during Google sign-in: $e');
    //     Fluttertoast.showToast(
    //       msg: 'Failed to sign in with Google',
    //       toastLength: Toast.LENGTH_SHORT,
    //       gravity: ToastGravity.BOTTOM,
    //       backgroundColor: Color(0xFFF5F5F5),
    //       textColor: Color(0xFF121212),
    //     );
    //     return false;
    //   }
    // }

    // Future<bool> signInWithGoogle() async {
    //   // check the internet connection
    //   final hasConnection = await checkNetworkConnection();
    //   if (!hasConnection) return false;
    //
    //   try {
    //     final response = await supabase.auth.signInWithOAuth(
    //       OAuthProvider.google,
    //       redirectTo: 'pasada://login-callback',
    //       authScreenLaunchMode: LaunchMode.externalApplication,
    //     );
    //     return response;
    //   } catch (e) {
    //     debugPrint('Error during Google sign-in: $e');
    //     throw Exception('Google sign-in failed');
    //   }
    // }
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
