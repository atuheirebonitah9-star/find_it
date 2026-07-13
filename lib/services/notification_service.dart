import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

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

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _requestPermissions();
      await _initializeLocalNotifications();
      await _getFCMToken();
      _setupMessageHandlers();
      _isInitialized = true;
    } catch (e) {
      print('❌ Failed to initialize notification service: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    }
  }

  Future<void> _initializeLocalNotifications() async {
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
      _saveTokenToFirestore();
    } catch (e) {
      print('❌ Failed to get FCM token: $e');
    }
  }

  Future<void> _saveTokenToFirestore() async {
    final user = _auth.currentUser;
    if (user == null || _token == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': _token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'deviceType': Platform.operatingSystem,
      }, SetOptions(merge: true));
    } catch (e) {
      print('❌ Failed to save FCM token: $e');
    }
  }

  Future<void> refreshToken() async {
    await _getFCMToken();
  }

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    _fcm.onTokenRefresh.listen((newToken) {
      _token = newToken;
      _saveTokenToFirestore();
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(message);
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    _navigateToRelevantScreen(message.data);
  }

  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      _navigateToRelevantScreen({'payload': response.payload});
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'find_it_channel',
            'Find It Notifications',
            channelDescription: 'Notifications for matches and messages',
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
      print('❌ Failed to show local notification: $e');
    }
  }

  void _navigateToRelevantScreen(Map<String, dynamic> data) {
    final type = data['type'] ?? 'general';
    switch (type) {
      case 'match':
        print('🔀 Navigate to match: ${data['matchId']}');
        break;
      case 'message':
        print('🔀 Navigate to chat: ${data['chatId']}');
        break;
      case 'confirmation':
        print('🔀 Navigate to confirmation: ${data['matchId']}');
        break;
      default:
        print('🔀 Navigate to home');
        break;
    }
  }

  Future<String?> getUserToken(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return doc.data()?['fcmToken'] as String?;
    } catch (e) {
      print('❌ Failed to get user token: $e');
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
    await _fcm.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  void dispose() {}
}
