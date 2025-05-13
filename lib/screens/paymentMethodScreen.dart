import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasada_passenger_app/screens/paymongo_payment_screen.dart';

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
  bool isOnlinePayment = false;

  @override
  void initState() {
    super.initState();
    selectPaymentMethod = widget.currentSelection;
    _updatePaymentType(selectPaymentMethod);
  }

  void _updatePaymentType(String? paymentMethod) {
    setState(() {
      isOnlinePayment = paymentMethod == 'GCash' || paymentMethod == 'Maya';
    });
  }

  // helper function para magbuild ng list tiles for payment methods
  Widget buildPaymentOption({
    required String title,
    required String value,
    Widget? leadingIcon,
    bool enabled = true,
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
      onChanged: enabled
          ? (String? newValue) {
              if (newValue != null) {
                setState(() {
                  selectPaymentMethod = newValue;
                });
                _updatePaymentType(newValue);
                // Only auto-return for Cash option
                if (newValue == 'Cash') {
                  Navigator.pop(context, newValue);
                }
              }
            }
          : null,
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
          'Payment Methods',
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
                                'Warning: Please choose the correct payment method for the passenger to avoid any payment issues.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode
                                      ? const Color(0xFFF5F5F5)
                                      : const Color(0xFF121212),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Note: If cashless payment is selected, the fare will be automatically paid once you are picked up by the driver.',
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
                buildSectionHeader('Cash Payment'),
                buildPaymentOption(
                  title: 'Cash',
                  value: 'Cash',
                  leadingIcon:
                      const Icon(Icons.money_rounded, color: Color(0xFF00CC58)),
                ),
                buildSectionHeader('Online Payment'),
                buildPaymentOption(
                  title: 'GCash',
                  value: 'GCash',
                  leadingIcon: SvgPicture.asset(
                    'assets/svg/gcash_logo.svg',
                    width: 24,
                    height: 24,
                    placeholderBuilder: (context) =>
                        const Icon(Icons.credit_card, color: Color(0xFF00CC58)),
                  ),
                  enabled: true,
                ),
                buildPaymentOption(
                  title: 'Maya',
                  value: 'Maya',
                  leadingIcon: SvgPicture.asset(
                    'assets/svg/maya_logo.svg',
                    width: 24,
                    height: 24,
                    placeholderBuilder: (context) =>
                        const Icon(Icons.credit_card, color: Color(0xFF00CC58)),
                  ),
                  enabled: true,
                ),
              ],
            ),
          ),
          // Continue button for online payments
          if (isOnlinePayment)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to the Paymongo payment flow
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (_) => PaymongoPaymentScreen(
                    //       paymentMethod: selectPaymentMethod!,
                    //       amount: (widget.fare * 100)
                    //           .toInt(), // Convert to smallest currency unit (centavos)
                    //     ),
                    //   ),
                    // );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00CC58),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Proceed to Payment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
