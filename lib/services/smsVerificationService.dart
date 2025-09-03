import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class SMSVerificationService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static String? _verificationId;
  static int? _resendToken;

  /// Send SMS OTP to the provided phone number
  static Future<bool> sendOTP({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
    required Function() onTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          Fluttertoast.showToast(
            msg: 'Verification code sent to $phoneNumber',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Color(0xFFF5F5F5),
            textColor: Color(0xFF121212),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed');
          Fluttertoast.showToast(
            msg: e.message ?? 'Verification code failed',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Color(0xFFF5F5F5),
            textColor: Color(0xFF121212),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          Fluttertoast.showToast(
            msg: 'Verification code sent to $phoneNumber',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Color(0xFFF5F5F5),
            textColor: Color(0xFF121212),
          );
        },
        timeout: const Duration(seconds: 60),
        codeAutoRetrievalTimeout: (String verificationId) {
          onTimeout();
          Fluttertoast.showToast(
            msg: 'Verification code timed out. Please try again.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Color(0xFFF5F5F5),
            textColor: Color(0xFF121212),
          );
        },
        forceResendingToken: _resendToken,
      );
      return true;
    } catch (e) {
      onError('Failed to send OTP. Please try again later');
      return false;
    }
  }

  /// Verify the OTP code
  static Future<bool> verifyOTP({
    required String otpCode,
    required Function(String) onError,
    required Function() onSuccess,
  }) async {
    if (_verificationId == null) {
      onError('Verification ID not found');
      return false;
    }
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpCode,
      );
      await _auth.signInWithCredential(credential);
      await _auth.signOut();

      onSuccess();
      return true;
    } on FirebaseAuthException catch (e) {
      onError(e.message ?? 'Verification failed');
      return false;
    } catch (e) {
      onError('Invalid OTP code');
      return false;
    }
  }

  static Future<bool> resendOTP({
    required String phoneNumber,
    required Function(String) onError,
    required Function(String) onCodeSent,
  }) async {
    return await sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
      onTimeout: () => onError('Resend OTP timed out'),
    );
  }

  static void clearSession() {
    _verificationId = null;
    _resendToken = null;
  }
}
