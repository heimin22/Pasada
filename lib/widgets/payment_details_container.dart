import 'package:flutter/material.dart';

class PaymentDetailsContainer extends StatelessWidget {
  final String paymentMethod;
  final VoidCallback onCancelBooking;
  final double fare;

  const PaymentDetailsContainer({
    super.key,
    required this.paymentMethod,
    required this.onCancelBooking,
    required this.fare,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container();
  }
}
