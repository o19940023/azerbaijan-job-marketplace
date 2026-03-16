import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/services/remote_config_service.dart';
import '../../../../core/widgets/update_dialog.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0, 0.5)),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _logoController.forward().then((_) {
      _textController.forward();
      Future.delayed(const Duration(milliseconds: 1500), () async {
        if (mounted) {
          final isUpdateRequired = await _checkVersion();
          if (!isUpdateRequired && mounted) {
            _checkAuthAndNavigate();
          }
        }
      });
    });
  }

  Future<bool> _checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final minVersion = RemoteConfigService().getMinAppVersion();
      final latestVersion = RemoteConfigService().getLatestAppVersion();

      // Məcburi yeniləmə (Force Update)
      if (_isVersionLower(currentVersion, minVersion)) {
        if (mounted) {
          await showUpdateDialog(context, isMandatory: true);
        }
        return true;
      }
      
      // Könüllü yeniləmə (Optional Update)
      if (_isVersionLower(currentVersion, latestVersion)) {
        if (mounted) {
          await showUpdateDialog(context, isMandatory: false);
        }
        // Könüllü olduğu üçün tətbiqə davam edə bilər (dialog-da "Sonra" var)
        return false; 
      }
    } catch (e) {
      debugPrint('Version check error: $e');
    }
    return false;
  }

  bool _isVersionLower(String current, String min) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final minParts = min.split('.').map(int.parse).toList();

      for (var i = 0; i < 3; i++) {
        final currentPart = i < currentParts.length ? currentParts[i] : 0;
        final minPart = i < minParts.length ? minParts[i] : 0;

        if (currentPart < minPart) return true;
        if (currentPart > minPart) return false;
      }
    } catch (e) {
      debugPrint('Version comparison error: $e');
    }
    return false;
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // İstifadəçi artıq giriş edib — Firestore-dan userType-ı öyrən
        try {
          // Timeout əlavə edirik ki, əgər Firestore cavab verməsə sonsuz gözləməsin
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 5));
          
          if (doc.exists && mounted) {
            final data = doc.data();
            final userType = data?['userType'] as String? ?? '';
            
            // FCM token-i arxa planda yenilə (await etməyə ehtiyac yoxdur)
            FirebaseMessaging.instance.getToken().then((token) {
              if (token != null) {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({'fcmToken': token})
                    .catchError((_) {});
              }
            }).catchError((_) {});

            if (userType == 'employer') {
              Navigator.pushReplacementNamed(context, AppRouter.employerHome);
            } else {
              Navigator.pushReplacementNamed(context, AppRouter.jobSeekerHome);
            }
            return;
          }
        } catch (e) {
          debugPrint('Firestore error or timeout: $e');
          // Xəta baş versə belə, istifadəçi giriş edibsə Home-a yönləndirməyə çalış
          // Default olaraq jobSeekerHome
          if (mounted) {
             Navigator.pushReplacementNamed(context, AppRouter.jobSeekerHome);
             return;
          }
        }
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
    }
    
    // Əgər heç bir şərt ödənməzsə (user null və ya xəta), onboarding-ə get
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRouter.roleSelection);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            ScaleTransition(
              scale: _logoScale,
              child: FadeTransition(
                opacity: _logoOpacity,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        blurRadius: 40,
                        spreadRadius: 5,
                        offset: const Offset(0, 15),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        'assets/icons/Logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Animated Text
            SlideTransition(
              position: _textSlide,
              child: FadeTransition(
                opacity: _textOpacity,
                child: Column(
                  children: [
                    const Text(
                      'İşTap',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Azərbaycanın İş Bazarı',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 2,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
