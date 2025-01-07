import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // supabase credentials
  /*static const supabaseUrl = 'https://otbwhitwrmnfqgpmnjvf.supabase.co';
  static const supabaseKey = String.fromEnvironment(
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im90YndoaXR3cm1uZnFncG1uanZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzMzOTk5MzQsImV4cCI6MjA0ODk3NTkzNH0.f8JOv0YvKPQy8GWYGIdXfkIrKcqw0733QY36wJjG1Fw');*/

  // supabase client instance
  final SupabaseClient supabase = Supabase.instance.client;

  // singleton pattern
  static final AuthService _instance = AuthService.internal();

  factory AuthService() {
    return _instance;
  }

  AuthService.internal() {
    if (kDebugMode) {
      print('Supabase Client Initialized: ${supabase}');
    }
  }

  // sign up with email and password
  /*
    This is an initial function that needs to be tested!
   */
  /*Future<void> signUp(String email, String password) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        if (kDebugMode) print('Sign-up successful: ${response.user!.email}');
      }
      else {
        throw Exception('Sign-up failed');
      }
    }
    catch (e) {
      if (kDebugMode) print('Error during sign-up: $e');
      throw Exception('Failed to sign up');
    }
  }*/


  // login with email and password
  Future<AuthResponse> login(String email, String password) async {
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