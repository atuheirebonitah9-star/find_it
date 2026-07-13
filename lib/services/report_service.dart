import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../matching_logic.dart';
import 'notification_event_service.dart';

class ReportService {
  final CollectionReference lostReports = FirebaseFirestore.instance.collection(
    'lost_reports',
  );

  final CollectionReference foundReports = FirebaseFirestore.instance
      .collection('found_reports');

  Future<void> submitLostReport(Report report) async {
    await lostReports.add({
      'category': report.category.toLowerCase(),
      'location': report.location,
      'date': report.date,
      'description': report.description,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitFoundReport(Report report) async {
    await foundReports.add({
      'category': report.category.toLowerCase(),
      'location': report.location,
      'date': report.date,
      'description': report.description,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<MatchResult>> checkForMatches(Report newFoundReport) async {
    final querySnapshot = await lostReports
        .where('category', isEqualTo: newFoundReport.category.toLowerCase())
        .where('status', isEqualTo: 'open')
        .get();

    List<MatchResult> results = [];
    final eventService = NotificationEventService();

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

      // Trigger event when matches are found
      if (result == MatchResult.strong) {
        eventService.emit(NotificationEvent(
          type: NotificationEventType.matchFound,
          data: {
            'lostReportId': doc.id,
            'lostItem': lostReport.category,
            'location': lostReport.location,
            'matchStrength': 'strong',
            'description': '${lostReport.category} found at ${lostReport.location}',
          },
        ));
        debugPrint('[ReportService] Strong match found for ${lostReport.category}');
      } else if (result == MatchResult.weak) {
        eventService.emit(NotificationEvent(
          type: NotificationEventType.matchFound_weak,
          data: {
            'lostReportId': doc.id,
            'lostItem': lostReport.category,
            'location': lostReport.location,
            'matchStrength': 'weak',
            'description': '${lostReport.category} might be at ${lostReport.location}',
          },
        ));
      }
    }

    return results;
  }
}
