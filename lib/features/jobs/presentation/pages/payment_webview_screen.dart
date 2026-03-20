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

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen>
    with WidgetsBindingObserver {
  late InAppWebViewController _webViewController;
  bool _isProcessingPayment = false;
  bool _paymentCompleted = false;
  bool _merchantSuccessSeen = false;
  bool _merchantErrorSeen = false;
  bool _is3DSChallengeActive = false;
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
    userAgent:
        "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
    hardwareAcceleration: true,
  );

  // ─── Helpers ───────────────────────────────────────────────────────────────

  bool _isSuccessUrl(String url) {
    if (url.isEmpty) return false;
    return url.contains('payment-success.html') ||
        url.contains('istapapp.netlify.app/payment-success');
  }

  bool _isErrorUrl(String url) {
    if (url.isEmpty) return false;
    return url.contains('payment-error.html') ||
        url.contains('istapapp.netlify.app/payment-error');
  }

  bool _is3DSUrl(String url) {
    return url.contains('methodurl.vcas.visa.com') ||
        url.contains('3dsecure') ||
        url.contains('3ds') ||
        url.contains('acs.') ||
        url.contains('securecode') ||
        url.contains('verifiedbyvisa') ||
        url.contains('ecomm.pashabank.az/ecomm2/ThreeDs') ||
        url.contains('ThreeDs2Handler');
  }

  // ─── Payment result handlers ────────────────────────────────────────────────

  void _handlePaymentSuccess() {
    if (_paymentCompleted) return;
    setState(() {
      _isProcessingPayment = true;
      _paymentCompleted = true;
    });
    debugPrint('✅ [PAYMENT] Payment SUCCESS, closing WebView');
    Navigator.pop(context, true);
  }

  void _handlePaymentError() {
    if (_paymentCompleted) return;
    setState(() {
      _isProcessingPayment = true;
      _paymentCompleted = true;
    });
    debugPrint('❌ [PAYMENT] Payment ERROR, closing WebView');
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

  // ─── Timeout ────────────────────────────────────────────────────────────────

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    final timeoutDuration = _is3DSChallengeActive
        ? const Duration(minutes: 10)
        : const Duration(minutes: 5);

    _timeoutTimer = Timer(timeoutDuration, () {
      if (!_paymentCompleted && mounted) {
        if (_merchantSuccessSeen) {
          _handlePaymentSuccess();
          return;
        }
        if (_merchantErrorSeen) {
          _handlePaymentError();
          return;
        }
        debugPrint('⏰ [TIMEOUT] Payment timeout after ${timeoutDuration.inMinutes} minutes');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Vaxt bitdi'),
            content: const Text(
                'Ödəniş prosesi çox uzun çəkdi. Zəhmət olmasa yenidən cəhd edin.'),
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

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimeoutTimer();
    debugPrint('🚀 [PAYMENT_WEBVIEW_INIT] URL: ${widget.url}');
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
    debugPrint('🔄 [LIFECYCLE] $state');
  }

  // ─── shouldOverrideUrlLoading (shared logic) ────────────────────────────────

  Future<NavigationActionPolicy> _handleNavigation(
    InAppWebViewController controller,
    NavigationAction navigationAction, {
    BuildContext? popContext,
  }) async {
    final uri = navigationAction.request.url!;
    final urlString = uri.toString();

    debugPrint('🌐 [NAV] $urlString');

    // 3DS URLs — always allow, extend timeout
    if (_is3DSUrl(urlString)) {
      debugPrint('🔐 [3DS] URL detected: $urlString');
      if (!_is3DSChallengeActive) {
        setState(() => _is3DSChallengeActive = true);
        _startTimeoutTimer();
      }
      return NavigationActionPolicy.ALLOW;
    }

    // External / custom schemes
    if (!['http', 'https', 'file', 'chrome', 'data', 'javascript', 'about']
        .contains(uri.scheme)) {
      debugPrint('🚀 [NAV] External scheme: ${uri.scheme}');
      try {
        if (uri.scheme == 'intent') {
          final match =
              RegExp(r'browser_fallback_url=([^;]+)').firstMatch(urlString);
          if (match != null) {
            final fallback = Uri.decodeComponent(match.group(1)!);
            await controller.loadUrl(
                urlRequest: URLRequest(url: WebUri(fallback)));
            return NavigationActionPolicy.CANCEL;
          }
        }
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('❌ [NAV] Cannot launch: $e');
      }
      return NavigationActionPolicy.CANCEL;
    }

    // Error / success URLs
    if (_isErrorUrl(urlString)) {
      _merchantErrorSeen = true;
      if (popContext != null && Navigator.canPop(popContext)) {
        Navigator.pop(popContext);
      }
      _handlePaymentError();
      return NavigationActionPolicy.CANCEL;
    }

    if (_isSuccessUrl(urlString)) {
      _merchantSuccessSeen = true;
      if (popContext != null && Navigator.canPop(popContext)) {
        Navigator.pop(popContext);
      }
      _handlePaymentSuccess();
      return NavigationActionPolicy.CANCEL;
    }

    return NavigationActionPolicy.ALLOW;
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_paymentCompleted || _isProcessingPayment) return;

        try {
          final canGoBack = await _webViewController.canGoBack();
          if (canGoBack) {
            await _webViewController.goBack();
            return;
          }
        } catch (e) {
          debugPrint('⚠️ [BACK] canGoBack error: $e');
        }

        if (!mounted) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ödənişdən çıxmaq istəyirsiniz?'),
            content: const Text(
                'Ödəniş prosesi yarımçıq qalacaq və ödəniş alınmayacaq.'),
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
          Navigator.pop(context, false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ödəniş'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: (_paymentCompleted || _isProcessingPayment)
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

                    // ── URL interception ──────────────────────────────────
                    shouldOverrideUrlLoading: (controller, navigationAction) =>
                        _handleNavigation(controller, navigationAction),

                    // ── Load events ───────────────────────────────────────
                    onLoadStart: (controller, url) async {
                      final urlStr = url?.toString() ?? '';
                      debugPrint('🌐 [LOAD_START] $urlStr');

                      if (_is3DSUrl(urlStr) && !_is3DSChallengeActive) {
                        setState(() => _is3DSChallengeActive = true);
                        _startTimeoutTimer();
                        debugPrint('⏰ [3DS] Timeout extended to 10 min');
                      }
                    },

                    onLoadStop: (controller, url) async {
                      final urlStr = url?.toString() ?? '';
                      debugPrint('🌐 [LOAD_STOP] $urlStr');

                      if (_is3DSUrl(urlStr)) {
                        debugPrint('🔐 [3DS_LOADED] $urlStr');

                        // Debug iframes on Authentication page
                        if (urlStr.contains('ThreeDs2Handler/Authentication')) {
                          try {
                            final iframes =
                                await controller.evaluateJavascript(source: """
                              (function() {
                                var iframes = document.querySelectorAll('iframe');
                                var result = [];
                                iframes.forEach(function(f) {
                                  result.push(f.src || 'no-src');
                                });
                                return JSON.stringify(result);
                              })();
                            """);
                            debugPrint('🔍 [3DS_DEBUG] IFRAMES: $iframes');

                            final html = await controller.getHtml();
                            if (html != null && html.isNotEmpty) {
                              debugPrint(
                                  '📄 [3DS_DEBUG] HTML: ${html.substring(0, html.length.clamp(0, 800))}');
                            }
                          } catch (e) {
                            debugPrint('⚠️ [3DS_DEBUG] Error: $e');
                          }
                        }
                      }

                      if (_isSuccessUrl(urlStr)) _merchantSuccessSeen = true;
                      if (_isErrorUrl(urlStr)) _merchantErrorSeen = true;
                    },

                    // ── Errors ────────────────────────────────────────────
                    onReceivedError: (controller, request, error) {
                      if (request.url.toString().contains('favicon.ico')) return;
                      debugPrint(
                          '🔴 [ERROR] ${error.description} | ${request.url}');

                      if (_is3DSUrl(request.url.toString()) &&
                          (error.type == WebResourceErrorType.TIMEOUT ||
                              error.type == WebResourceErrorType.HOST_LOOKUP)) {
                        debugPrint('🔴 [3DS_ERROR] 3DS server connection failed');
                        if (mounted && !_paymentCompleted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '⚠️ Bankın 3D Secure serveri cavab vermir.\n'
                                'Bir neçə dəqiqə sonra yenidən cəhd edin.',
                              ),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 8),
                            ),
                          );
                        }
                      }
                    },

                    onReceivedHttpError: (controller, request, errorResponse) {
                      if (request.url.toString().contains('favicon.ico')) return;
                      debugPrint(
                          '🔴 [HTTP_ERROR] ${errorResponse.statusCode} | ${request.url}');
                    },

                    onProgressChanged: (controller, progress) {
                      debugPrint('📊 [PROGRESS] $progress%');
                      setState(() => _progress = progress / 100);
                    },

                    onConsoleMessage: (controller, consoleMessage) {
                      debugPrint(
                          '🟡 [CONSOLE] [${consoleMessage.messageLevel}]: ${consoleMessage.message}');
                    },

                    // ── Popup / new window ────────────────────────────────
                    // CRITICAL FIX for LeoBank: use windowId, NOT loadUrl()
                    // Loading in same WebView destroys the JS parent context.
                    onCreateWindow: (controller, createWindowAction) async {
                      debugPrint(
                          '🪟 [POPUP] New window requested. windowId=${createWindowAction.windowId} url=${createWindowAction.request?.url}');

                      if (!mounted) return false;

                      await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (dialogContext) {
                          return Dialog(
                            insetPadding: EdgeInsets.zero,
                            child: SizedBox(
                              width: MediaQuery.of(dialogContext).size.width,
                              height:
                                  MediaQuery.of(dialogContext).size.height * 0.9,
                              child: Column(
                                children: [
                                  // Header bar
                                  Container(
                                    color: Colors.black87,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: Text(
                                            '3D Secure',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close,
                                              color: Colors.white),
                                          onPressed: () {
                                            if (Navigator.canPop(dialogContext)) {
                                              Navigator.pop(dialogContext);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  // WebView with windowId — preserves JS context!
                                  Expanded(
                                    child: InAppWebView(
                                      windowId: createWindowAction.windowId,
                                      initialSettings: _settings,
                                      shouldOverrideUrlLoading:
                                          (ctrl, nav) async {
                                        return _handleNavigation(ctrl, nav,
                                            popContext: dialogContext);
                                      },
                                      onLoadStart: (ctrl, url) async {
                                        final urlStr = url?.toString() ?? '';
                                        debugPrint(
                                            '🌐 [POPUP_LOAD_START] $urlStr');
                                        if (_isSuccessUrl(urlStr)) {
                                          if (Navigator.canPop(dialogContext)) {
                                            Navigator.pop(dialogContext);
                                          }
                                          _handlePaymentSuccess();
                                        } else if (_isErrorUrl(urlStr)) {
                                          if (Navigator.canPop(dialogContext)) {
                                            Navigator.pop(dialogContext);
                                          }
                                          _handlePaymentError();
                                        }
                                      },
                                      onLoadStop: (ctrl, url) async {
                                        final urlStr = url?.toString() ?? '';
                                        debugPrint(
                                            '🌐 [POPUP_LOAD_STOP] $urlStr');
                                        if (_isSuccessUrl(urlStr)) {
                                          if (Navigator.canPop(dialogContext)) {
                                            Navigator.pop(dialogContext);
                                          }
                                          _handlePaymentSuccess();
                                        } else if (_isErrorUrl(urlStr)) {
                                          if (Navigator.canPop(dialogContext)) {
                                            Navigator.pop(dialogContext);
                                          }
                                          _handlePaymentError();
                                        }
                                      },
                                      onCloseWindow: (ctrl) {
                                        debugPrint(
                                            '🪟 [POPUP_CLOSE] Closed by JS');
                                        if (Navigator.canPop(dialogContext)) {
                                          Navigator.pop(dialogContext);
                                        }
                                      },
                                      onReceivedError:
                                          (ctrl, request, error) {
                                        if (request.url
                                            .toString()
                                            .contains('favicon.ico')) return;
                                        debugPrint(
                                            '🔴 [POPUP_ERROR] ${error.description} | ${request.url}');
                                      },
                                      onReceivedHttpError:
                                          (ctrl, request, errorResponse) {
                                        if (request.url
                                            .toString()
                                            .contains('favicon.ico')) return;
                                        debugPrint(
                                            '🔴 [POPUP_HTTP_ERROR] ${errorResponse.statusCode} | ${request.url}');
                                      },
                                      onConsoleMessage: (ctrl, msg) {
                                        debugPrint(
                                            '🟡 [POPUP_CONSOLE] ${msg.message}');
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );

                      return true;
                    },
                  ),

                  // Progress bar
                  if (_progress < 1.0)
                    LinearProgressIndicator(value: _progress),
                ],
              ),
      ),
    );
  }
}