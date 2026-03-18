import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String url;

  const PaymentWebViewScreen({super.key, required this.url});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isProcessingPayment = false;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            debugPrint("Navigating to: $url");

            // Duplicate navigation'ları önle
            if (_isProcessingPayment || _paymentCompleted) {
              return NavigationDecision.prevent;
            }

            // Success URL pattern'leri
            if (url.contains('payment-success.html') ||
                url.contains('success') ||
                url.contains('pay-successful')) {
              _handlePaymentSuccess();
              return NavigationDecision.prevent;
            }
            
            // Error URL pattern'leri
            if (url.contains('payment-error.html') ||
                url.contains('error') ||
                url.contains('fail')) {
              _handlePaymentError();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) {
            debugPrint("Page finished loading: $url");
            
            // Sayfa yüklendikten sonra tekrar kontrol et
            if (_paymentCompleted) return;
            
            // Success pattern'leri
            if (url.contains('payment-success.html') ||
                url.contains('success') ||
                url.contains('pay-successful')) {
              _handlePaymentSuccess();
            }
            // Error pattern'leri
            else if (url.contains('payment-error.html') ||
                url.contains('error') ||
                url.contains('fail')) {
              _handlePaymentError();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _handlePaymentSuccess() {
    if (_paymentCompleted) return;
    setState(() {
      _isProcessingPayment = true;
      _paymentCompleted = true;
    });
    debugPrint("Payment SUCCESS detected, closing WebView");
    Navigator.pop(context, true);
  }

  void _handlePaymentError() {
    if (_paymentCompleted) return;
    setState(() {
      _isProcessingPayment = true;
      _paymentCompleted = true;
    });
    debugPrint("Payment ERROR detected, closing WebView");
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödəniş'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _paymentCompleted 
              ? null 
              : () => Navigator.pop(context, false), // Ləğv edildi
        ),
      ),
      body: _isProcessingPayment
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Ödəniş təsdiqlənir...'),
                ],
              ),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}
