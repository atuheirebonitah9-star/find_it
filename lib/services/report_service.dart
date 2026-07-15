import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../matching_logic.dart';
import 'notification_event_service.dart';
import 'embedding_service.dart';

class ReportService {
  final CollectionReference lostReports = FirebaseFirestore.instance.collection(
    'lost_reports',
  );

  final CollectionReference foundReports = FirebaseFirestore.instance
      .collection('found_reports');

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationEventService _eventService = NotificationEventService();
  final EmbeddingService _embeddingService = EmbeddingService();

  Future<List<double>?> _getEmbedding(Report report) async {
    final text = '${report.itemName} ${report.category} ${report.description}';
    return await _embeddingService.getEmbedding(text);
  }

  Future<void> submitLostReport(Report report) async {
    final currentUser = _auth.currentUser;
    final embedding = await _getEmbedding(report);

    await lostReports.add({
      'category': report.category.toLowerCase(),
      'location': report.location,
      'date': report.date,
      'description': report.description,
      'itemName': report.itemName,
      'userId': currentUser?.uid,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'embedding': embedding,
    });

    _eventService.emit(
      NotificationEvent(
        type: NotificationEventType.itemReported,
        data: {
          'itemName': report.itemName,
          'category': report.category,
          'location': report.location,
          'isLost': true,
        },
      ),
    );
  }

  Future<List<MatchDocument>> submitFoundReport(Report report) async {
    final currentUser = _auth.currentUser;
    final embedding = await _getEmbedding(report);

    await foundReports.add({
      'category': report.category.toLowerCase(),
      'location': report.location,
      'date': report.date,
      'description': report.description,
      'itemName': report.itemName,
      'userId': currentUser?.uid,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'embedding': embedding,
    });

    final reportWithEmbedding = Report(
      category: report.category,
      location: report.location,
      date: report.date,
      description: report.description,
      itemName: report.itemName,
      userId: currentUser?.uid,
      embedding: embedding,
    );

    _eventService.emit(
      NotificationEvent(
        type: NotificationEventType.itemReported,
        data: {
          'itemName': report.itemName,
          'category': report.category,
          'location': report.location,
          'isLost': false,
        },
      ),
    );

    final matches = await checkForMatches(reportWithEmbedding);
    for (var match in matches) {
      if (match.result == MatchResult.strong) {
        _eventService.emit(
          NotificationEvent(
            type: NotificationEventType.matchFound,
            data: {
              'itemName': match.report.itemName,
              'location': match.report.location,
              'lostReportUserId': match.report.userId,
              'foundReportUserId': _auth.currentUser?.uid,
            },
          ),
        );
      } else if (match.result == MatchResult.weak) {
        _eventService.emit(
          NotificationEvent(
            type: NotificationEventType.matchFoundWeak,
            data: {
              'itemName': match.report.itemName,
              'location': match.report.location,
            },
          ),
        );
      }
    }

    return matches;
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
        embedding: data['embedding'] != null
            ? List<double>.from(data['embedding'])
            : null,
      );

      if (lostReport.userId == currentUserUid) {
        continue;
      }

      final result = compareReports(lostReport, newFoundReport);
      matches.add(MatchDocument(report: lostReport, result: result));
    }

    return matches;
  }
}
