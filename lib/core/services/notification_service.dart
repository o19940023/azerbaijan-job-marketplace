import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../../firebase_options.dart';

final FlutterLocalNotificationsPlugin _backgroundLocalNotifications = FlutterLocalNotificationsPlugin();
bool _backgroundNotificationsInitialized = false;

Future<void> _initializeBackgroundNotifications() async {
  if (_backgroundNotificationsInitialized) return;
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  await _backgroundLocalNotifications.initialize(
    settings: InitializationSettings(android: androidSettings, iOS: iosSettings),
  );
  if (Platform.isAndroid) {
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );
    await _backgroundLocalNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }
  _backgroundNotificationsInitialized = true;
}

// Background handler must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    await _requestPermissions();

    // Initialize Local Notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    await _localNotifications.initialize(
      settings: InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        // Handle local notification tap
        if (details.payload != null) {
          debugPrint('Local Notification payload: ${details.payload}');
          try {
            final data = jsonDecode(details.payload!);
            _handleNotificationTap(data);
          } catch (e) {
            debugPrint('Error parsing payload: $e');
          }
        }
      },
    );

    // Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Create High Importance Channel for Android
    if (Platform.isAndroid) {
      final androidChannel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.', // description
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }

    // Foreground Message Listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        
        // Show local notification
        _showLocalNotification(message);
      }
    });

    // Background/Terminated Message Tap Listener
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleNotificationTap(message.data);
    });
    
    // Check initial message (Terminated state)
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App launched from terminated state via notification');
      // Delay to ensure navigator is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage.data);
      });
    }

    _isInitialized = true;
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    if (_navigatorKey?.currentState == null) {
      debugPrint('Navigator key is null or current state is null');
      return;
    }

    final action = data['action'] ?? data['type'];

    // Chat navigation
    if (action == 'chat' || data.containsKey('chatId')) {
      final chatId = data['chatId'];
      if (chatId != null) {
        _navigatorKey!.currentState!.pushNamed(
          '/chat_detail', // Using string route name to avoid circular dependency
          arguments: {
            'chatId': chatId,
            'name': data['senderName'] ?? data['name'] ?? 'Söhbət',
            'otherUserId': data['senderId'] ?? data['otherUserId'] ?? '',
          },
        );
      }
    }
    // Job detail navigation
    else if (action == 'job_detail' || data.containsKey('jobId')) {
       final jobId = data['jobId'];
       if (jobId != null) {
         // Implement job detail navigation if needed
         // _navigatorKey!.currentState!.pushNamed('/job_detail', arguments: jobId);
       }
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } else if (Platform.isAndroid) {
      final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
  
  // Topic subscription methods
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}
