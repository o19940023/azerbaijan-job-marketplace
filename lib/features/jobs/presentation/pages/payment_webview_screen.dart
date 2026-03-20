import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String url;

  const PaymentWebViewScreen({super.key, required this.url});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> with WidgetsBindingObserver {
  late InAppWebViewController _webViewController;
  bool _isProcessingPayment = false;
  bool _paymentCompleted = false;
  bool _successPending = false;
  bool _errorPending = false;
  double _progress = 0;
  Timer? _timeoutTimer;

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
    // Epoint-recommended settings for 3DS2
    allowContentAccess: true,
    allowFileAccess: true,
    useWideViewPort: true,
    loadWithOverviewMode: true,
    supportZoom: true,
    builtInZoomControls: false,
    displayZoomControls: false,
    verticalScrollBarEnabled: true,
    horizontalScrollBarEnabled: true,
    geolocationEnabled: true,
    // Chrome 120 user agent for 3DS2 compatibility
    userAgent:
        "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
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
    debugPrint("❌ [PAYMENT_ERROR] Payment ERROR detected, closing WebView");
    
    // Kullanıcıya detaylı hata mesajı göster
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ Ödəniş uğursuz oldu!\n\n'
              'Səbəblər:\n'
              '• Kartda kifayət qədər balans yoxdur\n'
              '• Kartın online ödəniş limiti bağlıdır\n'
              '• 3D Secure kodu yanlış daxil edilib\n'
              '• Bank ödənişi təhlükəsizlik səbəbindən rədd edib\n\n'
              'Zəhmət olmasa kartınızı yoxlayın və ya başqa kart sınayın.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 8),
          ),
        );
      }
    });
    Navigator.pop(context, false);
  }

  bool _isSuccessUrl(String url) {
    if (url.isEmpty || url.trim().isEmpty) return false;
    
    // IMPORTANT:
    // Epoint docs says final result page is our merchant-provided success_redirect_url.
    // So we only treat our exact success page as success.
    if (url.contains('payment-success.html')) return true;
    if (url.contains('istapapp.netlify.app/payment-success')) return true;
    return false;
  }

  bool _isErrorUrl(String url) {
    if (url.isEmpty || url.trim().isEmpty) return false;
    
    // IMPORTANT:
    // Only treat our exact error_redirect_url page as error.
    if (url.contains('payment-error.html')) return true;
    if (url.contains('istapapp.netlify.app/payment-error')) return true;
    return false;
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(minutes: 5), () {
      if (!_paymentCompleted && mounted) {
        debugPrint('⏰ [PAYMENT_TIMEOUT] Payment timeout after 5 minutes');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Vaxt bitdi'),
            content: const Text(
              'Ödəniş prosesi çox uzun çəkdi. Zəhmət olmasa yenidən cəhd edin.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, false);
                },
                child: const Text('Bağla'),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimeoutTimer();
    debugPrint('🚀 [PAYMENT_WEBVIEW_INIT] Payment WebView initialized with URL: ${widget.url}');
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('🔚 [PAYMENT_WEBVIEW_DISPOSE] Payment WebView disposed');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('🔄 [PAYMENT_LIFECYCLE] App lifecycle changed to: $state');
    if (state == AppLifecycleState.paused) {
      debugPrint('⏸️ [PAYMENT_LIFECYCLE] App went to background during payment');
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('▶️ [PAYMENT_LIFECYCLE] App returned to foreground during payment');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Asla direkt kapanmasın
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // Ödeme tamamlandıysa çıkışa izin verme
        if (_paymentCompleted || _isProcessingPayment) {
          debugPrint('🔒 [PAYMENT_BACK_BUTTON] Payment completed, blocking back button');
          return;
        }
        
        // WebView'da geri gidilecek sayfa var mı kontrol et
        try {
          final canGoBack = await _webViewController.canGoBack();
          if (canGoBack) {
            await _webViewController.goBack();
            debugPrint('🔙 [PAYMENT_BACK_BUTTON] WebView went back in history');
            return;
          }
        } catch (e) {
          debugPrint('⚠️ [PAYMENT_BACK_BUTTON] Error checking canGoBack: $e');
        }
        
        // WebView'da geri gidilecek sayfa yoksa, kullanıcıya sor
        if (!mounted) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ödənişdən çıxmaq istəyirsiniz?'),
            content: const Text(
              'Ödəniş prosesi yarımçıq qalacaq və ödəniş alınmayacaq.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Xeyr, davam et'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Bəli, çıx'),
              ),
            ],
          ),
        );
        
        if (shouldPop == true && mounted) {
          debugPrint('❌ [PAYMENT_BACK_BUTTON] User confirmed exit, closing WebView');
          Navigator.pop(context, false);
        } else {
          debugPrint('↩️ [PAYMENT_BACK_BUTTON] User cancelled exit');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ödəniş'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: (_paymentCompleted || _isProcessingPayment)
                ? null
                : () {
                    debugPrint('❌ [PAYMENT_CLOSE_BUTTON] User pressed close button');
                    Navigator.pop(context, false);
                  },
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

                    // Detailed URL logging
                    debugPrint("🌐 [WEBVIEW_NAVIGATION] Full URL: $urlString");
                    debugPrint("🌐 [WEBVIEW_NAVIGATION] Scheme: ${uri.scheme}");
                    debugPrint("🌐 [WEBVIEW_NAVIGATION] Host: ${uri.host}");
                    debugPrint("🌐 [WEBVIEW_NAVIGATION] Path: ${uri.path}");
                    if (uri.queryParameters.isNotEmpty) {
                      debugPrint("🌐 [WEBVIEW_NAVIGATION] Query params: ${uri.queryParameters}");
                    }

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
                        "🚨 Error URL matched in shouldOverride, closing WebView immediately",
                      );
                      _handlePaymentError();
                      return NavigationActionPolicy.CANCEL;
                    }

                    if (_isSuccessUrl(urlString)) {
                      debugPrint(
                        "✅ Success URL matched in shouldOverride, deferring close until onLoadStop",
                      );
                      setState(() {
                        _isProcessingPayment = true;
                        _successPending = true;
                      });
                      return NavigationActionPolicy.ALLOW;
                    }

                    return NavigationActionPolicy.ALLOW;
                  },
                  onLoadStart: (controller, url) async {
                    final urlStr = url?.toString() ?? "";
                    debugPrint("🌐 [WEBVIEW_NAVIGATION] onLoadStart: $urlStr");

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

                    // Do not close the WebView on loadStart.
                    // We'll close only after the success/error page fully loads (onLoadStop).
                  },
                  onLoadStop: (controller, url) async {
                    final urlStr = url?.toString() ?? "";
                    debugPrint("🌐 [WEBVIEW_NAVIGATION] onLoadStop: $urlStr");

                    if (_successPending && _isSuccessUrl(urlStr)) {
                      _successPending = false;
                      _handlePaymentSuccess();
                    } else if (_errorPending && _isErrorUrl(urlStr)) {
                      _errorPending = false;
                      _handlePaymentError();
                    }
                  },
                  onReceivedError: (controller, request, error) {
                    // Ignore favicon errors and main frame loading errors for intents
                    if (request.url.toString().contains('favicon.ico')) return;
                    debugPrint(
                      "🔴 [WEBVIEW_ERROR] Error: ${error.description}",
                    );
                    debugPrint(
                      "🔴 [WEBVIEW_ERROR] Error code: ${error.type}",
                    );
                    debugPrint(
                      "🔴 [WEBVIEW_ERROR] URL: ${request.url}",
                    );
                  },
                  onReceivedHttpError: (controller, request, errorResponse) {
                    if (request.url.toString().contains('favicon.ico')) return;
                    debugPrint(
                      "🔴 [WEBVIEW_HTTP_ERROR] Status: ${errorResponse.statusCode}",
                    );
                    debugPrint(
                      "🔴 [WEBVIEW_HTTP_ERROR] Reason: ${errorResponse.reasonPhrase}",
                    );
                    debugPrint(
                      "🔴 [WEBVIEW_HTTP_ERROR] URL: ${request.url}",
                    );
                  },
                  onProgressChanged: (controller, progress) {
                    debugPrint("📊 [WEBVIEW_PROGRESS] Loading: $progress%");
                    setState(() {
                      _progress = progress / 100;
                    });
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    debugPrint(
                      "🟡 [WEBVIEW_CONSOLE] [${consoleMessage.messageLevel}]: ${consoleMessage.message}",
                    );
                  },
                  onCreateWindow: (controller, createWindowAction) async {
                    debugPrint("🪟 [WEBVIEW_POPUP] 3DSecure/Bank popup window requested.");
                    debugPrint("🪟 [WEBVIEW_POPUP] Window ID: ${createWindowAction.windowId}");

                    // Epoint recommendation: Load request in same WebView first
                    if (createWindowAction.request != null) {
                      debugPrint("🪟 [WEBVIEW_POPUP] Loading request in same WebView");
                      await _webViewController.loadUrl(
                        urlRequest: createWindowAction.request!,
                      );
                      return true;
                    }

                    // Fallback to dialog if no request
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
                                debugPrint("🌐 [POPUP_NAVIGATION] onLoadStart: $urlStr");
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
                                debugPrint("🌐 [POPUP_NAVIGATION] onLoadStop: $urlStr");
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
                                  "🔴 [POPUP_ERROR] ${error.description} for URL: ${request.url}",
                                );
                              },
                              onReceivedHttpError:
                                  (controller, request, errorResponse) {
                                    if (request.url.toString().contains(
                                      'favicon.ico',
                                    ))
                                      return;
                                    debugPrint(
                                      "🔴 [POPUP_HTTP_ERROR] ${errorResponse.statusCode} - ${errorResponse.reasonPhrase} for URL: ${request.url}",
                                    );
                                  },
                              onConsoleMessage: (controller, consoleMessage) {
                                debugPrint(
                                  "🟡 [POPUP_CONSOLE] ${consoleMessage.message}",
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
      ),
    );
  }
}
