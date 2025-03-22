import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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

      if (response.user != null) {
        await updateDeviceInfo(response.user!.id);
        await validateDevice(response.user!.id);
      }
      // String deviceID = await getDeviceID();
      // await supabase.from('profiles').update({'device_id': deviceID}).eq('id', response.user!.id);
      return response;
    } catch (e) {
      if (kDebugMode) print('Error during login: $e');
      throw Exception('Failed to login');
    }
  }

  // sign up with email and password
  // update to store device ID
  Future<AuthResponse> signUp(String email, String password) async {
    AuthResponse response = await supabase.auth.signUp(
      email: email,
      password: password,
    );
    if (response.user != null) {
      String deviceID = await getDeviceID();
      await supabase.from('profiles').insert({
        'id': response.user!.id,
        'email': response.user!.email,
        'device_id': deviceID,
      });
    }
    return response;
  }

  // logout
  // update to remove device ID
  Future<void> logout() async {
    try {
      // device ID handling for logging out
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase
            .from('passenger')
            .update({'device_ID': null})
            .eq('user_ID', user.id);
      }
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
    String? deviceID = prefs.getString('device_ID');
    if (deviceID == null) {
      deviceID = const Uuid().v4();
      await prefs.setString('device_ID', deviceID);
    }
    return deviceID;
  }

  // update device information on login
  Future<void> updateDeviceInfo(String userID) async {
    final deviceID = await getDeviceID();
    await supabase.from('passengerTable').update({
      'device_ID': deviceID,
      'last_Login': DateTime.now().toIso8601String(),
    }).eq('user_ID', userID);
  }

  // validate device on app start
  Future<void> validateDevice(String userID) async {
    final currentDeviceID = await getDeviceID();
    final responseProfile = await supabase
        .from('passengerTable')
        .select('device_ID')
        .eq('user_ID', userID)
        .single();

    if (responseProfile['device_ID'] != currentDeviceID) {
      await supabase.auth.signOut();
      throw Exception('Session expired.');
    }
  }
}
