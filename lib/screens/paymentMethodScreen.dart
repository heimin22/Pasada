import 'package:flutter/material.dart';

class PaymentMethodScreen extends StatefulWidget {
  final String? currentSelection;
  final double fare;

  const PaymentMethodScreen({
    super.key,
    this.currentSelection,
    required this.fare,
  });

  @override
  State<PaymentMethodScreen> createState() => PaymentMethodScreenState();
}

class PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String? selectPaymentMethod;

  @override
  void initState() {
    super.initState();
    // Set default to Cash
    selectPaymentMethod = 'Cash';
  }

  // helper function para magbuild ng list tiles for payment methods
  Widget buildPaymentOption({
    required String title,
    required String value,
    Widget? leadingIcon,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RadioListTile<String>(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 24.0, vertical: 2.0),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
        ),
      ),
      value: value,
      groupValue: selectPaymentMethod,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            selectPaymentMethod = newValue;
          });
          // Auto-return since only Cash is available
          Navigator.pop(context, newValue);
        }
      },
      secondary: leadingIcon,
      controlAffinity: ListTileControlAffinity.trailing,
      selected: selectPaymentMethod == value,
      activeColor: Color(0xFF067837),
    );
  }

  // helper para sa section headers
  Widget buildSectionHeader(String title) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF515151),
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment Method',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color:
                isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
          ),
        ),
        backgroundColor:
            isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        foregroundColor:
            isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
        elevation: 1.0,
      ),
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF2F2F2),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 16),
                // Informational message
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: const Color(0xFF00CC58),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cash payment is the only available payment method.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode
                                      ? const Color(0xFFF5F5F5)
                                      : const Color(0xFF121212),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Cash option
                buildSectionHeader('Payment Method'),
                buildPaymentOption(
                  title: 'Cash',
                  value: 'Cash',
                  leadingIcon:
                      const Icon(Icons.money_rounded, color: Color(0xFF00CC58)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
