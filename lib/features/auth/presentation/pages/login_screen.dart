import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';
import '../../data/repositories/firebase_auth_repository.dart';

const _kBg      = Color(0xFF07070F);
const _kAccent  = Color(0xFF5B5FEF);
const _kAccent2 = Color(0xFF38BDF8);
const _kSurface = Color(0xFF12121F);
const _kBorder  = Color(0xFF2A2A4A);

class LoginScreen extends StatefulWidget {
  final String userType;
  const LoginScreen({super.key, required this.userType});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authRepo     = FirebaseAuthRepository();

  bool _isLoading = false;
  bool _showPass  = false;

  late final AnimationController _entryCtrl;
  late final List<Animation<double>> _itemFades;
  late final List<Animation<Offset>> _itemSlides;

  static const _itemCount = 5;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _itemFades  = [];
    _itemSlides = [];

    for (int i = 0; i < _itemCount; i++) {
      final start = i * 0.12;
      final end   = (start + 0.4).clamp(0.0, 1.0);
      _itemFades.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
      _itemSlides.add(
        Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: Interval(
              start,
              (end + 0.1).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Widget _animated(int i, Widget child) => SlideTransition(
        position: _itemSlides[i],
        child: FadeTransition(opacity: _itemFades[i], child: child),
      );

  // ── Actions ────────────────────────────────────────────────────

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      _showSnack('Zəhmət olmasa bütün xanaları doldurun');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authRepo.login(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        expectedUserType: widget.userType,
      );
      await FirebaseAnalytics.instance.logLogin(loginMethod: 'email');
      await FirebaseAnalytics.instance.setUserProperty(
        name: 'user_type',
        value: widget.userType,
      );
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          widget.userType == 'employer'
              ? AppRouter.employerHome
              : AppRouter.jobSeekerHome,
          (_) => false,
        );
      }
    } catch (e) {
      _showSnack('Xəta: ${_clean(e)}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _isLoading = true);
    try {
      await _authRepo.signInWithGoogle(widget.userType);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          widget.userType == 'employer'
              ? AppRouter.employerHome
              : AppRouter.jobSeekerHome,
          (_) => false,
        );
      }
    } catch (e) {
      _showSnack('Xəta: ${_clean(e)}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _appleLogin() async {
    setState(() => _isLoading = true);
    try {
      await _authRepo.signInWithApple(widget.userType);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          widget.userType == 'employer'
              ? AppRouter.employerHome
              : AppRouter.jobSeekerHome,
          (_) => false,
        );
      }
    } catch (e) {
      _showSnack('Xəta: ${_clean(e)}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF1E1E2E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _clean(Object e) => e
      .toString()
      .replaceAll('Exception: ', '')
      .replaceAll(RegExp(r'\[.*?\]\s*'), '');

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Ambient blobs
          Positioned(top: -120, right: -80, child: _blob(_kAccent, 300, 0.07)),
          Positioned(bottom: -80, left: -60, child: _blob(_kAccent2, 250, 0.05)),

          SafeArea(
            child: Column(
              children: [
                // Back button row
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white54, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),

                        // 0 · Logo
                        AnimatedBuilder(
                          animation: _entryCtrl,
                          builder: (_, child) => _animated(0, child!),
                          child: Center(
                            child: Hero(
                              tag: 'app_logo',
                              child: _logoBox(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 1 · Title
                        AnimatedBuilder(
                          animation: _entryCtrl,
                          builder: (_, child) => _animated(1, child!),
                          child: _titleBlock(
                            title: 'Xoş gəldiniz',
                            subtitle: 'Hesabınıza daxil olun',
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 2 · Email
                        AnimatedBuilder(
                          animation: _entryCtrl,
                          builder: (_, child) => _animated(2, child!),
                          child: _GlassInput(
                            controller: _emailCtrl,
                            label: 'E-poçt',
                            hint: 'nümunə@email.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 3 · Password
                        AnimatedBuilder(
                          animation: _entryCtrl,
                          builder: (_, child) => _animated(3, child!),
                          child: _GlassInput(
                            controller: _passwordCtrl,
                            label: 'Şifrə',
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            obscureText: !_showPass,
                            suffix: IconButton(
                              icon: Icon(
                                _showPass
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                                color: Colors.white38,
                              ),
                              onPressed: () =>
                                  setState(() => _showPass = !_showPass),
                            ),
                          ),
                        ),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(
                                context, AppRouter.forgotPassword),
                            child: Text(
                              'Şifrəmi unutdum?',
                              style: TextStyle(
                                color: _kAccent2,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // 4 · Buttons
                        AnimatedBuilder(
                          animation: _entryCtrl,
                          builder: (_, child) => _animated(4, child!),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _PrimaryButton(
                                onTap: _isLoading ? null : _login,
                                isLoading: _isLoading,
                                label: 'Daxil ol',
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.pushReplacementNamed(
                                    context,
                                    AppRouter.register,
                                    arguments: widget.userType,
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'Hesabınız yoxdur? ',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.35),
                                        fontSize: 13,
                                      ),
                                      children: const [
                                        TextSpan(
                                          text: 'Qeydiyyat',
                                          style: TextStyle(
                                            color: _kAccent2,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              _divider(),
                              const SizedBox(height: 20),
                              _SocialButton(
                                onTap: _isLoading ? null : _googleLogin,
                                icon: Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png',
                                  height: 20,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.g_mobiledata,
                                      color: Colors.white70,
                                      size: 22),
                                ),
                                label: 'Google ilə daxil ol',
                              ),
                              const SizedBox(height: 10),
                              _SocialButton(
                                onTap: _isLoading ? null : _appleLogin,
                                icon: const Icon(Icons.apple,
                                    color: Colors.white, size: 22),
                                label: 'Apple ilə daxil ol',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  Widget _logoBox() => Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: _kAccent.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Image.asset('assets/icons/Logo.png', fit: BoxFit.contain),
          ),
        ),
      );

  Widget _titleBlock({required String title, required String subtitle}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Colors.white, Color(0xFFCDD5F3)],
            ).createShader(b),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.35),
            ),
          ),
        ],
      );

  Widget _divider() => Row(
        children: [
          Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'və ya',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.25), fontSize: 12),
            ),
          ),
          Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
        ],
      );

  Widget _blob(Color c, double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: c.withOpacity(opacity),
              blurRadius: size / 2,
              spreadRadius: size / 4,
            )
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────
//  SHARED COMPONENTS  (also used by register_screen.dart)
// ─────────────────────────────────────────────────────────────────

/// Animated glass text field with focus border
class _GlassInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  const _GlassInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  @override
  State<_GlassInput> createState() => _GlassInputState();
}

class _GlassInputState extends State<_GlassInput> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _focused
            ? Colors.white.withOpacity(0.07)
            : const Color(0xFF12121F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focused
              ? _kAccent.withOpacity(0.6)
              : Colors.white.withOpacity(0.08),
          width: _focused ? 1.5 : 1,
        ),
      ),
      child: Focus(
        onFocusChange: (v) => setState(() => _focused = v),
        child: TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              color: _focused ? _kAccent2 : Colors.white38,
              fontSize: 13,
            ),
            hintText: widget.hint,
            hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.18), fontSize: 14),
            prefixIcon: Icon(widget.icon,
                size: 19,
                color: _focused ? _kAccent2 : Colors.white30),
            suffixIcon: widget.suffix,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }
}

/// Gradient primary button with press scale
class _PrimaryButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final String label;

  const _PrimaryButton({
    required this.onTap,
    required this.isLoading,
    required this.label,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    lowerBound: 0.96,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _press.reverse() : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _press.forward();
              widget.onTap!();
            }
          : null,
      onTapCancel: () => _press.forward(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) =>
            Transform.scale(scale: _press.value, child: child),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kAccent, Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _kAccent.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Social login button (Google / Apple)
class _SocialButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget icon;
  final String label;

  const _SocialButton({
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.09)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}