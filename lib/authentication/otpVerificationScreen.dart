import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';
import 'package:pasada_passenger_app/services/smsVerificationService.dart';
import 'package:pasada_passenger_app/services/authService.dart';
import 'package:pasada_passenger_app/screens/selectionScreen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String email;
  final String password;
  final String displayName;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController codeController = TextEditingController();
  final AuthService authService = AuthService();
  bool isLoading = false;
  bool canResend = false;
  int remainingTime = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    sendOTPCode();
    startTimer();
  }

  @override
  void dispose() {
    codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (count) {
      if (remainingTime > 0) {
        setState(() => remainingTime--);
      } else {
        setState(() => canResend = true);
        _timer?.cancel();
      }
    });
  }

  Future<void> sendOTPCode() async {
    try {
      setState(() {
        isLoading = true;
        canResend = false;
      });

      await SMSVerificationService.sendOTP(
        phoneNumber: widget.phoneNumber,
        onCodeSent: (message) {
          if (mounted) {
            Fluttertoast.showToast(
              msg: 'OTP code sent to ${widget.phoneNumber}',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Color(0xFFF5F5F5),
              textColor: Color(0xFF121212),
            );
          }
        },
        onError: (error) {
          if (mounted) {
            Fluttertoast.showToast(
              msg: error,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Color(0xFFF5F5F5),
              textColor: Color(0xFF121212),
            );
          }
        },
        onTimeout: () {
          if (mounted) {
            Fluttertoast.showToast(
              msg: 'SMS timeout. Please try again.',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Color(0xFFF5F5F5),
              textColor: Color(0xFF121212),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('Error sending OTP code: $e');
      if (mounted) {
        String errorMessage = 'Failed to send OTP code';
        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Color(0xFFF5F5F5),
          textColor: Color(0xFF121212),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> verifyOTPAndCreateAccount() async {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter the OTP code',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color(0xFFF5F5F5),
        textColor: Color(0xFF121212),
      );
      return;
    }

    if (code.length != 6) {
      Fluttertoast.showToast(
        msg: 'Please enter a valid 6-digit code',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color(0xFFF5F5F5),
        textColor: Color(0xFF121212),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // First verify the OTP
      bool isVerified = await SMSVerificationService.verifyOTP(
        otpCode: code,
        onSuccess: () async {
          // OTP verified successfully, now create the account
          try {
            await authService.signUpAuth(
              widget.email,
              widget.password,
              data: {
                'display_name': widget.displayName,
                'contact_number': widget.phoneNumber,
                'avatar_url': 'assets/svg/default_user_profile.svg',
              },
            );

            // Clear SMS verification session
            SMSVerificationService.clearSession();

            if (mounted) {
              Fluttertoast.showToast(
                msg: 'Account created successfully',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Color(0xFFF5F5F5),
                textColor: Color(0xFF121212),
              );

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => const selectionScreen()),
                (route) => false,
              );
            }
          } catch (e) {
            if (mounted) {
              Fluttertoast.showToast(
                msg: 'Failed to create account: ${e.toString()}',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Color(0xFFF5F5F5),
                textColor: Color(0xFF121212),
              );
            }
          }
        },
        onError: (error) {
          if (mounted) {
            Fluttertoast.showToast(
              msg: error,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Color(0xFFF5F5F5),
              textColor: Color(0xFF121212),
            );
          }
        },
      );

      if (!isVerified) {
        // Clear the code field if verification failed
        codeController.clear();
      }
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      if (mounted) {
        String errorMessage = 'Invalid verification code';
        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Color(0xFFF5F5F5),
          textColor: Color(0xFF121212),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Verify Phone Number',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the 6-digit code sent to:',
                  style: TextStyle(
                    color: isDarkMode
                        ? const Color(0xFFF5F5F5)
                        : const Color(0xFF121212),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.phoneNumber,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? const Color(0xFFF5F5F5)
                        : const Color(0xFF121212),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    labelText: 'OTP Code',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFF2F2F2),
                    helperText: 'Enter the 6-digit code sent via SMS',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: TextStyle(
                    color: isDarkMode
                        ? const Color(0xFFF5F5F5)
                        : const Color(0xFF121212),
                    letterSpacing: 8.0,
                  ),
                ),
                const SizedBox(height: 16),
                if (!canResend)
                  Text(
                    'Resend code in ${remainingTime}s',
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFF121212),
                    ),
                  ),
                if (canResend)
                  TextButton(
                    onPressed: () {
                      sendOTPCode();
                      setState(() {
                        remainingTime = 60;
                        canResend = false;
                      });
                      startTimer();
                    },
                    child: const Text('Resend Code'),
                  ),
              ],
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              child: ElevatedButton(
                onPressed: isLoading ? null : verifyOTPAndCreateAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00CC58),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Verify & Create Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF5F5F5),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
