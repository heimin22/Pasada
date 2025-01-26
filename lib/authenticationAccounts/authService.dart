import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // supabase client instance
  final SupabaseClient supabase = Supabase.instance.client;

  // singleton pattern
  static final AuthService _instance = AuthService.internal();

  // internet connection
  final Connectivity connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> connectivitySubscription;

  void initState() {
    checkInitialConnectivity();
    connectivitySubscription = connectivity.onConnectivityChanged.listen(updateConnectionStatus);

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
      print('Supabase Client Initialized: ${supabase}');
    }
  }

  // login with email and password
  Future<AuthResponse> login(String email, String password) async {

    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      showNoInternetToast();
      throw Exception("No internet connection");

    }
    try {
      return await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    }
    catch (e) {
      if (kDebugMode) print('Error during login: $e');
      throw Exception('Failed to login');
    }
  }

  // logout
  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
      if (kDebugMode) print('Logout successful');
    }
    catch (e) {
      if (kDebugMode) print('Error during logout: $e');
      throw Exception('Failed to logout');
    }
  }

  // get current user email
  String? getCurrentUserEnail() {
    final session = supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }
}