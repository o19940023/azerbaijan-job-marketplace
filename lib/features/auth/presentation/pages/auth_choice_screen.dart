import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';

// Matching splash colors
const _kBg     = Color(0xFF07070F);
const _kAccent = Color(0xFF5B5FEF);
const _kAccent2 = Color(0xFF38BDF8);

class AuthChoiceScreen extends StatefulWidget {
  final String userType;
  const AuthChoiceScreen({super.key, required this.userType});

  @override
  State<AuthChoiceScreen> createState() => _AuthChoiceScreenState();
}

class _AuthChoiceScreenState extends State<AuthChoiceScreen>
    with TickerProviderStateMixin {

  late final AnimationController _entryCtrl;
  late final AnimationController _floatCtrl;

  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _btnFade;
  late final Animation<Offset> _btnSlide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
    ));

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    // Icon: 0..0.5
    _iconScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Title: 0.3..0.7
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOutCubic),
    ));

    // Buttons: 0.6..1.0
    _btnFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    _btnSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
    ));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  bool get _isEmployer => widget.userType == 'employer';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -100,
            left: -80,
            child: _buildGlowBlob(_kAccent, 320, 0.08),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: _buildGlowBlob(_kAccent2, 260, 0.06),
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white54,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),

                  // Icon
                  AnimatedBuilder(
                    animation: _entryCtrl,
                    builder: (_, __) => Transform.scale(
                      scale: _iconScale.value,
                      child: Opacity(
                        opacity: _iconFade.value,
                        child: _buildRoleIcon(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Title + subtitle
                  AnimatedBuilder(
                    animation: _entryCtrl,
                    builder: (_, child) => SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(opacity: _titleFade, child: child),
                    ),
                    child: _buildTitleBlock(),
                  ),

                  const Spacer(flex: 3),

                  // Buttons
                  AnimatedBuilder(
                    animation: _entryCtrl,
                    builder: (_, child) => SlideTransition(
                      position: _btnSlide,
                      child: FadeTransition(opacity: _btnFade, child: child),
                    ),
                    child: _buildButtons(context),
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Role icon ──────────────────────────────────────────────────

  Widget _buildRoleIcon() {
    return Center(
      child: AnimatedBuilder(
        animation: _floatCtrl,
        builder: (_, child) {
          final dy = math.sin(_floatCtrl.value * math.pi) * 6;
          return Transform.translate(
            offset: Offset(0, dy),
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kAccent.withOpacity(0.3),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
            // Ring
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    _kAccent.withOpacity(0),
                    _kAccent,
                    _kAccent2,
                    _kAccent.withOpacity(0),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBg,
                  ),
                ),
              ),
            ),
            // Icon
            Icon(
              _isEmployer
                  ? Icons.business_center_rounded
                  : Icons.person_search_rounded,
              size: 42,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  // ── Title block ────────────────────────────────────────────────

  Widget _buildTitleBlock() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Colors.white, Color(0xFFCDD5F3)],
          ).createShader(b),
          child: Text(
            _isEmployer
                ? 'İşveren olaraq\ndavam et'
                : 'İş axtaran olaraq\ndavam et',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.8,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _isEmployer
              ? 'Ən yaxşı namizədləri tap,\nelanlarını asanlıqla idarə et.'
              : 'Minlərlə iş elanı arasından\nsənə uyğun olanı tap.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withOpacity(0.4),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ── Buttons ────────────────────────────────────────────────────

  Widget _buildButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary — Login
        _GlassButton(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.pushNamed(
              context,
              AppRouter.login,
              arguments: widget.userType,
            );
          },
          gradient: const LinearGradient(
            colors: [_kAccent, Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          glowColor: _kAccent,
          child: const Text(
            'Daxil ol',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Secondary — Register
        _GlassButton(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(
              context,
              AppRouter.register,
              arguments: widget.userType,
            );
          },
          borderColor: Colors.white.withOpacity(0.12),
          child: Text(
            'Hesab yarat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Terms
        Text(
          'Davam etməklə İstifadəçi Şərtlərini qəbul etmiş olursunuz.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.2),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGlowBlob(Color color, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(opacity),
            blurRadius: size / 2,
            spreadRadius: size / 4,
          ),
        ],
      ),
    );
  }
}

// ── Shared button widget ──────────────────────────────────────────

class _GlassButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final Gradient? gradient;
  final Color? glowColor;
  final Color? borderColor;

  const _GlassButton({
    required this.onTap,
    required this.child,
    this.gradient,
    this.glowColor,
    this.borderColor,
  });

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0.95,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.reverse(),
      onTapUp: (_) {
        _pressCtrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.forward(),
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (_, child) => Transform.scale(
          scale: _pressCtrl.value,
          child: child,
        ),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            color: widget.gradient == null
                ? Colors.white.withOpacity(0.05)
                : null,
            borderRadius: BorderRadius.circular(18),
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!)
                : null,
            boxShadow: widget.glowColor != null
                ? [
                    BoxShadow(
                      color: widget.glowColor!.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}