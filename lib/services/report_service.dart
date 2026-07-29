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

  final CollectionReference foundReports = FirebaseFirestore.instance.collection(
    'found_reports',
  );

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

  Future<String?> uploadImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;
    try {
      final result = await CloudinaryService.uploadItemImage(File(imagePath));
      return result;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }

  Future<ExtractedIdentifiers?> analyzeImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    try {
      return await _imageAnalysisService.analyzeImageFromUrl(imageUrl);
    } catch (e) {
      print('Image analysis error: $e');
      return null;
    }
  }

  // ============ SUBMIT LOST REPORT ============
  Future<List<MatchDocument>> submitLostReport(Report report) async {
    final currentUser = _auth.currentUser;
    final embedding = await _getEmbedding(report);

    String? imageUrl;
    ExtractedIdentifiers? extractedIdentifiers = report.extractedIdentifiers;

    if (report.imageUrl != null && report.imageUrl!.isNotEmpty) {
      if (report.imageUrl!.startsWith('http')) {
        imageUrl = report.imageUrl;
      } else {
        imageUrl = await uploadImage(report.imageUrl);
      }

      if (imageUrl != null) {
        extractedIdentifiers = await analyzeImage(imageUrl);
        print('AI Analysis Result (lost): ${extractedIdentifiers?.toMap()}');
      }
    }

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
      isLost: true,
      status: 'lost',
    );

    _eventService.emit(
      NotificationEvent(
        type: NotificationEventType.itemReported,
        data: {
          'itemName': report.itemName,
          'category': report.category,
          'location': report.location,
          'isLost': true,
          'imageUrl': imageUrl ?? '',
        },
        targetUserId: currentUser?.uid,
      ),
    );

    final matches = await checkForFoundMatches(reportWithEmbedding);

    matches.sort((a, b) {
      if (a.result == MatchResult.strong && b.result != MatchResult.strong) return -1;
      if (a.result != MatchResult.strong && b.result == MatchResult.strong) return 1;
      if (a.result == MatchResult.weak && b.result == MatchResult.none) return -1;
      if (a.result == MatchResult.none && b.result == MatchResult.weak) return 1;
      return b.score.compareTo(a.score);
    });

    if (currentUser?.uid != null) {
      await _saveMatchesForUser(
        currentUser?.uid ?? '',
        matches,
        report.itemName,
      );
    }

    final lostReportUserId = _auth.currentUser?.uid;
    for (var match in matches) {
      final foundReportUserId = match.report.userId;
      final commonData = {
        'itemName': match.report.itemName,
        'location': match.report.location,
        'lostReportUserId': lostReportUserId,
        'foundReportUserId': foundReportUserId,
        'imageUrl': match.report.imageUrl ?? '',
      };

      if (match.result == MatchResult.strong) {
        if (lostReportUserId != null) {
          _eventService.emit(
            NotificationEvent(
              type: NotificationEventType.matchFound,
              data: {...commonData, 'role': 'lost'},
              targetUserId: lostReportUserId,
            ),
          );
        }
        if (foundReportUserId != null && foundReportUserId != lostReportUserId) {
          _eventService.emit(
            NotificationEvent(
              type: NotificationEventType.matchFound,
              data: {...commonData, 'role': 'found'},
              targetUserId: foundReportUserId,
            ),
          );
        }
      } else if (match.result == MatchResult.weak) {
        if (lostReportUserId != null) {
          _eventService.emit(
            NotificationEvent(
              type: NotificationEventType.matchFoundWeak,
              data: {...commonData, 'role': 'lost'},
              targetUserId: lostReportUserId,
            ),
          );
        }
        if (foundReportUserId != null && foundReportUserId != lostReportUserId) {
          _eventService.emit(
            NotificationEvent(
              type: NotificationEventType.matchFoundWeak,
              data: {...commonData, 'role': 'found'},
              targetUserId: foundReportUserId,
            ),
          );
        }
      }
    }

    return matches;
  }

  // ============ SUBMIT FOUND REPORT ============
  Future<List<MatchDocument>> submitFoundReport(Report report) async {
    final currentUser = _auth.currentUser;
    final embedding = await _getEmbedding(report);

    String? imageUrl;
    ExtractedIdentifiers? extractedIdentifiers = report.extractedIdentifiers;

    if (report.imageUrl != null && report.imageUrl!.isNotEmpty) {
      if (report.imageUrl!.startsWith('http')) {
        imageUrl = report.imageUrl;
      } else {
        imageUrl = await uploadImage(report.imageUrl);
      }

      if (imageUrl != null) {
        extractedIdentifiers = await analyzeImage(imageUrl);
        print('AI Analysis Result (found): ${extractedIdentifiers?.toMap()}');
      }
    }

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
      isLost: false,
      status: 'found',
    );

    _eventService.emit(
      NotificationEvent(
        type: NotificationEventType.itemReported,
        data: {
          'itemName': report.itemName,
          'category': report.category,
          'location': report.location,
          'isLost': false,
          'imageUrl': imageUrl ?? '',
        },
        targetUserId: currentUser?.uid,
      ),
    );

    final matches = await checkForMatches(reportWithEmbedding);

    matches.sort((a, b) {
      if (a.result == MatchResult.strong && b.result != MatchResult.strong) return -1;
      if (a.result != MatchResult.strong && b.result == MatchResult.strong) return 1;
      if (a.result == MatchResult.weak && b.result == MatchResult.none) return -1;
      if (a.result == MatchResult.none && b.result == MatchResult.weak) return 1;
      return b.score.compareTo(a.score);
    });

    if (currentUser?.uid != null) {
      await _saveMatchesForUser(
        currentUser?.uid ?? '',
        matches,
        report.itemName,
      );
    }

    final foundReportUserId = _auth.currentUser?.uid;
    for (var match in matches) {
      final lostReportUserId = match.report.userId;
      final commonData = {
        'itemName': match.report.itemName,
        'location': match.report.location,
        'lostReportUserId': lostReportUserId,
        'foundReportUserId': foundReportUserId,
        'imageUrl': match.report.imageUrl ?? '',
      };

      if (match.result == MatchResult.strong) {
        if (foundReportUserId != null) {
          _eventService.emit(
            NotificationEvent(
              type: NotificationEventType.matchFound,
              data: {...commonData, 'role': 'found'},
              targetUserId: foundReportUserId,
            ),
          );
        }
        if (lostReportUserId != null && lostReportUserId != foundReportUserId) {
          _eventService.emit(
            NotificationEvent(
              type: NotificationEventType.matchFound,
              data: {...commonData, 'role': 'lost'},
              targetUserId: lostReportUserId,
            ),
          );
        }
      } else if (match.result == MatchResult.weak) {
        if (foundReportUserId != null) {
          _eventService.emit(
            NotificationEvent(
              type: NotificationEventType.matchFoundWeak,
              data: {...commonData, 'role': 'found'},
              targetUserId: foundReportUserId,
            ),
          );
        }
        if (lostReportUserId != null && lostReportUserId != foundReportUserId) {
          _eventService.emit(
            NotificationEvent(
              type: NotificationEventType.matchFoundWeak,
              data: {...commonData, 'role': 'lost'},
              targetUserId: lostReportUserId,
            ),
          );
        }
      }
    }

    return matches;
  }

  // ============ CHECK FOR MATCHES ============
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
        category: data['category'] ?? '',
        location: data['location'] ?? '',
        date: (data['date'] as Timestamp).toDate(),
        description: data['description'] ?? '',
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
        isLost: true,
        status: 'lost',
      );

      if (lostReport.userId == currentUserUid) continue;

      final matchResult = await compareReportsWithDetails(lostReport, newFoundReport);

      if (matchResult.result != MatchResult.none) {
        final refinedResult = await _refineWithGemini(
          matchResult.result,
          lostReport,
          newFoundReport,
        );

        if (refinedResult == MatchResult.none) continue;

        final updatedMatch = MatchDocument(
          report: lostReport,
          result: refinedResult,
          score: matchResult.score,
          details: matchResult.details,
        );
        matches.add(updatedMatch);
      }
    }

    return matches;
  }

  // ============ CHECK FOR FOUND MATCHES ============
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
        category: data['category'] ?? '',
        location: data['location'] ?? '',
        date: (data['date'] as Timestamp).toDate(),
        description: data['description'] ?? '',
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
        isLost: false,
        status: 'found',
      );

      if (foundReport.userId == currentUserUid) continue;

      final matchResult = await compareReportsWithDetails(newLostReport, foundReport);

      if (matchResult.result != MatchResult.none) {
        final refinedResult = await _refineWithGemini(
          matchResult.result,
          newLostReport,
          foundReport,
        );

        if (refinedResult == MatchResult.none) continue;

        final updatedMatch = MatchDocument(
          report: foundReport,
          result: refinedResult,
          score: matchResult.score,
          details: matchResult.details,
        );
        matches.add(updatedMatch);
      }
    }

    return matches;
  }

  // ============ SAVE MATCHES FOR USER ============
  Future<void> _saveMatchesForUser(String userId, List<MatchDocument> matches, String reportItemName) async {
    final realMatches = matches.where((m) => m.result != MatchResult.none).toList();
    if (realMatches.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    for (var match in realMatches) {
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
          'isLost': match.report.isLost,
          'status': match.report.status,
        },
        'result': match.result.toString().split('.').last,
        'score': match.score,
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