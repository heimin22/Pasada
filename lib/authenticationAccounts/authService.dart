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
  Future<AuthResponse> signUpAuth(String email, String password, {Map<String, dynamic>? data}) async {
    return await supabase.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }


  // logout
  // update to remove device ID
  Future<void> logout() async {
    try {
      // device ID handling for logging out
      // final user = supabase.auth.currentUser;
      // if (user != null) {
      //   await supabase
      //       .from('passenger');
      //       // .update({'device_id': null})
      //       // .eq('user_id', user.id);
      // }
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

  // update user information
  // Future<void> updateUserInfo(String firstName, String lastName, String contactNumber, String email) async {
  //   final user = supabase.auth.currentUser;
  //
  //   if (user != null) {
  //     try {
  //       final response = await supabase.from('passengers').update({
  //         'first_name': firstName,
  //         'last_name': lastName,
  //         'contact_number': contactNumber,
  //         'passenger_email': email,
  //       }).eq('user_id', user.id);
  //
  //       if (response.error != null) {
  //         throw Exception(response.error!.message);
  //       }
  //       debugPrint('Updated passenger_table: first_Name=$firstName, last_Name=$lastName, contact_Number=$contactNumber');
  //     } catch (e) {
  //       debugPrint('Error updating passenger_table: $e');
  //       rethrow;
  //     }
  //   } else {
  //     throw Exception('User not found');
  //   }
  // }

  // update device information on login
  // Future<void> updateDeviceInfo(String userID) async {
  //   final deviceID = await getDeviceID();
  //   await supabase.from('passengers').update({
  //     'device_id': deviceID,
  //     'last_Login': DateTime.now().toIso8601String(),
  //   }).eq('user_id', userID);
  // }

  // validate device on app start
  // Future<void> validateDevice(String userID) async {
  //   final currentDeviceID = await getDeviceID();
  //   final responseProfile = await supabase
  //       .from('passenger')
  //       .select('device_id')
  //       .eq('user_id', userID)
  //       .single();
  //
  //   if (responseProfile['device_id'] != currentDeviceID) {
  //     await supabase.auth.signOut();
  //     throw Exception('Session expired.');
  //   }
  // }
}
