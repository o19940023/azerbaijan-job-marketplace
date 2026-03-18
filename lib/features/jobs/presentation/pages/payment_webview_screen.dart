import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String url;

  const PaymentWebViewScreen({super.key, required this.url});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late InAppWebViewController _webViewController;
  bool _isProcessingPayment = false;
  bool _paymentCompleted = false;
  double _progress = 0;

  final InAppWebViewSettings _settings = InAppWebViewSettings(
    useShouldOverrideUrlLoading: false,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone",
    iframeAllowFullscreen: true,
    javaScriptEnabled: true,
    javaScriptCanOpenWindowsAutomatically: true,
    supportMultipleWindows: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    clearSessionCache: true,
    cacheEnabled: false,
    transparentBackground: true,
    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
    thirdPartyCookiesEnabled: true,
    allowUniversalAccessFromFileURLs: true,
    allowFileAccessFromFileURLs: true,
    useOnLoadResource: true,
    userAgent:
        "Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36",
  );

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
              : () => Navigator.pop(context, false),
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
          : Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                  initialSettings: _settings,
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                  onLoadStart: (controller, url) async {
                    debugPrint("Started loading: $url");
                    final urlStr = url?.toString() ?? "";

                    if (urlStr.contains('payment-success.html') ||
                        urlStr.contains('pay-successful') ||
                        (urlStr.contains('netlify.app') &&
                            urlStr.contains('success'))) {
                      _handlePaymentSuccess();
                    } else if (urlStr.contains('payment-error.html') ||
                        urlStr.contains('pay-error') ||
                        (urlStr.contains('netlify.app') &&
                            urlStr.contains('error'))) {
                      _handlePaymentError();
                    }
                  },
                  onLoadStop: (controller, url) async {
                    debugPrint("Finished loading: $url");
                    final urlStr = url?.toString() ?? "";

                    if (urlStr.contains('payment-success.html') ||
                        urlStr.contains('pay-successful') ||
                        (urlStr.contains('netlify.app') &&
                            urlStr.contains('success'))) {
                      _handlePaymentSuccess();
                    } else if (urlStr.contains('payment-error.html') ||
                        urlStr.contains('pay-error') ||
                        (urlStr.contains('netlify.app') &&
                            urlStr.contains('error'))) {
                      _handlePaymentError();
                    }
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      _progress = progress / 100;
                    });
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    debugPrint("WebView Console: ${consoleMessage.message}");
                  },
                  onCreateWindow: (controller, createWindowAction) async {
                    debugPrint("3DSecure/Bank popup window requested.");

                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          contentPadding: EdgeInsets.zero,
                          content: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height * 0.8,
                            child: InAppWebView(
                              windowId: createWindowAction.windowId,
                              initialSettings: _settings,
                              onCloseWindow: (controller) async {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              },
                              onLoadStart: (controller, url) async {
                                final urlStr = url?.toString() ?? "";
                                debugPrint("Popup Started loading: $url");
                                if (urlStr.contains('payment-success.html') ||
                                    urlStr.contains('pay-successful') ||
                                    (urlStr.contains('netlify.app') &&
                                        urlStr.contains('success'))) {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                  _handlePaymentSuccess();
                                } else if (urlStr.contains(
                                      'payment-error.html',
                                    ) ||
                                    urlStr.contains('pay-error') ||
                                    (urlStr.contains('netlify.app') &&
                                        urlStr.contains('error'))) {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                  _handlePaymentError();
                                }
                              },
                              onLoadStop: (controller, url) async {
                                final urlStr = url?.toString() ?? "";
                                debugPrint("Popup Finished loading: $url");
                                if (urlStr.contains('payment-success.html') ||
                                    urlStr.contains('pay-successful') ||
                                    (urlStr.contains('netlify.app') &&
                                        urlStr.contains('success'))) {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                  _handlePaymentSuccess();
                                } else if (urlStr.contains(
                                      'payment-error.html',
                                    ) ||
                                    urlStr.contains('pay-error') ||
                                    (urlStr.contains('netlify.app') &&
                                        urlStr.contains('error'))) {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                  _handlePaymentError();
                                }
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text("Bağla"),
                            ),
                          ],
                        );
                      },
                    );
                    return true;
                  },
                ),
                if (_progress < 1.0) LinearProgressIndicator(value: _progress),
              ],
            ),
    );
  }
}
