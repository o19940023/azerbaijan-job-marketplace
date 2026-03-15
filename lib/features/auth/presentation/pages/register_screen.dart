import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';
import '../../data/repositories/firebase_auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  final String userType;
  const RegisterScreen({super.key, required this.userType});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authRepo = FirebaseAuthRepository();
  bool _isLoading = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty ||
        _confirmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zəhmət olmasa bütün xanaları doldurun')),
      );
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifrələr uyğun gəlmir')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authRepo.register(
        email: _emailController.text,
        password: _passwordController.text,
        userType: widget.userType,
      );
      
      if (mounted) {
        if (widget.userType == 'employer') {
          Navigator.pushNamedAndRemoveUntil(context, AppRouter.employerSetup, (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, AppRouter.jobSeekerHome, (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xəta: ${e.toString().replaceAll('Exception: ', '').replaceAll(RegExp(r'\[.*?\]\s*'), '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Hesab yarat'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Logo
                  Hero(
                    tag: 'app_logo',
                    child: Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Image.asset(
                              'assets/icons/Logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _AnimatedTextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    labelText: 'E-poçt',
                    hintText: 'nümunə@email.com',
                    prefixIcon: Icons.email_outlined,
                    delay: 600,
                  ),
                  const SizedBox(height: 16),
                  _AnimatedTextField(
                    controller: _passwordController,
                    obscureText: true,
                    labelText: 'Şifrə',
                    hintText: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    delay: 700,
                  ),
                  const SizedBox(height: 16),
                  _AnimatedTextField(
                    controller: _confirmController,
                    obscureText: true,
                    labelText: 'Şifrəni Təsdiqləyin',
                    hintText: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    delay: 800,
                  ),
                  const SizedBox(height: 32),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading 
                          ? const SizedBox(
                              width: 24, height: 24, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                            )
                          : const Text(
                              'Qeydiyyatdan keç',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context, 
                        AppRouter.login,
                        arguments: widget.userType,
                      );
                    },
                    child: Text(
                      'Artıq hesabınız var? Daxil olun',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: context.dividerColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'və ya',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: context.dividerColor)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SocialButton(
                    onPressed: _isLoading ? null : () async {
                      setState(() => _isLoading = true);
                      try {
                        await _authRepo.signInWithGoogle(widget.userType);
                        if (mounted) {
                          final route = widget.userType == 'employer'
                              ? AppRouter.employerHome
                              : AppRouter.jobSeekerHome;
                          Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Xəta: ${e.toString().replaceAll('Exception: ', '').replaceAll(RegExp(r'\[.*?\]\s*'), '')}')),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    icon: Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png',
                      height: 24,
                    ),
                    label: 'Google ilə daxil ol',
                    delay: 1000,
                  ),
                  const SizedBox(height: 12),
                  _SocialButton(
                    onPressed: _isLoading ? null : () async {
                      setState(() => _isLoading = true);
                      try {
                        await _authRepo.signInWithApple(widget.userType);
                        if (mounted) {
                          final route = widget.userType == 'employer'
                              ? AppRouter.employerHome
                              : AppRouter.jobSeekerHome;
                          Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Xəta: ${e.toString().replaceAll('Exception: ', '').replaceAll(RegExp(r'\[.*?\]\s*'), '')}')),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    icon: Icon(Icons.apple, color: context.textPrimaryColor, size: 28),
                    label: 'Apple ilə daxil ol',
                    delay: 1100,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedTextField extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final int delay;

  const _AnimatedTextField({
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: delay),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: Icon(prefixIcon),
          filled: true,
          fillColor: context.inputFillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final int delay;

  const _SocialButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: delay),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(
          label,
          style: TextStyle(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: context.dividerColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
