import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'auth_gate.dart';
import 'providers/chat_provider.dart';
import 'services/notification_event_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background FCM message: ${message.messageId}');

  // Emit event for background message
  NotificationEventService().emit(NotificationEvent(
    type: NotificationEventType.foregroundMessage,
    data: {
      'title': message.notification?.title,
      'body': message.notification?.body,
      'messageId': message.messageId,
      'data': message.data,
      'isBackground': true,
    },
  ));
}

Future<void> _showForegroundNotification(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) return;

  const androidDetails = AndroidNotificationDetails(
    'default_channel',
    'Default Notifications',
    channelDescription: 'General notifications',
    importance: Importance.max,
    priority: Priority.high,
  );

  const platformDetails = NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(
    id: notification.hashCode,
    title: notification.title,
    body: notification.body,
    notificationDetails: platformDetails,
    payload: message.data['payload'] as String?,
  );

  // Emit event for foreground notification
  NotificationEventService().emit(NotificationEvent(
    type: NotificationEventType.foregroundMessage,
    data: {
      'title': notification.title,
      'body': notification.body,
      'messageId': message.messageId,
      'data': message.data,
      'isBackground': false,
    },
  ));
}

Future<void> _initNotifications() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  const initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initSettings,
    onDidReceiveNotificationResponse: (response) {
      debugPrint('Notification tapped: ${response.payload}');
      
      // Emit event for notification tap
      NotificationEventService().emit(NotificationEvent(
        type: NotificationEventType.notificationTapped,
        data: {
          'payload': response.payload,
          'notificationId': response.id,
          'actionId': response.actionId,
        },
      ));
    },
  );

  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    final token = await messaging.getToken();
    debugPrint('FCM token: $token');
  }

  FirebaseMessaging.onMessage.listen((message) {
    debugPrint('Foreground FCM message: ${message.notification?.title}');
    _showForegroundNotification(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    debugPrint('Notification opened: ${message.data}');
    
    // Emit event for notification opened
    NotificationEventService().emit(NotificationEvent(
      type: NotificationEventType.notificationTapped,
      data: {
        'title': message.notification?.title,
        'body': message.notification?.body,
        'messageId': message.messageId,
        'data': message.data,
        'source': 'onMessageOpenedApp',
      },
    ));
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    await _initNotifications();
  } catch (e) {
    debugPrint('Notifications setup failed (safe to ignore on web): $e');
  }

  runApp(const FindItApp());
}

class FindItApp extends StatelessWidget {
  const FindItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChatProvider(),
      child: MaterialApp(
        title: 'Find It',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}
