class Report {
  final String category;
  final String location;
  final DateTime date;
  final String description;

  Report({
    required this.category,
    required this.location,
    required this.date,
    required this.description,
  });
}

MatchResult compareReports(Report lost, Report found) {
  bool categoryMatch =
      lost.category.toLowerCase() == found.category.toLowerCase();
  bool locationMatch =
      lost.location.toLowerCase() == found.location.toLowerCase();
  bool dateMatch = lost.date.difference(found.date).inDays.abs() <= 3;

  int overlapCount = countKeywordOverlap(lost.description, found.description);

  if (categoryMatch && locationMatch && dateMatch && overlapCount >= 2) {
    return MatchResult.strong;
  } else if (categoryMatch && locationMatch) {
    return MatchResult.weak;
  } else {
    return MatchResult.none;
  }
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

enum MatchResult { strong, weak, none }

void main() {
  final lostReport = Report(
    category: 'Wallet',
    location: 'Library',
    date: DateTime(2026, 7, 1),
    description: 'black wallet with torn corner and student ID inside',
  );

  final foundReport = Report(
    category: 'Wallet',
    location: 'Library',
    date: DateTime(2026, 7, 3),
    description: 'found a black wallet near the library entrance',
  );

  final result = compareReports(lostReport, foundReport);

  print('Match result: $result');
}
