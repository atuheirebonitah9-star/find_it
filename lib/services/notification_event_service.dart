import 'package:flutter/foundation.dart';

/// Defines the types of notification events
enum NotificationEventType {
  matchFound,           // Strong match between lost and found item
  matchFound_weak,      // Weak match found
  notificationTapped,   // User tapped on notification
  notificationClosed,   // Notification was closed
  foregroundMessage,    // Foreground FCM message received
}

/// Represents a notification event
class NotificationEvent {
  final NotificationEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  NotificationEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'NotificationEvent(type: $type, timestamp: $timestamp, data: $data)';
}

/// Callback type for notification event listeners
typedef NotificationEventCallback = void Function(NotificationEvent event);

/// Service to manage notification events
class NotificationEventService extends ChangeNotifier {
  static final NotificationEventService _instance =
      NotificationEventService._internal();

  factory NotificationEventService() {
    return _instance;
  }

  NotificationEventService._internal();

  final List<NotificationEventCallback> _listeners = [];
  final List<NotificationEvent> _eventHistory = [];

  /// Subscribe to notification events
  void subscribe(NotificationEventCallback listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  /// Unsubscribe from notification events
  void unsubscribe(NotificationEventCallback listener) {
    _listeners.remove(listener);
  }

  /// Emit a notification event
  void emit(NotificationEvent event) {
    debugPrint('[NotificationEventService] Emitting event: $event');
    _eventHistory.add(event);

    // Keep only the last 100 events in history
    if (_eventHistory.length > 100) {
      _eventHistory.removeAt(0);
    }

    // Notify all listeners
    for (var listener in _listeners) {
      try {
        listener(event);
      } catch (e) {
        debugPrint('[NotificationEventService] Error in listener: $e');
      }
    }

    // Notify ChangeNotifier listeners
    notifyListeners();
  }

  /// Get event history
  List<NotificationEvent> getEventHistory() {
    return List.unmodifiable(_eventHistory);
  }

  /// Get event history by type
  List<NotificationEvent> getEventsByType(NotificationEventType type) {
    return _eventHistory.where((event) => event.type == type).toList();
  }

  /// Clear event history
  void clearHistory() {
    _eventHistory.clear();
  }

  /// Get listener count
  int getListenerCount() => _listeners.length;
}
