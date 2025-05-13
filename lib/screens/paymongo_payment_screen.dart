import 'package:flutter/material.dart';
import 'package:paymongo_sdk/paymongo_sdk.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_passenger_app/services/bookingService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

      // pick the right "flavor" of client: public or secret
      final publicClient = PaymongoClient<PaymongoPublic>(publicKey);
      final secretClient = PaymongoClient<PaymongoSecret>(secretKey);

      // 1) create a source (for GCash/PayMaya) with your public key
      final source = await publicClient.instance.source.create(
        SourceAttributes(
          type: widget.paymentMethod.toLowerCase(),
          amount: widget.amount,
          currency: 'PHP',
          redirect: const Redirect(
            success: 'pasada://payment-success',
            failed: 'pasada://payment-failed',
          ),
          billing: PayMongoBilling(
            name: user.userMetadata?['display_name'] ?? 'Pasada User',
            email: user.email ?? '',
            phone: user.userMetadata?['contact_number'] ?? '',
            address: PayMongoAddress(
              line1: dotenv.env['PAYMONGO_COMPANY_ADDRESS'] ?? '',
              city: dotenv.env['PAYMONGO_COMPANY_CITY'] ?? '',
              state: dotenv.env['PAYMONGO_COMPANY_STATE'] ?? '',
              postalCode: dotenv.env['PAYMONGO_COMPANY_POSTAL_CODE'] ?? '',
              country: dotenv.env['PAYMONGO_COMPANY_COUNTRY'] ?? '',
            ),
          ),
        ),
      );

      // Get the checkout URL from the source
      final paymentUrl = source.attributes?.redirect.checkoutUrl ?? '';

      if (paymentUrl.isNotEmpty) {
        // TODO: Implement WebView or URL launcher to open the payment URL

        // For now, simulate successful payment
        await Future.delayed(const Duration(seconds: 2));
        _onPaymentSuccess();
        return;
      }

      // 2) create a payment intent with your secret key
      final intent = await secretClient.instance.paymentIntent.create(
        PaymentIntentAttributes(
          amount: widget.amount,
          currency: 'PHP',
          statementDescriptor: 'Test Payment',
          paymentMethodAllowed: [
            widget.paymentMethod == 'GCash' ? 'gcash' : 'paymaya'
          ],
          description: 'Pasada Ride Payment',
          metadata: {'passenger_id': user.id},
        ),
      );

      // 3) attach the source to the intent
      final attached = await secretClient.instance.paymentIntent.attach(
        intent.id,
        PaymentIntentAttach(
          paymentMethod: widget.paymentMethod.toLowerCase(),
          returnUrl: 'pasada://payment-callback',
        ),
      );

      if (attached.attributes.nextAction?.redirect?.url != null) {
        // TODO: hahandle dapat dito yung redirect ng user sa e-wallet app
        // pwedeng WebView or url_launcher
        setState(() {
          isLoading = false;
          statusMessage =
              'Payment processing. You will be redirected to complete the payment.';
        });

        // ganito kasi dapat yung flow niyan
        // 1. open yung URL in a WebView
        // 2. handle yung redirect back duon sa app
        // 3. check yung payment status

        // simulate muna natin yung successful payment
        await Future.delayed(const Duration(seconds: 2));
        _onPaymentSuccess();
      } else if (attached.attributes.status == 'succeeded') {
        _onPaymentSuccess();
      } else {
        throw Exception('Payment failed: ${attached.attributes.status}');
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
