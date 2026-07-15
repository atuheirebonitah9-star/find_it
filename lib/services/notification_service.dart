import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'notification_event_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _token;
  bool _isInitialized = false;

  // Android notification channel constants
  static const String channelId = 'find_it_channel';
  static const String channelName = 'Find It Notifications';
  static const String channelDescription = 'Notifications for matches and messages';

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _requestPermissions();
      if (!kIsWeb) {
        await _initializeLocalNotifications();
        await _createAndroidNotificationChannel();
      }
      await _getFCMToken();
      _setupMessageHandlers();
      _isInitialized = true;
      debugPrint('✅ Notification service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize notification service: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      // Web permissions handled by browser
      return;
    }
    if (Platform.isIOS || Platform.isAndroid) {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    }
  }

  Future<void> _createAndroidNotificationChannel() async {
    if (!Platform.isAndroid) return;
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _initializeLocalNotifications() async {
    if (kIsWeb) return;
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  Future<void> _getFCMToken() async {
    try {
      _token = await _fcm.getToken();
      debugPrint('🔑 FCM Token: $_token');
      _saveTokenToFirestore();
    } catch (e) {
      debugPrint('❌ Failed to get FCM token: $e');
    }
  }

  Future<void> _saveTokenToFirestore() async {
    final user = _auth.currentUser;
    if (user == null || _token == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': _token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'deviceType': kIsWeb ? 'web' : Platform.operatingSystem,
      }, SetOptions(merge: true));
      debugPrint('💾 FCM token saved to Firestore');
    } catch (e) {
      debugPrint('❌ Failed to save FCM token: $e');
    }
  }

  Future<void> refreshToken() async {
    await _getFCMToken();
  }

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM token refreshed');
      _token = newToken;
      _saveTokenToFirestore();
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 Foreground message received: ${message.notification?.title}');
    if (!kIsWeb) {
      _showLocalNotification(message);
    }

    NotificationEventService().emit(NotificationEvent(
      type: NotificationEventType.foregroundMessage,
      data: {
        'title': message.notification?.title,
        'body': message.notification?.body,
        'messageId': message.messageId,
        'data': message.data,
        'isBackground': false,
      },
    ));
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('📨 Background message opened: ${message.data}');
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
    _navigateToRelevantScreen(message.data);
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    NotificationEventService().emit(NotificationEvent(
      type: NotificationEventType.notificationTapped,
      data: {
        'payload': response.payload,
        'notificationId': response.id,
        'actionId': response.actionId,
      },
    ));
    if (response.payload != null) {
      _navigateToRelevantScreen({'payload': response.payload});
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            enableLights: true,
          );
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      final title = message.notification?.title ?? 'Find It App';
      final body = message.notification?.body ?? 'You have a new notification';
      final payload = message.data['type'] ?? 'general';
      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Failed to show local notification: $e');
    }
  }

  void _navigateToRelevantScreen(Map<String, dynamic> data) {
    final type = data['type'] ?? 'general';
    switch (type) {
      case 'match':
        debugPrint('🔀 Navigate to match: ${data['matchId']}');
        break;
      case 'message':
        debugPrint('🔀 Navigate to chat: ${data['chatId']}');
        break;
      case 'confirmation':
        debugPrint('🔀 Navigate to confirmation: ${data['matchId']}');
        break;
      default:
        debugPrint('🔀 Navigate to home');
        break;
    }
  }

  Future<String?> getUserToken(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return doc.data()?['fcmToken'] as String?;
    } catch (e) {
      debugPrint('❌ Failed to get user token: $e');
      return null;
    }
  }

  Future<String> getUserName(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return 'User';
      return doc.data()?['name'] ?? 'User';
    } catch (e) {
      return 'User';
    }
  }

  Future<String> getItemName(String itemId) async {
    try {
      final doc = await _firestore.collection('items').doc(itemId).get();
      if (!doc.exists) return 'Item';
      return doc.data()?['title'] ?? 'Item';
    } catch (e) {
      return 'Item';
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    if (!kIsWeb) {
      await _fcm.subscribeToTopic(topic);
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (!kIsWeb) {
      await _fcm.unsubscribeFromTopic(topic);
    }
  }

  void dispose() {}
}
