import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../matching_logic.dart';
import 'notification_event_service.dart';
import 'notification_service.dart';

class MatchDocument {
  final String docId;
  final Map<String, dynamic> data;
  final Report report;

  MatchDocument({
    required this.docId,
    required this.data,
    required this.report,
  });
}

class ReportService {
  final CollectionReference lostReports = FirebaseFirestore.instance.collection(
    'lost_reports',
  );

  final CollectionReference foundReports = FirebaseFirestore.instance
      .collection('found_reports');

  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
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
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<MatchDocument>> checkForMatches(Report newFoundReport) async {
    final querySnapshot = await lostReports
        .where('category', isEqualTo: newFoundReport.category.toLowerCase())
        .where('status', isEqualTo: 'open')
        .get();

    List<MatchDocument> strongMatches = [];

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

      final result = compareReports(lostReport, newFoundReport);
      if (result == MatchResult.strong) {
        strongMatches.add(
          MatchDocument(docId: doc.id, data: data, report: lostReport),
        );
      }
    }

    return strongMatches;
  }
}
