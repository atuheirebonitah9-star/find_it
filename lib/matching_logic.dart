import 'dart:math';

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

MatchResult compareReports(Report lost, Report found) {
  bool locationMatch =
      lost.location.toLowerCase() == found.location.toLowerCase();
  bool dateMatch = lost.date.difference(found.date).inDays.abs() <= 3;

  if (lost.embedding != null && found.embedding != null) {
    double semanticScore = cosineSimilarity(lost.embedding!, found.embedding!);
    double score =
        semanticScore + (locationMatch ? 0.05 : 0) + (dateMatch ? 0.05 : 0);

    print(
      'DEBUG: semanticScore=$semanticScore, locationMatch=$locationMatch, dateMatch=$dateMatch, totalScore=$score',
    );

    if (score >= 0.93) {
      return MatchResult.strong;
    } else if (score >= 0.80) {
      return MatchResult.weak;
    } else {
      return MatchResult.none;
    }
  }

  // Fallback: keyword-based matching if embeddings are unavailable
  int overlapCount = countKeywordOverlap(lost.description, found.description);

  if (locationMatch && dateMatch && overlapCount >= 2) {
    return MatchResult.strong;
  } else if (locationMatch && overlapCount >= 1) {
    return MatchResult.weak;
  } else {
    return MatchResult.none;
  }
}

enum MatchResult { strong, weak, none }
