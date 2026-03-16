import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/navigation/app_router.dart';
import 'core/services/notification_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/remote_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env").timeout(const Duration(seconds: 3));
  } catch (e) {
    debugPrint('Warning: Failed to load .env file: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('Warning: Firebase initialization failed or timed out: $e');
  }

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('Critical: Failed to get SharedPreferences: $e');
  }

  runApp(
    BlocProvider(
      create: (context) => ThemeCubit(prefs),
      child: const AzerbaijanJobMarketplaceApp(),
    ),
  );
}

class AzerbaijanJobMarketplaceApp extends StatefulWidget {
  const AzerbaijanJobMarketplaceApp({super.key});

  @override
  State<AzerbaijanJobMarketplaceApp> createState() => _AzerbaijanJobMarketplaceAppState();
}

class _AzerbaijanJobMarketplaceAppState extends State<AzerbaijanJobMarketplaceApp> {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    try {
      NotificationService().setNavigatorKey(navigatorKey);
    } catch (e) {
      debugPrint('Warning: Failed to set navigator key: $e');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNonCriticalServices();
    });
  }

  Future<void> _initializeNonCriticalServices() async {
    try {
      await RemoteConfigService().initialize().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Warning: Remote Config initialization failed: $e');
    }
    try {
      await NotificationService().initialize().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Warning: Notification Service initialization failed: $e');
    }
    try {
      await FirebaseAnalytics.instance.logAppOpen();
    } catch (e) {
      debugPrint('Warning: Analytics/Crashlytics initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'İşTap - Azərbaycan İş Bazarı',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          initialRoute: AppRouter.splash,
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
}
