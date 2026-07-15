import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_keys.dart';

class EmbeddingService {
  static const String _apiKey = geminiApiKey;
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent';

  Future<List<double>?> getEmbedding(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_endpoint?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
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
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
