import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';

const _kBg      = Color(0xFF07070F);
const _kAccent  = Color(0xFF5B5FEF);
const _kAccent2 = Color(0xFF38BDF8);
const _kOrange  = Color(0xFFFF6D00);

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _auroraCtrl;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _cardsFade;
  late final Animation<Offset> _cardsSlide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _auroraCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut)));
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)));
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl,
          curve: const Interval(0.3, 0.65, curve: Curves.easeOut)));
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryCtrl,
          curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic)));
    _cardsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl,
          curve: const Interval(0.55, 1.0, curve: Curves.easeOut)));
    _cardsSlide = Tween<Offset>(
      begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryCtrl,
          curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic)));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    _auroraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Aurora blobs
          AnimatedBuilder(
            animation: _auroraCtrl,
            builder: (_, __) {
              final s = math.sin(_auroraCtrl.value * math.pi * 2);
              return Stack(children: [
                Positioned(
                  top: -120 + s * 20, left: -80,
                  child: _blob(_kAccent, 340, 0.07)),
                Positioned(
                  bottom: -80 + s * 15, right: -60,
                  child: _blob(_kAccent2, 280, 0.05)),
                Positioned(
                  top: 200 + s * 10, right: -40,
                  child: _blob(_kOrange, 200, 0.04)),
              ]);
            },
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Floating logo
                  AnimatedBuilder(
                    animation: _entryCtrl,
                    builder: (_, child) => Transform.scale(
                      scale: _logoScale.value,
                      child: Opacity(opacity: _logoFade.value, child: child),
                    ),
                    child: AnimatedBuilder(
                      animation: _floatCtrl,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, math.sin(_floatCtrl.value * math.pi) * 7),
                        child: child,
                      ),
                      child: _buildLogoMark(),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Title
                  AnimatedBuilder(
                    animation: _entryCtrl,
                    builder: (_, child) => SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(opacity: _titleFade, child: child),
                    ),
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFCDD5F3)],
                          ).createShader(b),
                          child: const Text(
                            'İşTap',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nə axtarırsınız?',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.4),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Role cards
                  AnimatedBuilder(
                    animation: _entryCtrl,
                    builder: (_, child) => SlideTransition(
                      position: _cardsSlide,
                      child: FadeTransition(opacity: _cardsFade, child: child),
                    ),
                    child: Column(
                      children: [
                        _RoleCard(
                          icon: Icons.search_rounded,
                          title: 'İş Axtarıram',
                          subtitle: 'Yaxınlıqdakı iş imkanlarını tap',
                          gradient: const LinearGradient(
                            colors: [_kAccent, Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          glowColor: _kAccent,
                          onTap: () => Navigator.pushReplacementNamed(
                            context, AppRouter.jobSeekerHome),
                        ),
                        const SizedBox(height: 16),
                        _RoleCard(
                          icon: Icons.people_rounded,
                          title: 'İşçi Axtarıram',
                          subtitle: 'Elan ver, uyğun namizədləri tap',
                          gradient: LinearGradient(
                            colors: [_kOrange, _kOrange.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          glowColor: _kOrange,
                          onTap: () => Navigator.pushNamed(
                            context, AppRouter.authChoice,
                            arguments: 'employer'),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Footer
                  FadeTransition(
                    opacity: _cardsFade,
                    child: Text(
                      'Davam etməklə İstifadə Şərtlərini\nvə Gizlilik Siyasətini qəbul edirsiniz',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.2),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoMark() {
    return Hero(
      tag: 'app_logo',
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _kAccent.withOpacity(0.35),
                  blurRadius: 60, spreadRadius: 12),
              ],
            ),
          ),
          // Spinning ring
          AnimatedBuilder(
            animation: _auroraCtrl,
            builder: (_, child) => Transform.rotate(
              angle: _auroraCtrl.value * math.pi * 2,
              child: child,
            ),
            child: Container(
              width: 100, height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Color(0x005B5FEF), _kAccent, _kAccent2,
                    Color(0x005B5FEF),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: _kBg),
                ),
              ),
            ),
          ),
          // Logo asset
          ClipOval(
            child: Container(
              width: 84, height: 84,
              color: const Color(0xFF12121F),
              padding: const EdgeInsets.all(16),
              child: Image.asset('assets/icons/Logo.png', fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(Color c, double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(
        color: c.withOpacity(opacity),
        blurRadius: size / 2, spreadRadius: size / 4,
      )],
    ),
  );
}

// ── Role Card ─────────────────────────────────────────────────────

class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final Color glowColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 120),
    lowerBound: 0.96, upperBound: 1.0, value: 1.0,
  );

  @override
  void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { HapticFeedback.lightImpact(); _press.reverse(); },
      onTapUp: (_) { _press.forward(); widget.onTap(); },
      onTapCancel: () => _press.forward(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) => Transform.scale(scale: _press.value, child: child),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(0.35),
                blurRadius: 24, offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                      style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    Text(widget.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.75))),
                  ],
                ),
              ),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}