import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../matching_logic.dart';
import 'notification_event_service.dart';

class ReportService {
  final CollectionReference lostReports = FirebaseFirestore.instance.collection(
    'lost_reports',
  );

  final CollectionReference foundReports = FirebaseFirestore.instance
      .collection('found_reports');

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationEventService _eventService = NotificationEventService();

  Future<void> submitLostReport(Report report) async {
    final currentUser = _auth.currentUser;
    await lostReports.add({
      'category': report.category.toLowerCase(),
      'location': report.location,
      'date': report.date,
      'description': report.description,
      'itemName': report.itemName,
      'userId': currentUser?.uid,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Emit itemReported event for new lost item
    _eventService.emit(NotificationEvent(
      type: NotificationEventType.itemReported,
      data: {
        'itemName': report.itemName,
        'category': report.category,
        'location': report.location,
        'isLost': true,
      },
    ));
  }

  Future<void> submitFoundReport(Report report) async {
    final currentUser = _auth.currentUser;
    await foundReports.add({
      'category': report.category.toLowerCase(),
      'location': report.location,
      'date': report.date,
      'description': report.description,
      'itemName': report.itemName,
      'userId': currentUser?.uid,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Emit itemReported event for new found item
    _eventService.emit(NotificationEvent(
      type: NotificationEventType.itemReported,
      data: {
        'itemName': report.itemName,
        'category': report.category,
        'location': report.location,
        'isLost': false,
      },
    ));

    // Check for matches and emit events
    final matches = await checkForMatches(report);
    for (var match in matches) {
      if (match.result == MatchResult.strong) {
        _eventService.emit(NotificationEvent(
          type: NotificationEventType.matchFound,
          data: {
            'itemName': match.report.itemName,
            'location': match.report.location,
            'lostReportUserId': match.report.userId,
            'foundReportUserId': _auth.currentUser?.uid,
          },
        ));
      } else if (match.result == MatchResult.weak) {
        _eventService.emit(NotificationEvent(
          type: NotificationEventType.matchFoundWeak,
          data: {
            'itemName': match.report.itemName,
            'location': match.report.location,
          },
        ));
      }
    }
  }

  Future<List<MatchDocument>> checkForMatches(Report newFoundReport) async {
    final currentUserUid = _auth.currentUser?.uid;
    final querySnapshot = await lostReports
        .where('category', isEqualTo: newFoundReport.category.toLowerCase())
        .where('status', isEqualTo: 'open')
        .get();

    List<MatchDocument> matches = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final lostReport = Report(
        category: data['category'],
        location: data['location'],
        date: (data['date'] as Timestamp).toDate(),
        description: data['description'],
        itemName: data['itemName'] ?? 'Lost Item',
        userId: data['userId'],
      );

      // Skip if the lost report is from the same user who is submitting the found report
      if (lostReport.userId == currentUserUid) {
        continue;
      }

      final result = compareReports(lostReport, newFoundReport);
      matches.add(MatchDocument(report: lostReport, result: result));
    }

    return matches;
  }
}
