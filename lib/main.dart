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
    await dotenv.load(fileName: ".env");
    debugPrint('Environment variables loaded successfully');
  } catch (e) {
    debugPrint('Failed to load environment variables (expected in release if using remote config): $e');
  }
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');

    // Initialize Remote Config Service
    await RemoteConfigService().initialize();
    debugPrint('Remote Config initialized');

    // Initialize Notification Service
    await NotificationService().initialize();
    debugPrint('Notification Service initialized');

    // Initialize Firebase Analytics
    await FirebaseAnalytics.instance.logAppOpen();
    debugPrint('Firebase Analytics initialized and logged app open');

    // Initialize Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    debugPrint('Firebase Crashlytics initialized');
  } catch (e) {
    debugPrint('Critical initialization error: $e');
    // Continue running app even if services fail, to avoid white screen
  }

  final prefs = await SharedPreferences.getInstance();

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
    NotificationService().setNavigatorKey(navigatorKey);
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
