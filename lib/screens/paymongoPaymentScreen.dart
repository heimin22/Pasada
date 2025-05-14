import 'package:flutter/material.dart';
import 'package:paymongo_sdk/paymongo_sdk.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_passenger_app/services/bookingService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pasada_passenger_app/screens/paymentWebViewScreen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

      final publicKey = dotenv.env['PAYMONGO_PUBLIC_KEY'] ?? '';
      final secretKey = dotenv.env['PAYMONGO_SECRET_KEY'] ?? '';

      if (publicKey.isEmpty || secretKey.isEmpty) {
        throw Exception('Paymongo API keys not configured');
      }

      // Use valid HTTPS redirect URLs for PayMongo (custom schemes are not accepted)
      const String successRedirect =
          'https://example.com/pasada/payment-success';
      const String failedRedirect = 'https://example.com/pasada/payment-failed';

      if ((widget.amount * 100).toInt() < 2000) {
        setState(() {
          isLoading = false;
          statusMessage = 'Minimum payment is ₱20.00';
        });
        return;
      }

      // Create billing info (needed for e-wallet source flow)
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

      final method = widget.paymentMethod.toLowerCase();

      if (method == 'gcash') {
        final int cents = (widget.amount * 100).toInt();
        final String basicAuth = base64.encode(utf8.encode('$secretKey:'));
        final http.Response sourceResponse = await http.post(
          Uri.parse('https://api.paymongo.com/v1/sources'),
          headers: {
            'Authorization': 'Basic $basicAuth',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'data': {
              'attributes': {
                'type': method,
                'amount': cents,
                'currency': 'PHP',
                'billing': {
                  'name': billing.name,
                  'email': billing.email,
                  'phone': billing.phone,
                  'address': {
                    'line1': billing.address.line1,
                    'city': billing.address.city,
                    'state': billing.address.state,
                    'postal_code': billing.address.postalCode,
                    'country': billing.address.country,
                  },
                },
                'redirect': {
                  'success': successRedirect,
                  'failed': failedRedirect,
                },
              }
            }
          }),
        );
        if (sourceResponse.statusCode != 200) {
          final Map<String, dynamic> errBody = jsonDecode(sourceResponse.body);
          final List<dynamic> errs = errBody['errors'] ?? [];
          throw Exception(errs.map((e) => e['detail']).join('\n'));
        }
        final Map<String, dynamic> sourceBody = jsonDecode(sourceResponse.body);
        final String? checkoutUrl =
            sourceBody['data']?['attributes']?['redirect']?['checkout_url'];
        if (checkoutUrl == null) {
          throw Exception('Missing checkout_url from Source response');
        }

        final paid = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentWebViewScreen(
                  url: checkoutUrl,
                  successUrl: successRedirect,
                  failedUrl: failedRedirect,
                ),
              ),
            ) ??
            false;
        if (paid) {
          // finalize payment
          final String secretAuth = base64.encode(utf8.encode('$secretKey:'));
          final http.Response paymentResponse = await http.post(
            Uri.parse('https://api.paymongo.com/v1/payments'),
            headers: {
              'Authorization': 'Basic $secretAuth',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'data': {
                'attributes': {
                  'amount': cents,
                  'currency': 'PHP',
                  'source': {
                    'id': sourceBody['data']['id'],
                    'type': 'source',
                  },
                  'description': 'Pasada Ride Payment',
                }
              }
            }),
          );
          if (paymentResponse.statusCode != 200) {
            final Map<String, dynamic> errBody =
                jsonDecode(paymentResponse.body);
            final List<dynamic> errs = errBody['errors'] ?? [];
            throw Exception(errs.map((e) => e['detail']).join('\n'));
          }
          _onPaymentSuccess();
        } else {
          setState(() {
            isLoading = false;
            statusMessage = 'Payment was cancelled or failed.';
          });
        }
      } else {
        final int amountCents = (widget.amount * 100).toInt();
        final int safeAmount = amountCents < 2000 ? 2000 : amountCents;
        final String basicAuth = base64.encode(utf8.encode('$secretKey:'));
        final http.Response intentResponse = await http.post(
          Uri.parse('https://api.paymongo.com/v1/payment_intents'),
          headers: {
            'Authorization': 'Basic $basicAuth',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'data': {
              'attributes': {
                'amount': safeAmount,
                'currency': 'PHP',
                'payment_method_allowed': [method],
                'payment_method_options': {
                  'card': {'request_three_d_secure': 'any'}
                },
                'description': 'Pasada Ride Payment',
                'redirect': {
                  'success': successRedirect,
                  'failed': failedRedirect,
                },
              },
            }
          }),
        );
        if (intentResponse.statusCode != 200) {
          final Map<String, dynamic> errBody = jsonDecode(intentResponse.body);
          final List<dynamic> errs = errBody['errors'] ?? [];
          throw Exception(errs.map((e) => e['detail']).join('\n'));
        }
        final Map<String, dynamic> intentBody = jsonDecode(intentResponse.body);
        final String? checkoutUrl = intentBody['data']?['attributes']
            ?['next_action']?['redirect']?['url'];
        if (checkoutUrl == null) {
          throw Exception('Missing redirect URL from PaymentIntent response');
        }
        final bool success = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentWebViewScreen(
                  url: checkoutUrl,
                  successUrl: successRedirect,
                  failedUrl: failedRedirect,
                ),
              ),
            ) ??
            false;
        if (success) {
          final String secretAuth = base64.encode(utf8.encode('$secretKey:'));
          final http.Response paymentResponse = await http.post(
            Uri.parse('https://api.paymongo.com/v1/payments'),
            headers: {
              'Authorization': 'Basic $secretAuth',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'data': {
                'attributes': {
                  'amount': safeAmount,
                  'currency': 'PHP',
                  'source': {
                    'id': intentBody['data']['id'],
                    'type': 'payment_intent',
                  },
                  'description': 'Pasada Ride Payment',
                }
              }
            }),
          );
          if (paymentResponse.statusCode != 200) {
            final Map<String, dynamic> errBody =
                jsonDecode(paymentResponse.body);
            final List<dynamic> errs = errBody['errors'] ?? [];
            throw Exception(errs.map((e) => e['detail']).join('\n'));
          }
          _onPaymentSuccess();
        }
      }
    } catch (e) {
      String errorMessage;
      if (e is PaymongoError) {
        errorMessage = 'Paymongo Error: ${e.toString()}';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }
      debugPrint('Payment Processing Error: $errorMessage');
      debugPrint('Full error object: $e');
      setState(() {
        isLoading = false;
        statusMessage = errorMessage;
      });
    }
  }

  void _onPaymentSuccess() {
    setState(() {
      isLoading = false;
      statusMessage = 'Payment successful!';
    });

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: screenSize.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Successful',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                        fontSize: 24,
                        color: isDarkMode
                            ? const Color(0xFFF5F5F5)
                            : const Color(0xFF121212),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFF121212),
                      width: double.infinity,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your payment has been processed successfully.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                        color: isDarkMode
                            ? const Color(0xFFDEDEDE)
                            : const Color(0xFF1E1E1E),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context,
                          true); // Return to previous screen with success result
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size(double.infinity, 40),
                      backgroundColor: const Color(0xFF00CC58),
                      foregroundColor: const Color(0xFFF5F5F5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
