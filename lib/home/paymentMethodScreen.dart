import 'package:flutter/material.dart';

class PaymentMethodScreen extends StatefulWidget {
  final String? currentSelection;

  const PaymentMethodScreen({
    super.key,
    this.currentSelection,
  });

  @override
  State<PaymentMethodScreen> createState() => PaymentMethodScreenState();
}

class PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String? selectPaymentMethod;

  @override
  void initState() {
    super.initState();
    selectPaymentMethod = widget.currentSelection;
  }

  // helper function para magbuild ng list tiles for payment methods
  Widget buildPaymentOption({
    required String title,
    required String value,
    Widget? leadingIcon,
  }) {
    return RadioListTile<String>(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      groupValue: selectPaymentMethod,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            selectPaymentMethod = newValue;
          });
          Navigator.pop(context, newValue);
        }
      },
      // use the provided leading icon
      secondary: Radio<String>(
        value: value,
        groupValue: selectPaymentMethod,
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              selectPaymentMethod = newValue;
            });
            Navigator.pop(context, newValue);
          }
        },
        activeColor: Color(0xFF00CC58),
      ),
      // dito yung icon
      controlAffinity: ListTileControlAffinity.leading, // para mapunta yung radio button sa right
      // leading property sa right icon
      // leading: leadingIcon,
      selected: selectPaymentMethod == value,
      activeColor: Color(0xFF067837),
    );
  }

  // helper para sa section headers
  Widget buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF515151),
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment Methods',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF121212),
          ),
        ),
        backgroundColor: Color(0xFFf5F5F5),
        foregroundColor: Color(0xFF121212),
        elevation: 1.0,
      ),
      backgroundColor: Color(0xFFF2F2F2),
      body: ListView (
        children: [
          // Cash option
          buildSectionHeader('Cash Payment'),
          buildPaymentOption(
            title: 'Cash',
            value: 'Cash',
            leadingIcon: const Icon(Icons.money, color: Color(0xFF00CC58)),
          ),
          buildSectionHeader('Cashless'),
          // Paymongo option
          buildPaymentOption(
            title: 'Paymongo',
            value: 'Paymongo',
            leadingIcon: Image.asset(
              'assets/svg/paymongo_logo.svg',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.credit_card, color: Color(0xFF00CC58));
              },
            ),
          ),
        ],
      ),
    );
  }
}
