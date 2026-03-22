import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/services/remote_config_service.dart';
import '../../../../core/widgets/update_dialog.dart';
import '../../../../core/navigation/app_router.dart';

// ─────────────────────────────────────────────────────────────────
//  COLORS
// ─────────────────────────────────────────────────────────────────

const _kBg        = Color(0xFF07070F);
const _kAccent    = Color(0xFF5B5FEF);   // electric indigo
const _kAccent2   = Color(0xFF38BDF8);   // sky blue
const _kGold      = Color(0xFFD4AF37);
const _kRingColor = Color(0xFF5B5FEF);

// ─────────────────────────────────────────────────────────────────
//  SONAR RING PAINTER
// ─────────────────────────────────────────────────────────────────

class _SonarPainter extends CustomPainter {
  final double t; // 0..1 looping progress

  const _SonarPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = size.width * 0.72;

    // Draw 4 rings at different phase offsets
    for (int i = 0; i < 4; i++) {
      final phase = (t + i * 0.25) % 1.0;
      final radius = phase * maxR;
      final opacity = (1.0 - phase) * 0.18;

      if (opacity <= 0) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _kRingColor.withOpacity(opacity);

      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }

    // Tiny inner glow dot
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28)
      ..color = _kAccent.withOpacity(0.25);
    canvas.drawCircle(Offset(cx, cy), 40, glowPaint);
  }

  @override
  bool shouldRepaint(_SonarPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────────
//  STAR FIELD PAINTER  (subtle parallax background)
// ─────────────────────────────────────────────────────────────────

class _StarFieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;

  const _StarFieldPainter(this.stars, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      final flicker = 0.3 + 0.7 * ((math.sin(t * math.pi * 2 * s.speed + s.phase) + 1) / 2);
      paint.color = Colors.white.withOpacity(s.opacity * flicker);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter old) => old.t != t;
}

class _Star {
  final double x, y, radius, opacity, speed, phase;
  const _Star(this.x, this.y, this.radius, this.opacity, this.speed, this.phase);
}

// ─────────────────────────────────────────────────────────────────
//  SPLASH SCREEN
// ─────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Controllers
  late final AnimationController _sonarCtrl;   // sonar rings (looping)
  late final AnimationController _starCtrl;    // star field twinkle (looping)
  late final AnimationController _entryCtrl;   // one-shot entrance sequence
  late final AnimationController _progressCtrl; // bottom progress bar

  // Derived animations
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _dotOpacity;

  // Star field (pre-generated, deterministic)
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();

    // Force dark status bar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Generate stars
    final rng = math.Random(42);
    _stars = List.generate(60, (_) => _Star(
      rng.nextDouble(),
      rng.nextDouble(),
      rng.nextDouble() * 1.2 + 0.3,
      rng.nextDouble() * 0.5 + 0.1,
      rng.nextDouble() * 0.6 + 0.2,
      rng.nextDouble() * math.pi * 2,
    ));

    // Looping controllers
    _sonarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    // Entry sequence — 1400ms total, staggered
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Progress bar
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // Logo: 0..0.55 of entry
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Tagline: 0.45..1.0 of entry
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.45, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    // Status dot: 0.8..1.0
    _dotOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
      ),
    );

    // Kick off
    _entryCtrl.forward().then((_) {
      _progressCtrl.forward();
      Future.delayed(const Duration(milliseconds: 1800), () async {
        if (!mounted) return;
        try {
          final isUpdateRequired = await _checkVersion();
          if (!isUpdateRequired && mounted) {
            await _checkAuthAndNavigate();
          }
        } catch (e) {
          debugPrint('Splash nav error: $e');
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRouter.roleSelection);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _sonarCtrl.dispose();
    _starCtrl.dispose();
    _entryCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  // ── Version check (unchanged logic) ──────────────────────────────

  Future<bool> _checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final minVersion = RemoteConfigService().getMinAppVersion();
      final latestVersion = RemoteConfigService().getLatestAppVersion();

      if (_isVersionLower(currentVersion, minVersion)) {
        if (mounted) await showUpdateDialog(context, isMandatory: true);
        return true;
      }
      if (_isVersionLower(currentVersion, latestVersion)) {
        if (mounted) await showUpdateDialog(context, isMandatory: false);
        return false;
      }
    } catch (e) {
      debugPrint('Version check error: $e');
    }
    return false;
  }

  bool _isVersionLower(String current, String min) {
    try {
      final c = current.split('.').map(int.parse).toList();
      final m = min.split('.').map(int.parse).toList();
      for (var i = 0; i < 3; i++) {
        final cv = i < c.length ? c[i] : 0;
        final mv = i < m.length ? m[i] : 0;
        if (cv < mv) return true;
        if (cv > mv) return false;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 5));

          if (doc.exists && mounted) {
            final data = doc.data();
            final userType = data?['userType'] as String? ?? '';

            // FCM token refresh (fire-and-forget)
            FirebaseMessaging.instance.getToken().then((token) {
              if (token != null) {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({'fcmToken': token})
                    .catchError((_) {});
              }
            }).catchError((_) {});

            if (!mounted) return;
            Navigator.pushReplacementNamed(
              context,
              userType == 'employer'
                  ? AppRouter.employerHome
                  : AppRouter.jobSeekerHome,
            );
            return;
          }
        } catch (e) {
          debugPrint('Firestore error: $e');
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRouter.jobSeekerHome);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
    }
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRouter.roleSelection);
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── 1. Star field ──────────────────────────────────────
          AnimatedBuilder(
            animation: _starCtrl,
            builder: (_, __) => CustomPaint(
              painter: _StarFieldPainter(_stars, _starCtrl.value),
              size: Size.infinite,
            ),
          ),

          // ── 2. Sonar rings ─────────────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _sonarCtrl,
              builder: (_, __) => SizedBox(
                width: size.width,
                height: size.width,
                child: CustomPaint(
                  painter: _SonarPainter(_sonarCtrl.value),
                ),
              ),
            ),
          ),

          // ── 3. Center content ──────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo mark
                _buildLogoMark(),
                const SizedBox(height: 28),

                // Wordmark
                _buildWordmark(),
                const SizedBox(height: 10),

                // Tagline
                _buildTagline(),
                const SizedBox(height: 20),

                // Status dot
                _buildStatusDot(),
              ],
            ),
          ),

          // ── 4. Bottom progress line ────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildProgressBar(size),
          ),

          // ── 5. Version text ────────────────────────────────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _dotOpacity,
              child: const Text(
                'by İşTap',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo mark ────────────────────────────────────────────────────

  Widget _buildLogoMark() {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, __) => Transform.scale(
        scale: _logoScale.value,
        child: Opacity(
          opacity: _logoOpacity.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kAccent.withOpacity(0.35),
                      blurRadius: 50,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
              // Gradient ring
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      _kAccent.withOpacity(0.0),
                      _kAccent,
                      _kAccent2,
                      _kAccent.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                    transform: GradientRotation(
                      _sonarCtrl.value * math.pi * 2,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kBg,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icons/Logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _FallbackLogo(),
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

  // ── Wordmark ─────────────────────────────────────────────────────

  Widget _buildWordmark() {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, __) => Opacity(
        opacity: _logoOpacity.value,
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFCDD5F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'İşTap',
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1.5,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }

  // ── Tagline ───────────────────────────────────────────────────────

  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, child) => SlideTransition(
        position: _taglineSlide,
        child: FadeTransition(opacity: _taglineOpacity, child: child),
      ),
      child: Text(
        'Karyeranı qur. İşini tap.',
        style: TextStyle(
          fontSize: 14,
          color: Colors.white.withOpacity(0.38),
          letterSpacing: 1.2,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // ── Status dot ────────────────────────────────────────────────────

  Widget _buildStatusDot() {
    return FadeTransition(
      opacity: _dotOpacity,
      child: _PulsingDot(),
    );
  }

  // ── Progress bar ─────────────────────────────────────────────────

  Widget _buildProgressBar(Size size) {
    return AnimatedBuilder(
      animation: _progressCtrl,
      builder: (_, __) {
        final v = CurvedAnimation(
          parent: _progressCtrl,
          curve: Curves.easeInOut,
        ).value;

        return SizedBox(
          height: 2,
          child: Stack(
            children: [
              // Track
              Container(color: Colors.white.withOpacity(0.04)),
              // Fill
              FractionallySizedBox(
                widthFactor: v,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_kAccent, _kAccent2],
                    ),
                  ),
                ),
              ),
              // Leading glow
              Positioned(
                left: v * size.width - 20,
                top: -6,
                child: Container(
                  width: 20,
                  height: 14,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: _kAccent2.withOpacity(0.9),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  PULSING DOT
// ─────────────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final v = _ctrl.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kAccent2.withOpacity(0.4 + v * 0.6),
                boxShadow: [
                  BoxShadow(
                    color: _kAccent2.withOpacity(v * 0.8),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Yüklənir...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.22 + v * 0.15),
                letterSpacing: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  FALLBACK LOGO (if asset missing)
// ─────────────────────────────────────────────────────────────────

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: const Center(
        child: Text(
          'İT',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }
}