import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  Future<String> _loadTerms() async {
    return await rootBundle.loadString('lib/assets/terms.md');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: FutureBuilder<String>(
        future: _loadTerms(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(snapshot.data!),
          );
        },
      ),
    );
  }
}
