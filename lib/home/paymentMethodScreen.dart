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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Payment Method',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView (
        children: [
          ListTile(
            title: const Text('Cash'),
            onTap: () => Navigator.pop(context, 'Cash'),
          ),
          ListTile(
            title: const Text('Cashless'),
            onTap: () => Navigator.pop(context, 'Cashless'),
          ),
        ],
      ),
    );
  }
}
