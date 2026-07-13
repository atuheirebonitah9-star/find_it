import 'package:flutter/material.dart';
import '../services/notification_event_service.dart';

/// Example implementation of listening to notification events
/// 
/// This widget demonstrates how to listen to notification events
/// and respond accordingly. You can integrate this pattern into
/// your existing screens.
class NotificationEventListener extends StatefulWidget {
  final Widget child;

  const NotificationEventListener({
    required this.child,
    super.key,
  });

  @override
  State<NotificationEventListener> createState() =>
      _NotificationEventListenerState();
}

class _NotificationEventListenerState extends State<NotificationEventListener> {
  late NotificationEventService _eventService;
  final List<NotificationEvent> _recentEvents = [];

  @override
  void initState() {
    super.initState();
    _eventService = NotificationEventService();
    
    // Subscribe to all notification events
    _eventService.subscribe(_handleNotificationEvent);
  }

  void _handleNotificationEvent(NotificationEvent event) {
    debugPrint('[UI] Received event: ${event.type}');
    
    setState(() {
      _recentEvents.insert(0, event);
      // Keep only last 50 events
      if (_recentEvents.length > 50) {
        _recentEvents.removeLast();
      }
    });

    // Handle different event types
    switch (event.type) {
      case NotificationEventType.matchFound:
        _handleStrongMatch(event);
        break;
      case NotificationEventType.matchFound_weak:
        _handleWeakMatch(event);
        break;
      case NotificationEventType.notificationTapped:
        _handleNotificationTapped(event);
        break;
      case NotificationEventType.foregroundMessage:
        _handleForegroundMessage(event);
        break;
      case NotificationEventType.notificationClosed:
        _handleNotificationClosed(event);
        break;
    }
  }

  void _handleStrongMatch(NotificationEvent event) {
    debugPrint('[UI] Strong match found: ${event.data}');
    
    // Show a snackbar or dialog
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Strong match found! ${event.data['description']}',
          ),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // Navigate to match details
              debugPrint('Navigate to match: ${event.data['lostReportId']}');
            },
          ),
        ),
      );
    }
  }

  void _handleWeakMatch(NotificationEvent event) {
    debugPrint('[UI] Weak match found: ${event.data}');
    
    // You can handle weak matches differently
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Possible match: ${event.data['description']}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleNotificationTapped(NotificationEvent event) {
    debugPrint('[UI] Notification tapped: ${event.data}');
    // Navigate to relevant screen based on payload
    // Example: Navigator.pushNamed(context, '/matches');
  }

  void _handleForegroundMessage(NotificationEvent event) {
    debugPrint('[UI] Foreground message: ${event.data['title']}');
    // Handle foreground message display
  }

  void _handleNotificationClosed(NotificationEvent event) {
    debugPrint('[UI] Notification closed: ${event.data}');
  }

  @override
  void dispose() {
    _eventService.unsubscribe(_handleNotificationEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Example widget showing how to display recent notification events
/// You can use this for debugging or showing a notification feed
class NotificationEventDebugPanel extends StatefulWidget {
  const NotificationEventDebugPanel({super.key});

  @override
  State<NotificationEventDebugPanel> createState() =>
      _NotificationEventDebugPanelState();
}

class _NotificationEventDebugPanelState
    extends State<NotificationEventDebugPanel> {
  late NotificationEventService _eventService;

  @override
  void initState() {
    super.initState();
    _eventService = NotificationEventService();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _eventService,
      builder: (context, _) {
        final history = _eventService.getEventHistory();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Notification Events (${history.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final event = history[history.length - 1 - index];
                  return ListTile(
                    title: Text(event.type.toString().split('.').last),
                    subtitle: Text(
                      '${event.timestamp.hour}:${event.timestamp.minute}:${event.timestamp.second}',
                    ),
                    trailing: Icon(
                      _getEventIcon(event.type),
                      color: _getEventColor(event.type),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getEventIcon(NotificationEventType type) {
    switch (type) {
      case NotificationEventType.matchFound:
        return Icons.check_circle;
      case NotificationEventType.matchFound_weak:
        return Icons.help;
      case NotificationEventType.notificationTapped:
        return Icons.touch_app;
      case NotificationEventType.foregroundMessage:
        return Icons.message;
      case NotificationEventType.notificationClosed:
        return Icons.close;
    }
  }

  Color _getEventColor(NotificationEventType type) {
    switch (type) {
      case NotificationEventType.matchFound:
        return Colors.green;
      case NotificationEventType.matchFound_weak:
        return Colors.orange;
      case NotificationEventType.notificationTapped:
        return Colors.blue;
      case NotificationEventType.foregroundMessage:
        return Colors.purple;
      case NotificationEventType.notificationClosed:
        return Colors.grey;
    }
  }
}
