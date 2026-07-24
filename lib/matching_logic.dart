// ignore_for_file: avoid_print

import 'dart:math';
import 'services/image_comparison_service.dart';
import 'package:flutter/material.dart';
import 'services/image_analysis_service.dart';

class Report {
  final String category;
  final String location;
  final DateTime date;
  final String description;
  final String? userId;
  final String itemName;
  final List<double>? embedding;
  final String? imageUrl;
  final ExtractedIdentifiers? extractedIdentifiers;

  Report({
    required this.category,
    required this.location,
    required this.date,
    required this.description,
    this.userId,
    required this.itemName,
    this.embedding,
    this.imageUrl,
    this.extractedIdentifiers,
  });
}

class MatchDocument {
  final Report report;
  final MatchResult result;
  final double score;
  final MatchDetails details;

  MatchDocument({
    required this.report,
    required this.result,
    this.score = 0.0,
    this.details = const MatchDetails(),
  });
}

class MatchDetails {
  final bool locationMatch;
  final bool dateMatch;
  final int keywordOverlap;
  final double imageSimilarity;
  final bool hasImageComparison;

  const MatchDetails({
    this.locationMatch = false,
    this.dateMatch = false,
    this.keywordOverlap = 0,
    this.imageSimilarity = 0.0,
    this.hasImageComparison = false,
  });
}

double cosineSimilarity(List<double> a, List<double> b) {
  double dot = 0, normA = 0, normB = 0;
  for (int i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA == 0 || normB == 0) return 0.0;
  return dot / (sqrt(normA) * sqrt(normB));
}

int countKeywordOverlap(String desc1, String desc2) {
  final fillerWords = {
    'a', 'an', 'the', 'with', 'and', 'is', 'was', 'in', 'on', 'at', 'to', 'of',
    'it', 'my', 'i', 'has', 'have', 'had', 'for', 'from', 'by', 'or', 'as',
    'but', 'so', 'if', 'then', 'that', 'this', 'these', 'those', 'we', 'you',
    'he', 'she', 'they', 'them', 'their', 'our', 'your', 'its', 'are', 'were',
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
  final imageAnalysisService = ImageAnalysisService();
  
  // FIRST: Check extracted identifiers (strongest possible signal)
  if (lost.extractedIdentifiers != null &&
      found.extractedIdentifiers != null) {
    if (imageAnalysisService.identifiersMatch(
      lost.extractedIdentifiers!,
      found.extractedIdentifiers!,
    )) {
      print('✅ IDENTIFIERS MATCH: Strong match based on extracted student ID/name/etc');
      return MatchResult.strong;
    }
  }
  
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
      print('🖼️ IMAGE COMPARISON: isSameItem=${imageResult.isSameItem}, similarity=$imageSimilarityScore, confidence=${imageResult.confidence}');
    }
  }

  // If embeddings are available, use them
  if (lost.embedding != null && found.embedding != null) {
    double semanticScore = cosineSimilarity(lost.embedding!, found.embedding!);

    // Incorporate image similarity into the score if available
    double score = semanticScore;
    if (hasImageComparison) {
      // Give image comparison significant weight (40% of total score)
      score = (semanticScore * 0.6) + (imageSimilarityScore * 0.4);
    }

    // Add bonus for location and date
    score += (locationMatch ? 0.05 : 0) + (dateMatch ? 0.05 : 0);

    print('📊 SCORE: semantic=$semanticScore, image=$imageSimilarityScore, location=$locationMatch, date=$dateMatch, total=$score');

    if (score >= 0.93) {
      return MatchResult.strong;
    } else if (score >= 0.75) {
      return MatchResult.weak;
    } else {
      return MatchResult.none;
    }
  }

  // Fallback: keyword-based matching if embeddings are unavailable
  int overlapCount = countKeywordOverlap(lost.description, found.description);
  int score = overlapCount + (locationMatch ? 1 : 0) + (dateMatch ? 1 : 0);

  print('📊 FALLBACK SCORE: overlap=$overlapCount, location=$locationMatch, date=$dateMatch, total=$score');

  if (overlapCount >= 3 || score >= 4) {
    return MatchResult.strong;
  } else if (overlapCount >= 1) {
    return MatchResult.weak;
  } else {
    return MatchResult.none;
  }
}

// ============ NEW: Get Match with Details ============
Future<MatchDocument> compareReportsWithDetails(Report lost, Report found) async {
  final result = await compareReports(lost, found);
  
  int keywordOverlap = countKeywordOverlap(lost.description, found.description);
  bool locationMatch = lost.location.toLowerCase() == found.location.toLowerCase();
  bool dateMatch = lost.date.difference(found.date).inDays.abs() <= 3;
  
  // Calculate a score percentage for display
  double score = 0.0;
  if (lost.embedding != null && found.embedding != null) {
    score = cosineSimilarity(lost.embedding!, found.embedding!);
    score += (locationMatch ? 0.05 : 0) + (dateMatch ? 0.05 : 0);
  } else {
    score = (keywordOverlap / 10).clamp(0.0, 1.0);
  }
  
  // Cap score at 1.0
  if (score > 1.0) score = 1.0;
  
  return MatchDocument(
    report: found,
    result: result,
    score: score,
    details: MatchDetails(
      locationMatch: locationMatch,
      dateMatch: dateMatch,
      keywordOverlap: keywordOverlap,
      hasImageComparison: false,
    ),
  );
}

// ============ NEW: Get Match Details for Display ============
String getMatchLabel(MatchResult result) {
  switch (result) {
    case MatchResult.strong:
      return 'Strong Match';
    case MatchResult.weak:
      return 'Weak Match';
    case MatchResult.none:
      return 'No Match';
  }
}

Color getMatchColor(MatchResult result) {
  switch (result) {
    case MatchResult.strong:
      return const Color(0xFF00C853); // Green
    case MatchResult.weak:
      return const Color(0xFFFF8C00); // Orange
    case MatchResult.none:
      return const Color(0xFF808080); // Gray
  }
}

String getMatchScoreLabel(double score) {
  if (score >= 0.9) return 'Excellent';
  if (score >= 0.8) return 'Very Good';
  if (score >= 0.7) return 'Good';
  if (score >= 0.6) return 'Moderate';
  if (score >= 0.5) return 'Fair';
  return 'Low';
}

int getMatchScorePercentage(double score) {
  return (score * 100).round();
}

enum MatchResult { strong, weak, none }

// ============ NEW: Detailed Match Result ============
class DetailedMatchResult {
  final Report report;
  final MatchResult result;
  final double score;
  final int percentage;
  final String label;
  final Color color;
  final String scoreText;
  final MatchDetails details;

  DetailedMatchResult({
    required this.report,
    required this.result,
    required this.score,
    required this.details,
  })  : percentage = getMatchScorePercentage(score),
        label = getMatchLabel(result),
        color = getMatchColor(result),
        scoreText = getMatchScoreLabel(score);
}

// ============ NEW: Get Detailed Match ============
Future<DetailedMatchResult?> getDetailedMatch(Report lost, Report found) async {
  final match = await compareReportsWithDetails(lost, found);
  if (match.result == MatchResult.none) return null;
  
  return DetailedMatchResult(
    report: match.report,
    result: match.result,
    score: match.score,
    details: match.details,
  );
}