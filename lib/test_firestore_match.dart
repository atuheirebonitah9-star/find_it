import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'matching_logic.dart';
import 'services/report_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final service = ReportService();

  final foundReport = Report(
    category: 'Wallet',
    location: 'Library',
    date: DateTime(2026, 7, 3),
    description: 'found a black wallet near the library entrance',
  );

  final results = await service.checkForMatches(foundReport);

  print('Number of results: ${results.length}');
  for (var result in results) {
    print('Match result: $result');
  }
}
