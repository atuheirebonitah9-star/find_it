// ignore_for_file: avoid_print

import 'dart:math';
import 'services/image_comparison_service.dart';

class Report {
  final String category;
  final String location;
  final DateTime date;
  final String description;
  final String? userId;
  final String itemName;
  final List<double>? embedding;
  final String? imageUrl;

  Report({
    required this.category,
    required this.location,
    required this.date,
    required this.description,
    this.userId,
    required this.itemName,
    this.embedding,
    this.imageUrl,
  });
}

class MatchDocument {
  final Report report;
  final MatchResult result;

  MatchDocument({required this.report, required this.result});
}

double cosineSimilarity(List<double> a, List<double> b) {
  double dot = 0, normA = 0, normB = 0;
  for (int i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  return dot / (sqrt(normA) * sqrt(normB));
}

int countKeywordOverlap(String desc1, String desc2) {
  final fillerWords = {
    'a',
    'an',
    'the',
    'with',
    'and',
    'is',
    'was',
    'in',
    'on',
    'at',
    'to',
    'of',
    'it',
    'my',
    'i',
    'has',
    'have',
    'had',
  };

  Set<String> getKeywords(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty && !fillerWords.contains(word))
        .toSet();
  }

  final words1 = getKeywords(desc1);
  final words2 = getKeywords(desc2);

  return words1.intersection(words2).length;
}

Future<MatchResult> compareReports(Report lost, Report found) async {
  bool locationMatch =
      lost.location.toLowerCase() == found.location.toLowerCase();
  bool dateMatch = lost.date.difference(found.date).inDays.abs() <= 3;

  double imageSimilarityScore = 0.0;
  bool hasImageComparison = false;

  // If both reports have images, use image comparison
  if (lost.imageUrl != null &&
      found.imageUrl != null &&
      lost.imageUrl!.isNotEmpty &&
      found.imageUrl!.isNotEmpty) {
    final imageComparisonService = ImageComparisonService();
    final imageResult = await imageComparisonService.compareImages(
      lost.imageUrl!,
      found.imageUrl!,
    );

    if (imageResult != null) {
      hasImageComparison = true;
      imageSimilarityScore = imageResult.similarityScore;
      print(
        'IMAGE COMPARISON: isSameItem=${imageResult.isSameItem}, similarity=$imageSimilarityScore, differences=${imageResult.differences}, confidence=${imageResult.confidence}',
      );

      // If AI says they're different with high confidence, return none immediately
      if (!imageResult.isSameItem && imageResult.confidence == 'high') {
        print(
          'IMAGE COMPARISON: High confidence that items are different - returning no match',
        );
        return MatchResult.none;
      }
    }
  }

  if (lost.embedding != null && found.embedding != null) {
    double semanticScore = cosineSimilarity(lost.embedding!, found.embedding!);

    // Incorporate image similarity into the score if available
    double score = semanticScore;
    if (hasImageComparison) {
      // Give image comparison significant weight (40% of total score)
      score = (semanticScore * 0.6) + (imageSimilarityScore * 0.4);
    }

    score += (locationMatch ? 0.05 : 0) + (dateMatch ? 0.05 : 0);

    print(
      'DEBUG: semanticScore=$semanticScore, imageSimilarity=$imageSimilarityScore (hasImage=$hasImageComparison), locationMatch=$locationMatch, dateMatch=$dateMatch, totalScore=$score',
    );

    if (score >= 0.93) {
      return MatchResult.strong;
    } else if (score >= 0.80) {
      return MatchResult.weak;
    } else {
      return MatchResult.none;
    }
  }

  // Fallback: keyword-based matching if embeddings are unavailable.
  // Location and date are bonus signals here too, not requirements —
  // a genuine match can happen even if the reports were filed in
  // different locations.
  int overlapCount = countKeywordOverlap(lost.description, found.description);
  int score = overlapCount + (locationMatch ? 1 : 0) + (dateMatch ? 1 : 0);

  print(
    'DEBUG (fallback): overlapCount=$overlapCount, locationMatch=$locationMatch, dateMatch=$dateMatch, score=$score',
  );

  if (overlapCount >= 3 || score >= 4) {
    return MatchResult.strong;
  } else if (overlapCount >= 1) {
    return MatchResult.weak;
  } else {
    return MatchResult.none;
  }
}

enum MatchResult { strong, weak, none }
