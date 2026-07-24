import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../matching_logic.dart';
import 'notification_event_service.dart';
import 'embedding_service.dart';
import 'cloudinary_service.dart';
import 'gemini_judgment_service.dart';
import 'image_analysis_service.dart';

class ReportService {
  final CollectionReference lostReports = FirebaseFirestore.instance.collection(
    'lost_reports',
  );

  final CollectionReference foundReports = FirebaseFirestore.instance
      .collection('found_reports');

  final CollectionReference items = FirebaseFirestore.instance.collection(
    'items',
  );

  final CollectionReference userMatches = FirebaseFirestore.instance.collection(
    'user_matches',
  );

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationEventService _eventService = NotificationEventService();
  final EmbeddingService _embeddingService = EmbeddingService();
  final GeminiJudgmentService _geminiService = GeminiJudgmentService();
  final ImageAnalysisService _imageAnalysisService = ImageAnalysisService();

  Future<List<double>?> _getEmbedding(Report report) async {
    final text = '${report.itemName} ${report.category} ${report.description}';
    return await _embeddingService.getEmbedding(text);
  }

  /// If the embedding-based result already looks promising (weak or strong),
  /// ask Gemini to double-check — this catches brand/model conflicts and
  /// judges item identity independent of location. Falls back to the
  /// embedding result if Gemini fails or the result was already "none".
  ///
  /// Before asking Gemini, this also applies a hard veto: if the text read
  /// off each item's image (student number / full name) clearly conflicts
  /// — e.g. two different names on two ID cards — the reports can't be the
  /// same item, regardless of how similar the embeddings or descriptions
  /// looked.
  Future<MatchResult> _refineWithGemini(
      MatchResult embeddingResult,
      Report a,
      Report b,
      ) async {
    if (embeddingResult == MatchResult.none) return embeddingResult;

    if (_imageAnalysisService.identifiersConflict(
      a.extractedIdentifiers,
      b.extractedIdentifiers,
    )) {
      return MatchResult.none;
    }

    final geminiResult = await _geminiService.judgeMatch(a, b);
    return geminiResult ?? embeddingResult;
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
    ExtractedIdentifiers? extractedIdentifiers = report.extractedIdentifiers;

    if (report.imageUrl != null) {
      imageUrl = await uploadImage(report.imageUrl!);

      // Extract identifiers from the uploaded image if not already extracted
      extractedIdentifiers ??=
      await _imageAnalysisService.analyzeImageFromUrl(imageUrl!);
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
      if (extractedIdentifiers != null)
        'extractedIdentifiers': extractedIdentifiers.toMap(),
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
      if (extractedIdentifiers != null)
        'extractedIdentifiers': extractedIdentifiers.toMap(),
    });

    final reportWithEmbedding = Report(
      category: report.category,
      location: report.location,
      date: report.date,
      description: report.description,
      itemName: report.itemName,
      userId: currentUser?.uid,
      embedding: embedding,
      imageUrl: imageUrl,
      extractedIdentifiers: extractedIdentifiers,
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

    // Save matches for user
    if (currentUser?.uid != null) {
      await _saveMatchesForUser(
        currentUser?.uid ?? '',
        matches,
        report.itemName,
      );
    }

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
    ExtractedIdentifiers? extractedIdentifiers = report.extractedIdentifiers;

    if (report.imageUrl != null) {
      imageUrl = await uploadImage(report.imageUrl!);

      // Extract identifiers from the uploaded image if not already extracted
      extractedIdentifiers ??=
      await _imageAnalysisService.analyzeImageFromUrl(imageUrl!);
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
      if (extractedIdentifiers != null)
        'extractedIdentifiers': extractedIdentifiers.toMap(),
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
      if (extractedIdentifiers != null)
        'extractedIdentifiers': extractedIdentifiers.toMap(),
    });

    final reportWithEmbedding = Report(
      category: report.category,
      location: report.location,
      date: report.date,
      description: report.description,
      itemName: report.itemName,
      userId: currentUser?.uid,
      embedding: embedding,
      imageUrl: imageUrl,
      extractedIdentifiers: extractedIdentifiers,
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

    // Save matches for user
    if (currentUser?.uid != null) {
      await _saveMatchesForUser(
        currentUser?.uid ?? '',
        matches,
        report.itemName,
      );
    }

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
        extractedIdentifiers: data['extractedIdentifiers'] != null
            ? ExtractedIdentifiers.fromMap(
          Map<String, dynamic>.from(data['extractedIdentifiers']),
        )
            : null,
      );

      if (lostReport.userId == currentUserUid) continue;

      final embeddingResult = await compareReports(lostReport, newFoundReport);
      final finalResult = await _refineWithGemini(
        embeddingResult,
        lostReport,
        newFoundReport,
      );
      matches.add(MatchDocument(report: lostReport, result: finalResult));
    }

    return matches;
  }

  Future<List<MatchDocument>> checkForFoundMatches(Report newLostReport) async {
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
        extractedIdentifiers: data['extractedIdentifiers'] != null
            ? ExtractedIdentifiers.fromMap(
          Map<String, dynamic>.from(data['extractedIdentifiers']),
        )
            : null,
      );

      if (foundReport.userId == currentUserUid) continue;

      final embeddingResult = await compareReports(newLostReport, foundReport);
      final finalResult = await _refineWithGemini(
        embeddingResult,
        newLostReport,
        foundReport,
      );
      matches.add(MatchDocument(report: foundReport, result: finalResult));
    }

    return matches;
  }

  Future<void> _saveMatchesForUser(String userId, List<MatchDocument> matches, String reportItemName) async {
    final batch = FirebaseFirestore.instance.batch();

    for (var match in matches) {
      if (match.result == MatchResult.none) continue;

      final matchDoc = userMatches.doc();
      batch.set(matchDoc, {
        'userId': userId,
        'matchedReportData': {
          'itemName': match.report.itemName,
          'category': match.report.category,
          'location': match.report.location,
          'date': match.report.date,
          'description': match.report.description,
          'userId': match.report.userId,
          'imageUrl': match.report.imageUrl,
          'extractedIdentifiers': match.report.extractedIdentifiers?.toMap(),
        },
        'result': match.result.toString().split('.').last,
        'reportItemName': reportItemName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Stream<QuerySnapshot> getUserMatchesStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }
    return userMatches.where('userId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot> getUserItemsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }
    return items.where('userId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots();
  }
}