import 'package:flutter/material.dart';
import 'package:paymongo_sdk/paymongo_sdk.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_passenger_app/services/bookingService.dart';

class PaymongoPaymentScreen extends StatefulWidget {
  final String paymentMethod;
  final int amount;

  const PaymongoPaymentScreen({
    super.key,
    required this.paymentMethod,
    required this.amount,
  });

  @override
  State<PaymongoPaymentScreen> createState() => _PaymongoPaymentScreenState();
}

class _PaymongoPaymentScreenState extends State<PaymongoPaymentScreen> {
  bool isLoading = false;
  String statusMessage = '';
  final BookingService bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          ),
        ),
        backgroundColor:
            isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
        foregroundColor:
            isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
        elevation: 1.0,
      ),
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00CC58)))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF121212)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: const Color(0xFF00CC58),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(statusMessage),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
