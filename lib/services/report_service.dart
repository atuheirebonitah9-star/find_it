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

  /// Uploads an image file to Cloudinary and returns the secure URL.
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

  /// Analyzes image and extracts text/identifiers from it
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

    // 1. Resolve image URL first (already uploaded from report screen)
    String? imageUrl;
    if (report.imageUrl != null && report.imageUrl!.isNotEmpty) {
      if (report.imageUrl!.startsWith('http')) {
        imageUrl = report.imageUrl;
      } else {
        imageUrl = await uploadImage(report.imageUrl);
      }
    }

    // 2. Run embedding and image analysis in parallel to save time
    final results = await Future.wait([
      _getEmbedding(report),
      analyzeImage(imageUrl),
    ]);

    final embedding = results[0] as List<double>?;
    final extractedIdentifiers =
        (results[1] as ExtractedIdentifiers?) ?? report.extractedIdentifiers;

    if (imageUrl != null) {
      print('AI Analysis Result (lost): ${extractedIdentifiers?.toMap()}');
    }

    // 2. Save to lost_reports collection
    final lostReportData = {
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
    };

    await lostReports.add(lostReportData);

    // 3. Also save to items collection for home feed
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
    );

    // 4. Emit notification event
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

    // 5. Check for matches
    final matches = await checkForFoundMatches(reportWithEmbedding);

    // Sort matches by result (strong first) and then by score if available
    matches.sort((a, b) {
      if (a.result == MatchResult.strong && b.result != MatchResult.strong) return -1;
      if (a.result != MatchResult.strong && b.result == MatchResult.strong) return 1;
      if (a.result == MatchResult.weak && b.result == MatchResult.none) return -1;
      if (a.result == MatchResult.none && b.result == MatchResult.weak) return 1;
      return b.score.compareTo(a.score);
    });

    // 6. Save matches
    if (currentUser?.uid != null) {
      await _saveMatchesForUser(
        currentUser?.uid ?? '',
        matches,
        report.itemName,
      );
    }

    // ============ EMIT NOTIFICATIONS ============
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
        // Notify lost report user (current reporter)
        if (lostReportUserId != null) {
          _eventService.emit(
            NotificationEvent(
              type: NotificationEventType.matchFound,
              data: {...commonData, 'role': 'lost'},
              targetUserId: lostReportUserId,
            ),
          );
        }
        // Notify found report user (match owner)
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
        // Notify lost report user (current reporter)
        if (lostReportUserId != null) {
          _eventService.emit(
            NotificationEvent(
              type: NotificationEventType.matchFoundWeak,
              data: {...commonData, 'role': 'lost'},
              targetUserId: lostReportUserId,
            ),
          );
        }
        // Notify found report user (match owner)
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

    // 1. Resolve image URL first (already uploaded from report screen)
    String? imageUrl;
    if (report.imageUrl != null && report.imageUrl!.isNotEmpty) {
      if (report.imageUrl!.startsWith('http')) {
        imageUrl = report.imageUrl;
      } else {
        imageUrl = await uploadImage(report.imageUrl);
      }
    }

    // 2. Run embedding and image analysis in parallel to save time
    final results = await Future.wait([
      _getEmbedding(report),
      analyzeImage(imageUrl),
    ]);

    final embedding = results[0] as List<double>?;
    final extractedIdentifiers =
        (results[1] as ExtractedIdentifiers?) ?? report.extractedIdentifiers;

    if (imageUrl != null) {
      print('AI Analysis Result (found): ${extractedIdentifiers?.toMap()}');
    }

    // 2. Save to found_reports collection
    final foundReportData = {
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
    };

    await foundReports.add(foundReportData);

    // 3. Also save to items collection for home feed
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
    );

    // 4. Emit notification event
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

    // 5. Check for matches
    final matches = await checkForMatches(reportWithEmbedding);

    // Sort matches by result (strong first) and then by score if available
    matches.sort((a, b) {
      if (a.result == MatchResult.strong && b.result != MatchResult.strong) return -1;
      if (a.result != MatchResult.strong && b.result == MatchResult.strong) return 1;
      if (a.result == MatchResult.weak && b.result == MatchResult.none) return -1;
      if (a.result == MatchResult.none && b.result == MatchResult.weak) return 1;
      return b.score.compareTo(a.score);
    });

    // 6. Save matches
    if (currentUser?.uid != null) {
      await _saveMatchesForUser(
        currentUser?.uid ?? '',
        matches,
        report.itemName,
      );
    }

    // ============ EMIT NOTIFICATIONS ============
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
        // Notify found report user (current reporter)
        if (foundReportUserId != null) {
          _eventService.emit(
            NotificationEvent(
              type: NotificationEventType.matchFound,
              data: {...commonData, 'role': 'found'},
              targetUserId: foundReportUserId,
            ),
          );
        }
        // Notify lost report user (match owner)
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
        // Notify found report user (current reporter)
        if (foundReportUserId != null) {
          _eventService.emit(
            NotificationEvent(
              type: NotificationEventType.matchFoundWeak,
              data: {...commonData, 'role': 'found'},
              targetUserId: foundReportUserId,
            ),
          );
        }
        // Notify lost report user (match owner)
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
      );

      if (lostReport.userId == currentUserUid) continue;

      final matchResult = await compareReportsWithDetails(lostReport, newFoundReport);

      if (matchResult.result != MatchResult.none) {
        final refinedResult = await _refineWithGemini(
          matchResult.result,
          lostReport,
          newFoundReport,
        );

        final updatedMatch = MatchDocument(
          report: matchResult.report,
          result: refinedResult,
          score: matchResult.score,
          details: matchResult.details,
        );
        matches.add(updatedMatch);
      } else {
        matches.add(matchResult);
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
      );

      if (foundReport.userId == currentUserUid) continue;

      final matchResult = await compareReportsWithDetails(newLostReport, foundReport);

      if (matchResult.result != MatchResult.none) {
        final refinedResult = await _refineWithGemini(
          matchResult.result,
          newLostReport,
          foundReport,
        );

        final updatedMatch = MatchDocument(
          report: matchResult.report,
          result: refinedResult,
          score: matchResult.score,
          details: matchResult.details,
        );
        matches.add(updatedMatch);
      } else {
        matches.add(matchResult);
      }
    }

    return matches;
  }

  // ============ SAVE MATCHES FOR USER ============
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