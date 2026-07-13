import 'package:intl/intl.dart';

String formatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.inDays > 7) {
    return DateFormat('MMM d').format(timestamp);
  } else if (difference.inDays > 1) {
    return '${difference.inDays}d ago';
  } else if (difference.inHours > 1) {
    return '${difference.inHours}h ago';
  } else if (difference.inMinutes > 1) {
    return '${difference.inMinutes}m ago';
  } else {
    return 'Just now';
  }
}