import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/navigation/app_router.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// Background message handler – must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Android automatically shows the notification from the 'notification' payload.
  // No extra code is needed here for displaying.
  debugPrint('Background message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register the background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request notification permission (especially needed for iOS)
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

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
  @override
  void initState() {
    super.initState();
    _setupForegroundNotifications();
  }

  void _setupForegroundNotifications() {
    // Listen for messages while the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        // Show a SnackBar or Dialog when a notification arrives in the foreground
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = navigatorKey.currentContext;
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${notification.title}: ${notification.body}'),
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Bax',
                  textColor: Colors.white,
                  onPressed: () => _handleNotificationClick(message),
                ),
              ),
            );
          }
        });
      }
    });

    // Handle notification taps when app was in background and user taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped (background): ${message.data}');
      _handleNotificationClick(message);
    });

    // Handle notification taps when app was terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('Notification tapped (terminated): ${message.data}');
        // Wait for the first frame so navigator is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNotificationClick(message);
        });
      }
    });
  }

  void _handleNotificationClick(RemoteMessage message) {
    if (navigatorKey.currentState == null) return;

    final data = message.data;
    final action = data['action'] ?? data['type'];

    if (action == 'chat' || data.containsKey('chatId')) {
      final chatId = data['chatId'];
      if (chatId != null) {
        navigatorKey.currentState!.pushNamed(
          AppRouter.chatDetail,
          arguments: {
            'chatId': chatId,
            'name': data['senderName'] ?? data['name'] ?? 'Söhbət',
            'otherUserId': data['senderId'] ?? data['otherUserId'] ?? '',
          },
        );
      }
    }
    // Future handling for job_detail or other screens can be added here
  }

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
