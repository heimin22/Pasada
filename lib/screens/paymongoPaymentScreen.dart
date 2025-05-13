import 'package:flutter/material.dart';
import 'package:paymongo_sdk/paymongo_sdk.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_passenger_app/services/bookingService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pasada_passenger_app/screens/paymentWebViewScreen.dart';

class PaymongoPaymentScreen extends StatefulWidget {
  final String paymentMethod;
  final double amount;

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
            isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        foregroundColor:
            isDarkMode ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
        elevation: 1.0,
      ),
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF2F2F2),
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
                        Text(
                          'Payment Summary',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode
                                ? const Color(0xFFF5F5F5)
                                : const Color(0xFF121212),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount:',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode
                                    ? const Color(0xFFF5F5F5)
                                    : const Color(0xFF515151),
                              ),
                            ),
                            Text(
                              '₱${widget.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDarkMode
                                    ? const Color(0xFFF5F5F5)
                                    : const Color(0xFF121212),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payment Method:',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode
                                    ? const Color(0xFFF5F5F5)
                                    : const Color(0xFF515151),
                              ),
                            ),
                            Text(
                              widget.paymentMethod,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? const Color(0xFFF5F5F5)
                                    : const Color(0xFF121212),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (statusMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        statusMessage,
                        style: TextStyle(
                          color: statusMessage.contains('Error')
                              ? Colors.red
                              : const Color(0xFF00CC58),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Payment button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00CC58),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Pay Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      isLoading = true;
      statusMessage = '';
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get API keys from environment variables
      final publicKey = dotenv.env['PAYMONGO_PUBLIC_KEY'] ?? '';
      final secretKey = dotenv.env['PAYMONGO_SECRET_KEY'] ?? '';

      if (publicKey.isEmpty || secretKey.isEmpty) {
        throw Exception('Paymongo API keys not configured');
      }

      // Initialize clients
      final publicClient = PaymongoClient<PaymongoPublic>(publicKey);
      final secretClient = PaymongoClient<PaymongoSecret>(secretKey);

      // Create billing info
      final billing = PayMongoBilling(
        name: user.userMetadata?['display_name'] ?? 'Pasada User',
        email: user.email ?? '',
        phone: user.userMetadata?['contact_number'] ?? '',
        address: PayMongoAddress(
          line1: dotenv.env['PAYMONGO_COMPANY_ADDRESS'] ?? '',
          city: dotenv.env['PAYMONGO_COMPANY_CITY'] ?? '',
          state: dotenv.env['PAYMONGO_COMPANY_STATE'] ?? '',
          postalCode: dotenv.env['PAYMONGO_COMPANY_POSTAL_CODE'] ?? '',
          country: dotenv.env['PAYMONGO_COMPANY_COUNTRY'] ?? 'PH',
        ),
      );

      // Define success and failed URLs
      const successUrl = 'pasada://payment-success';
      const failedUrl = 'pasada://payment-failed';

      // Create source for GCash/Maya
      final source = SourceAttributes(
        type: widget.paymentMethod.toLowerCase(),
        amount: widget.amount,
        currency: 'PHP',
        redirect: const Redirect(
          success: successUrl,
          failed: failedUrl,
        ),
        billing: billing,
      );

      final result = await publicClient.instance.source.create(source);
      final paymentUrl = result.attributes?.redirect.checkoutUrl ?? '';

      if (paymentUrl.isNotEmpty) {
        // Open WebView for payment
        final paymentSuccess = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentWebViewScreen(
                  url: paymentUrl,
                  successUrl: successUrl,
                  failedUrl: failedUrl,
                ),
              ),
            ) ??
            false;

        if (paymentSuccess) {
          // Create payment after successful checkout
          final paymentSource = PaymentSource(id: result.id, type: "source");
          final paymentAttr = CreatePaymentAttributes(
            amount: widget.amount,
            currency: 'PHP',
            description: "Pasada Ride Payment",
            source: paymentSource,
          );

          await secretClient.instance.payment.create(paymentAttr);
          _onPaymentSuccess();
        } else {
          setState(() {
            isLoading = false;
            statusMessage = 'Payment was cancelled or failed.';
          });
        }
      } else {
        throw Exception('Failed to get payment URL');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  void _onPaymentSuccess() {
    setState(() {
      isLoading = false;
      statusMessage = 'Payment successful!';
    });

    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful'),
        content: const Text('Your payment has been processed successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context,
                  true); // Return to previous screen with success result
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
