import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../matching_logic.dart';
import 'notification_event_service.dart';
import 'embedding_service.dart';
import 'cloudinary_service.dart';

class ReportService {
  final CollectionReference lostReports =
      FirebaseFirestore.instance.collection('lost_reports');

  final CollectionReference foundReports =
      FirebaseFirestore.instance.collection('found_reports');

  final CollectionReference items =
      FirebaseFirestore.instance.collection('items');

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationEventService _eventService = NotificationEventService();
  final EmbeddingService _embeddingService = EmbeddingService();

  Future<List<double>?> _getEmbedding(Report report) async {
    final text = '${report.itemName} ${report.category} ${report.description}';
    return await _embeddingService.getEmbedding(text);
  }

  /// Uploads an image file to Cloudinary and returns the secure URL.
  Future<String?> uploadImage(String imagePath) async {
    return await CloudinaryService.uploadItemImage(File(imagePath));
  }

  Future<List<MatchDocument>> submitLostReport(Report report) async {
    final currentUser = _auth.currentUser;
    final embedding = await _getEmbedding(report);

    // Upload image to Cloudinary first (if provided)
    String? imageUrl;
    if (report.imageUrl != null) {
      imageUrl = await uploadImage(report.imageUrl!);
    }

    // Write to lost_reports collection
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
      if (imageUrl != null) 'imageUrl': imageUrl,
    });

    // Also write to the shared items collection so the home feed shows it
    await items.add({
      'category': report.category.toLowerCase(),
      'location': report.location,
      'date': report.date,
      'description': report.description,
      'itemName': report.itemName,
      'userId': currentUser?.uid,
      'status': 'lost',
      'createdAt': FieldValue.serverTimestamp(),
      if (imageUrl != null) 'imageUrl': imageUrl,
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
          'isLost': true,
        },
      ),
    );

    final matches = await checkForFoundMatches(reportWithEmbedding);
    for (var match in matches) {
      if (match.result == MatchResult.strong) {
        _eventService.emit(
          NotificationEvent(
            type: NotificationEventType.matchFound,
            data: {
              'itemName': match.report.itemName,
              'location': match.report.location,
              'lostReportUserId': _auth.currentUser?.uid,
              'foundReportUserId': match.report.userId,
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

  Future<List<MatchDocument>> submitFoundReport(Report report) async {
    final currentUser = _auth.currentUser;
    final embedding = await _getEmbedding(report);

    // Upload image to Cloudinary first (if provided)
    String? imageUrl;
    if (report.imageUrl != null) {
      imageUrl = await uploadImage(report.imageUrl!);
    }

    // Write to found_reports collection
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
      if (imageUrl != null) 'imageUrl': imageUrl,
    });

    // Also write to the shared items collection so the home feed shows it
    await items.add({
      'category': report.category.toLowerCase(),
      'location': report.location,
      'date': report.date,
      'description': report.description,
      'itemName': report.itemName,
      'userId': currentUser?.uid,
      'status': 'found',
      'createdAt': FieldValue.serverTimestamp(),
      if (imageUrl != null) 'imageUrl': imageUrl,
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
        imageUrl: data['imageUrl'],
      );

      if (lostReport.userId == currentUserUid) continue;

      final result = await compareReports(lostReport, newFoundReport);
      matches.add(MatchDocument(report: lostReport, result: result));
    }

    return matches;
  }

  Future<List<MatchDocument>> checkForFoundMatches(
      Report newLostReport) async {
    final currentUserUid = _auth.currentUser?.uid;
    final querySnapshot = await foundReports
        .where('category', isEqualTo: newLostReport.category.toLowerCase())
        .where('status', isEqualTo: 'open')
        .get();

    List<MatchDocument> matches = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final foundReport = Report(
        category: data['category'],
        location: data['location'],
        date: (data['date'] as Timestamp).toDate(),
        description: data['description'],
        itemName: data['itemName'] ?? 'Found Item',
        userId: data['userId'],
        embedding: data['embedding'] != null
            ? List<double>.from(data['embedding'])
            : null,
        imageUrl: data['imageUrl'],
      );

      if (foundReport.userId == currentUserUid) continue;

      final result = await compareReports(newLostReport, foundReport);
      matches.add(MatchDocument(report: foundReport, result: result));
    }

    return matches;
  }
}
