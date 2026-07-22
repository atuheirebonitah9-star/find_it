// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_keys.dart';

class EmbeddingService {
  static final String _apiKey = geminiApiKey;
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent';

  Future<List<double>?> getEmbedding(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_endpoint?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'models/gemini-embedding-001',
          'content': {
            'parts': [
              {'text': text},
            ],
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final embedding = data['embedding']['values'];
        return List<double>.from(embedding);
      } else {
        print(
          'EMBEDDING ERROR: status ${response.statusCode}, body: ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('EMBEDDING EXCEPTION: $e');
      return null;
    }
  }
}
