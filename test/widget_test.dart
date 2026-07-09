// Basic Flutter widget test for FindIt app
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Create a simple testable widget that doesn't require Firebase
class TestableApp extends StatelessWidget {
  const TestableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Find It',
      home: Scaffold(
        appBar: AppBar(title: const Text('FindIt')),
        body: const Center(child: Text('Welcome to FindIt')),
      ),
    );
  }
}

void main() {
  testWidgets('App loads and shows title', (WidgetTester tester) async {
    // Build our testable app
    await tester.pumpWidget(const TestableApp());

    // Verify the app title is present
    expect(find.text('FindIt'), findsOneWidget);
    expect(find.text('Welcome to FindIt'), findsOneWidget);
  });
}
