import 'package:cloud_firestore/cloud_firestore.dart';
import '../matching_logic.dart';

class ReportService {
  final CollectionReference lostReports = FirebaseFirestore.instance.collection(
    'lost_reports',
  );

  final CollectionReference foundReports = FirebaseFirestore.instance
      .collection('found_reports');

  Future<void> submitLostReport(Report report) async {
    await lostReports.add({
      'category': report.category,
      'location': report.location,
      'date': report.date,
      'description': report.description,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitFoundReport(Report report) async {
    await foundReports.add({
      'category': report.category,
      'location': report.location,
      'date': report.date,
      'description': report.description,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<MatchResult>> checkForMatches(Report newFoundReport) async {
    final querySnapshot = await lostReports
        .where('category', isEqualTo: newFoundReport.category)
        .where('status', isEqualTo: 'open')
        .get();

    List<MatchResult> results = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final lostReport = Report(
        category: data['category'],
        location: data['location'],
        date: (data['date'] as Timestamp).toDate(),
        description: data['description'],
      );

      final result = compareReports(lostReport, newFoundReport);
      results.add(result);
    }

    return results;
  }
}
