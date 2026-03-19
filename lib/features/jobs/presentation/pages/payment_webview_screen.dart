import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

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
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone",
    iframeAllowFullscreen: true,
    javaScriptEnabled: true,
    javaScriptCanOpenWindowsAutomatically: true,
    supportMultipleWindows: true,
    transparentBackground: false,
    allowUniversalAccessFromFileURLs: true,
    allowFileAccessFromFileURLs: true,
    useOnLoadResource: true,
    useHybridComposition: true,
    allowsBackForwardNavigationGestures: false,
    incognito: false,
    safeBrowsingEnabled: false,
    isFraudulentWebsiteWarningEnabled: false,
    clearSessionCache: false,
    cacheEnabled: true,
    thirdPartyCookiesEnabled: true,
    sharedCookiesEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
    userAgent:
        "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36",
    // Ekstra donanım ve render ayarları (bazı cihazlarda beyaz sayfa kalmasını önler)
    hardwareAcceleration: true,
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
    // Kullanıcıya hata mesajı göster
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ödəniş uğursuz oldu. Zəhmət olmasa kartınızı və 3D Secure kodunu yoxlayın.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    });
    Navigator.pop(context, false);
  }

  bool _isSuccessUrl(String url) {
    if (url.isEmpty || url.trim().isEmpty) return false;
    return url.contains('payment-success.html') ||
        url.contains('pay-successful') ||
        url.contains('pay-success') ||
        url.contains('success=true') ||
        url.contains('istapapp.netlify.app/payment-success') ||
        (url.contains('netlify.app') && url.contains('success'));
  }

  bool _isErrorUrl(String url) {
    if (url.isEmpty || url.trim().isEmpty) return false;
    // Epoint'in kendi error sayfasını da kontrol et
    return url.contains('payment-error.html') ||
        url.contains('pay-error') ||
        url.contains('error=true') ||
        url.contains('istapapp.netlify.app/payment-error') ||
        (url.contains('epoint.az') && url.contains('error')) ||
        (url.contains('netlify.app') && url.contains('error'));
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
                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    var uri = navigationAction.request.url!;
                    final urlString = uri.toString();

                    debugPrint("🌐 Intercepting URL: $urlString");

                    // Banka uygulaması veya diğer intent/custom scheme linkleri
                    if (![
                      "http",
                      "https",
                      "file",
                      "chrome",
                      "data",
                      "javascript",
                      "about",
                    ].contains(uri.scheme)) {
                      debugPrint("🚀 External scheme detected: ${uri.scheme}");
                      try {
                        // intent URL'sini manuel parse edip doğrudan açmayı deneyelim
                        if (uri.scheme == 'intent') {
                          final intentUrl = uri.toString();
                          // Basit bir fallback URL ayıklaması
                          final fallbackRegex = RegExp(
                            r'browser_fallback_url=([^;]+)',
                          );
                          final match = fallbackRegex.firstMatch(intentUrl);
                          if (match != null && match.groupCount >= 1) {
                            final fallbackUrl = Uri.decodeComponent(
                              match.group(1)!,
                            );
                            debugPrint(
                              "🚀 Intent fallback found: $fallbackUrl",
                            );
                            await controller.loadUrl(
                              urlRequest: URLRequest(url: WebUri(fallbackUrl)),
                            );
                            return NavigationActionPolicy.CANCEL;
                          }
                        }

                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          return NavigationActionPolicy.CANCEL;
                        } else {
                          debugPrint("❌ canLaunchUrl returned false for: $uri");
                        }
                      } catch (e) {
                        debugPrint("❌ Could not launch external url: $e");
                      }
                    }

                    // Eğer EPoint hata sayfasına düşerse direkt yakala
                    if (_isErrorUrl(urlString)) {
                      debugPrint(
                        "🚨 Error URL matched in shouldOverride, triggering handlePaymentError",
                      );
                      _handlePaymentError();
                      return NavigationActionPolicy
                          .CANCEL; // Veya ALLOW, ama genelde CANCEL edip kapatmak iyidir
                    }

                    if (_isSuccessUrl(urlString)) {
                      debugPrint(
                        "✅ Success URL matched in shouldOverride, triggering handlePaymentSuccess",
                      );
                      _handlePaymentSuccess();
                      return NavigationActionPolicy.CANCEL;
                    }

                    return NavigationActionPolicy.ALLOW;
                  },
                  onLoadStart: (controller, url) async {
                    debugPrint("Started loading: $url");
                    final urlStr = url?.toString() ?? "";

                    // Ecomm2 fingerprinting sayfasını atlattırmak için script enjekte edelim
                    if (urlStr.contains(
                      'ecomm.pashabank.az/ecomm2/ThreeDs2Handler',
                    )) {
                      await controller.evaluateJavascript(
                        source: """
                        // Meta element parsing hatasını ezmek için geçici çözüm
                        var metas = document.getElementsByTagName('meta');
                        for (var i=0; i<metas.length; i++) {
                          if (metas[i].content && metas[i].content.includes(';')) {
                            metas[i].content = metas[i].content.replace(/;/g, ',');
                          }
                        }
                      """,
                      );
                    }

                    if (_isSuccessUrl(urlStr)) {
                      _handlePaymentSuccess();
                    } else if (_isErrorUrl(urlStr)) {
                      _handlePaymentError();
                    }
                  },
                  onLoadStop: (controller, url) async {
                    debugPrint("Finished loading: $url");
                    final urlStr = url?.toString() ?? "";

                    if (_isSuccessUrl(urlStr)) {
                      _handlePaymentSuccess();
                    } else if (_isErrorUrl(urlStr)) {
                      _handlePaymentError();
                    }
                  },
                  onReceivedError: (controller, request, error) {
                    // Ignore favicon errors and main frame loading errors for intents
                    if (request.url.toString().contains('favicon.ico')) return;
                    debugPrint(
                      "🔴 WebView Error: ${error.description} for URL: ${request.url}",
                    );
                  },
                  onReceivedHttpError: (controller, request, errorResponse) {
                    if (request.url.toString().contains('favicon.ico')) return;
                    debugPrint(
                      "🔴 WebView HTTP Error: ${errorResponse.statusCode} - ${errorResponse.reasonPhrase} for URL: ${request.url}",
                    );
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      _progress = progress / 100;
                    });
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    debugPrint(
                      "🟡 WebView Console [${consoleMessage.messageLevel}]: ${consoleMessage.message}",
                    );
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
                              onWebViewCreated: (controller) {},
                              shouldOverrideUrlLoading: (controller, navigationAction) async {
                                var uri = navigationAction.request.url!;
                                final urlString = uri.toString();
                                debugPrint(
                                  "🌐 Popup Intercepting URL: $urlString",
                                );

                                if (![
                                  "http",
                                  "https",
                                  "file",
                                  "chrome",
                                  "data",
                                  "javascript",
                                  "about",
                                ].contains(uri.scheme)) {
                                  debugPrint(
                                    "🚀 Popup External scheme detected: ${uri.scheme}",
                                  );
                                  try {
                                    if (uri.scheme == 'intent') {
                                      final intentUrl = uri.toString();
                                      final fallbackRegex = RegExp(
                                        r'browser_fallback_url=([^;]+)',
                                      );
                                      final match = fallbackRegex.firstMatch(
                                        intentUrl,
                                      );
                                      if (match != null &&
                                          match.groupCount >= 1) {
                                        final fallbackUrl = Uri.decodeComponent(
                                          match.group(1)!,
                                        );
                                        debugPrint(
                                          "🚀 Popup Intent fallback found: $fallbackUrl",
                                        );
                                        await controller.loadUrl(
                                          urlRequest: URLRequest(
                                            url: WebUri(fallbackUrl),
                                          ),
                                        );
                                        return NavigationActionPolicy.CANCEL;
                                      }
                                    }

                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                      return NavigationActionPolicy.CANCEL;
                                    } else {
                                      debugPrint(
                                        "❌ Popup canLaunchUrl returned false for: $uri",
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint(
                                      "❌ Popup Could not launch external url: $e",
                                    );
                                  }
                                }

                                if (_isErrorUrl(urlString)) {
                                  debugPrint(
                                    "🚨 Popup Error URL matched in shouldOverride",
                                  );
                                  if (Navigator.canPop(context))
                                    Navigator.pop(context);
                                  _handlePaymentError();
                                  return NavigationActionPolicy.CANCEL;
                                }

                                if (_isSuccessUrl(urlString)) {
                                  debugPrint(
                                    "✅ Popup Success URL matched in shouldOverride",
                                  );
                                  if (Navigator.canPop(context))
                                    Navigator.pop(context);
                                  _handlePaymentSuccess();
                                  return NavigationActionPolicy.CANCEL;
                                }

                                return NavigationActionPolicy.ALLOW;
                              },
                              onCloseWindow: (controller) async {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              },
                              onLoadStart: (controller, url) async {
                                final urlStr = url?.toString() ?? "";
                                debugPrint("Popup Started loading: $url");
                                if (_isSuccessUrl(urlStr)) {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                  _handlePaymentSuccess();
                                } else if (_isErrorUrl(urlStr)) {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                  _handlePaymentError();
                                }
                              },
                              onLoadStop: (controller, url) async {
                                final urlStr = url?.toString() ?? "";
                                debugPrint("Popup Finished loading: $url");
                                if (_isSuccessUrl(urlStr)) {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                  _handlePaymentSuccess();
                                } else if (_isErrorUrl(urlStr)) {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                  _handlePaymentError();
                                }
                              },
                              onReceivedError: (controller, request, error) {
                                if (request.url.toString().contains(
                                  'favicon.ico',
                                ))
                                  return;
                                debugPrint(
                                  "🔴 Popup WebView Error: ${error.description} for URL: ${request.url}",
                                );
                              },
                              onReceivedHttpError:
                                  (controller, request, errorResponse) {
                                    if (request.url.toString().contains(
                                      'favicon.ico',
                                    ))
                                      return;
                                    debugPrint(
                                      "🔴 Popup WebView HTTP Error: ${errorResponse.statusCode} - ${errorResponse.reasonPhrase} for URL: ${request.url}",
                                    );
                                  },
                              onConsoleMessage: (controller, consoleMessage) {
                                debugPrint(
                                  "🟡 Popup WebView Console: ${consoleMessage.message}",
                                );
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
