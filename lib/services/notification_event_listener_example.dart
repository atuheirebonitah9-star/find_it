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
      case NotificationEventType.matchFoundWeak:
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
      case NotificationEventType.itemReported:
        _handleItemReported(event);
        break;
      case NotificationEventType.matchConfirmed:
        _handleMatchConfirmed(event);
        break;
      case NotificationEventType.messageReceived:
        _handleMessageReceived(event);
        break;
      case NotificationEventType.itemMarkedFound:
        _handleItemMarkedFound(event);
        break;
      case NotificationEventType.itemClaimed:
        _handleItemClaimed(event);
        break;
      case NotificationEventType.reminder:
        _handleReminder(event);
        break;
      case NotificationEventType.verificationRequest:
        _handleVerificationRequest(event);
        break;
      case NotificationEventType.signUpSuccess:
        _handleSignUpSuccess(event);
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
            'Strong match found! ${event.data['itemName']} at ${event.data['location']}',
          ),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // Navigate to match details
              debugPrint('Navigate to match');
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
          content: Text('Possible match: ${event.data['itemName']} at ${event.data['location']}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleItemReported(NotificationEvent event) {
    debugPrint('[UI] New item reported: ${event.data}');
    
    if (mounted) {
      final isLost = event.data['isLost'] as bool;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'New ${isLost ? 'lost' : 'found'} item: ${event.data['itemName']} at ${event.data['location']}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleMatchConfirmed(NotificationEvent event) {
    debugPrint('[UI] Match confirmed: ${event.data}');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Match confirmed! Check your messages.'),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handleMessageReceived(NotificationEvent event) {
    debugPrint('[UI] Message received: ${event.data}');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New message from ${event.data['senderName'] ?? 'someone'}'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleItemMarkedFound(NotificationEvent event) {
    debugPrint('[UI] Item marked as found: ${event.data}');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Great! Your ${event.data['itemName']} has been marked as found!'),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handleItemClaimed(NotificationEvent event) {
    debugPrint('[UI] Item claimed: ${event.data}');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Someone claimed your ${event.data['itemName']}! Check your messages.'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _handleReminder(NotificationEvent event) {
    debugPrint('[UI] Reminder: ${event.data}');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder: Follow up on your lost item reports!'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleVerificationRequest(NotificationEvent event) {
    debugPrint('[UI] Verification request: ${event.data}');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please verify the match for ${event.data['itemName']}'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Verify',
            onPressed: () {
              debugPrint('Navigate to verification');
            },
          ),
        ),
      );
    }
  }

  void _handleSignUpSuccess(NotificationEvent event) {
    debugPrint('[UI] Sign up successful: ${event.data}');
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
      case NotificationEventType.matchFoundWeak:
        return Icons.help;
      case NotificationEventType.notificationTapped:
        return Icons.touch_app;
      case NotificationEventType.foregroundMessage:
        return Icons.message;
      case NotificationEventType.notificationClosed:
        return Icons.close;
      case NotificationEventType.itemReported:
        return Icons.add_alert;
      case NotificationEventType.matchConfirmed:
        return Icons.verified_user;
      case NotificationEventType.messageReceived:
        return Icons.message;
      case NotificationEventType.itemMarkedFound:
        return Icons.check;
      case NotificationEventType.itemClaimed:
        return Icons.person_add;
      case NotificationEventType.reminder:
        return Icons.access_alarm;
      case NotificationEventType.verificationRequest:
        return Icons.question_answer;
      case NotificationEventType.signUpSuccess:
        return Icons.person_add;
    }
  }

  Color _getEventColor(NotificationEventType type) {
    switch (type) {
      case NotificationEventType.matchFound:
        return Colors.green;
      case NotificationEventType.matchFoundWeak:
        return Colors.orange;
      case NotificationEventType.notificationTapped:
        return Colors.blue;
      case NotificationEventType.foregroundMessage:
        return Colors.purple;
      case NotificationEventType.notificationClosed:
        return Colors.grey;
      case NotificationEventType.itemReported:
        return Colors.blue;
      case NotificationEventType.matchConfirmed:
        return Colors.green;
      case NotificationEventType.messageReceived:
        return Colors.indigo;
      case NotificationEventType.itemMarkedFound:
        return Colors.green;
      case NotificationEventType.itemClaimed:
        return Colors.amber;
      case NotificationEventType.reminder:
        return Colors.orange;
      case NotificationEventType.verificationRequest:
        return Colors.purple;
      case NotificationEventType.signUpSuccess:
        return Colors.green;
    }
  }
}
