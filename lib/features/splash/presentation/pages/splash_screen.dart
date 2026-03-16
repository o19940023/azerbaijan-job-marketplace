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
      // Wait a bit before checking navigation logic
      Future.delayed(const Duration(milliseconds: 1500), () async {
        if (mounted) {
          try {
            final isUpdateRequired = await _checkVersion();
            if (!isUpdateRequired && mounted) {
              await _checkAuthAndNavigate();
            }
          } catch (e) {
             debugPrint('Critical error in splash navigation: $e');
             // Fallback to role selection if everything fails
             if (mounted) {
               Navigator.pushReplacementNamed(context, AppRouter.roleSelection);
             }
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
            try {
              FirebaseMessaging.instance.getToken().then((token) {
                if (token != null) {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({'fcmToken': token})
                      .catchError((_) {});
                }
              }).catchError((_) {});
            } catch (_) {}

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
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _logoScale,
              child: FadeTransition(
                opacity: _logoOpacity,
                child: Image.asset(
                  'assets/icons/Logo.png',
                  width: 150,
                  height: 150,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SlideTransition(
              position: _textSlide,
              child: FadeTransition(
                opacity: _textOpacity,
                child: const Text(
                  'İşTap',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
