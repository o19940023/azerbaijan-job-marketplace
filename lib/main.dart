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
  // Ensure binding is initialized first
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create a minimal app to show while initializing (if needed)
  // But standard practice is to just initialize critical things and run app
  
  try {
    // 1. Load Environment Variables (Non-blocking failure)
    try {
      await dotenv.load(fileName: ".env");
      debugPrint('Environment variables loaded successfully');
    } catch (e) {
      debugPrint('Warning: Failed to load .env file: $e');
    }
    
    // 2. Initialize Firebase (Critical)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');

    // 3. Initialize Services (Non-blocking failures handled inside)
    
    // Remote Config
    try {
      await RemoteConfigService().initialize();
      debugPrint('Remote Config initialized');
    } catch (e) {
      debugPrint('Warning: Remote Config initialization failed: $e');
    }

    // Notifications
    try {
      await NotificationService().initialize();
      debugPrint('Notification Service initialized');
    } catch (e) {
      debugPrint('Warning: Notification Service initialization failed: $e');
    }

    // Analytics & Crashlytics
    try {
      await FirebaseAnalytics.instance.logAppOpen();
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      debugPrint('Analytics & Crashlytics initialized');
    } catch (e) {
      debugPrint('Warning: Analytics/Crashlytics initialization failed: $e');
    }

  } catch (e) {
    debugPrint('CRITICAL INITIALIZATION ERROR: $e');
    // Even if critical init fails, try to run the app so it doesn't hang on white screen
    // The app might be broken, but at least it shows something
  }

  // 4. Initialize SharedPreferences (Critical for Theme)
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('Critical: Failed to get SharedPreferences: $e');
    // Create dummy prefs if failed, or handle in ThemeCubit
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
    // Set navigator key for notification service
    try {
      NotificationService().setNavigatorKey(navigatorKey);
    } catch (e) {
      debugPrint('Warning: Failed to set navigator key: $e');
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
