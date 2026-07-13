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

  // ======================== INITIALIZATION ========================

  /// Initialize notification services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Request permissions
      await _requestPermissions();

      // 2. Initialize local notifications
      await _initializeLocalNotifications();

      // 3. Get FCM token
      await _getFCMToken();

      // 4. Set up message handlers
      _setupMessageHandlers();

      _isInitialized = true;
      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize notification service: $e');
    }
  }

  // ======================== PERMISSIONS ========================

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

  // ======================== LOCAL NOTIFICATIONS ========================

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
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  // ======================== FCM TOKEN ========================

  Future<void> _getFCMToken() async {
    try {
      _token = await _fcm.getToken();
      print('📱 FCM Token: $_token');
      
      // Save token to Firestore if user is logged in
      _saveTokenToFirestore();
    } catch (e) {
      print('❌ Failed to get FCM token: $e');
    }
  }

  /// Save FCM token to user's document in Firestore
  Future<void> _saveTokenToFirestore() async {
    final user = _auth.currentUser;
    if (user == null || _token == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': _token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'deviceType': Platform.operatingSystem,
      }, SetOptions(merge: true));
      
      print('✅ FCM token saved to Firestore');
    } catch (e) {
      print('❌ Failed to save FCM token: $e');
    }
  }

  /// Refresh FCM token (call when user logs in)
  Future<void> refreshToken() async {
    await _getFCMToken();
  }

  // ======================== MESSAGE HANDLERS ========================

  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle token refresh
    FirebaseMessaging.onTokenRefresh.listen((newToken) {
      _token = newToken;
      _saveTokenToFirestore();
    });
  }

  // ======================== MESSAGE HANDLING ========================

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('📨 Foreground message received: ${message.data}');
    _showLocalNotification(message);
  }

  /// Handle background messages (when app is opened from notification)
  void _handleBackgroundMessage(RemoteMessage message) {
    print('📨 Background message opened: ${message.data}');
    _navigateToRelevantScreen(message.data);
  }

  /// Handle notification tap when app is in foreground
  void _onNotificationTap(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    if (response.payload != null) {
      _navigateToRelevantScreen({'payload': response.payload});
    }
  }

  /// Show local notification
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
            sound: 'default_sound',
          );

      const DarwinNotificationDetails iosDetails = 
          DarwinNotificationDetails(
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
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      print('❌ Failed to show local notification: $e');
    }
  }

  // ======================== NAVIGATION ========================

  void _navigateToRelevantScreen(Map<String, dynamic> data) {
    // This will be handled by your app's navigation system
    // We'll use a global navigator key pattern
    final type = data['type'] ?? 'general';
    
    switch (type) {
      case 'match':
        // Navigate to match details
        print('🔀 Navigate to match: ${data['matchId']}');
        break;
      case 'message':
        // Navigate to chat
        print('🔀 Navigate to chat: ${data['chatId']}');
        break;
      case 'confirmation':
        // Navigate to match confirmation
        print('🔀 Navigate to confirmation: ${data['matchId']}');
        break;
      default:
        // Navigate to home
        print('🔀 Navigate to home');
        break;
    }
  }

  // ======================== SEND NOTIFICATIONS ========================

  /// Send match notification to user
  Future<void> sendMatchNotification({
    required String userId,
    required String matchId,
    required String itemName,
    required double matchScore,
  }) async {
    try {
      // Get user's FCM token
      final token = await _getUserToken(userId);
      if (token == null) {
        print('⚠️ No FCM token found for user: $userId');
        return;
      }

      // Send notification using Firebase Cloud Messaging API
      await _fcm.send(
        Message(
          token: token,
          notification: Notification(
            title: '🎯 Strong Match Found!',
            body: 'Your item "$itemName" has a ${(matchScore * 100).toInt()}% match!',
          ),
          data: {
            'type': 'match',
            'matchId': matchId,
            'itemName': itemName,
            'matchScore': matchScore.toString(),
          },
        ),
      );
      
      print('✅ Match notification sent to $userId');
    } catch (e) {
      print('❌ Failed to send match notification: $e');
    }
  }

  /// Send chat message notification
  Future<void> sendChatNotification({
    required String userId,
    required String chatId,
    required String senderName,
    required String message,
    required String itemName,
  }) async {
    try {
      final token = await _getUserToken(userId);
      if (token == null) {
        print('⚠️ No FCM token found for user: $userId');
        return;
      }

      await _fcm.send(
        Message(
          token: token,
          notification: Notification(
            title: '💬 New Message from $senderName',
            body: '$senderName: $message',
          ),
          data: {
            'type': 'message',
            'chatId': chatId,
            'senderName': senderName,
            'itemName': itemName,
          },
        ),
      );
      
      print('✅ Chat notification sent to $userId');
    } catch (e) {
      print('❌ Failed to send chat notification: $e');
    }
  }

  /// Send match confirmation notification
  Future<void> sendMatchConfirmationNotification({
    required String userId,
    required String matchId,
    required String itemName,
    required String otherPartyName,
  }) async {
    try {
      final token = await _getUserToken(userId);
      if (token == null) {
        print('⚠️ No FCM token found for user: $userId');
        return;
      }

      await _fcm.send(
        Message(
          token: token,
          notification: Notification(
            title: '✅ Match Confirmed!',
            body: '$otherPartyName confirmed the match for "$itemName"! Chat is now active.',
          ),
          data: {
            'type': 'confirmation',
            'matchId': matchId,
            'itemName': itemName,
          },
        ),
      );
      
      print('✅ Match confirmation notification sent to $userId');
    } catch (e) {
      print('❌ Failed to send confirmation notification: $e');
    }
  }

  /// Send item returned notification
  Future<void> sendItemReturnedNotification({
    required String userId,
    required String matchId,
    required String itemName,
    required String otherPartyName,
  }) async {
    try {
      final token = await _getUserToken(userId);
      if (token == null) {
        print('⚠️ No FCM token found for user: $userId');
        return;
      }

      await _fcm.send(
        Message(
          token: token,
          notification: Notification(
            title: '🎉 Item Returned Successfully!',
            body: '$otherPartyName marked "$itemName" as returned. Thank you for using Find It!',
          ),
          data: {
            'type': 'completed',
            'matchId': matchId,
            'itemName': itemName,
          },
        ),
      );
      
      print('✅ Item returned notification sent to $userId');
    } catch (e) {
      print('❌ Failed to send item returned notification: $e');
    }
  }

  // ======================== HELPER METHODS ========================

  /// Get user's FCM token from Firestore
  Future<String?> _getUserToken(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      
      return doc.data()?['fcmToken'] as String?;
    } catch (e) {
      print('❌ Failed to get user token: $e');
      return null;
    }
  }

  /// Get user's name from Firestore
  Future<String> getUserName(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return 'User';
      
      return doc.data()?['name'] ?? 'User';
    } catch (e) {
      return 'User';
    }
  }

  /// Get item name from Firestore
  Future<String> getItemName(String itemId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('items').doc(itemId).get();
      if (!doc.exists) return 'Item';
      
      return doc.data()?['title'] ?? 'Item';
    } catch (e) {
      return 'Item';
    }
  }

  // ======================== BADGE COUNTER ========================

  /// Update app badge count (iOS)
  Future<void> updateBadgeCount(int count) async {
    if (Platform.isIOS) {
      await _fcm.setApplicationIconBadgeNumber(count);
    }
  }

  /// Clear badge count
  Future<void> clearBadgeCount() async {
    if (Platform.isIOS) {
      await _fcm.setApplicationIconBadgeNumber(0);
    }
  }

  // ======================== SUBSCRIPTIONS ========================

  /// Subscribe to a topic (for group notifications)
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    print('📌 Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    print('📌 Unsubscribed from topic: $topic');
  }

  // ======================== CLEANUP ========================

  /// Dispose notification service
  void dispose() {
    // Clean up resources if needed
  }
}