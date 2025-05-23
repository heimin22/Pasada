import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String url;
  final String successUrl;
  final String failedUrl;

  const PaymentWebViewScreen({
    super.key,
    required this.url,
    required this.successUrl,
    required this.failedUrl,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Check if the URL is the success or failed URL
            if (request.url.startsWith(widget.successUrl)) {
              Navigator.pop(context, true); // Return success
              return NavigationDecision.prevent;
            } else if (request.url.startsWith(widget.failedUrl)) {
              Navigator.pop(context, false); // Return failure
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complete Payment',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
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
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF00CC58)),
            ),
        ],
      ),
    );
  }
}
