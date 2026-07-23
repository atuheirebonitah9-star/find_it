// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_keys.dart';

class ImageComparisonService {
  static const String _apiKey = geminiApiKey;

  /// Compares two images and returns a similarity score (0.0 to 1.0)
  /// Also returns a description of differences if any
  Future<ImageComparisonResult?> compareImages(
    String imageUrl1,
    String imageUrl2,
  ) async {
    try {
      // Download and encode both images to base64
      final base64Image1 = await _downloadAndEncodeImage(imageUrl1);
      final base64Image2 = await _downloadAndEncodeImage(imageUrl2);

      if (base64Image1 == null || base64Image2 == null) {
        print('IMAGE COMPARISON: Failed to download one or both images');
        return null;
      }

      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''
Compare these two images and determine if they show the same item or different items.
Analyze visual details carefully including:
- Overall shape and size
- Color patterns and distinctive features
- Any visible damage, scratches, or wear
- Brand logos, text, or unique markings
- Accessories or attachments

Respond in JSON format with this exact structure:
{
  "is_same_item": true/false,
  "similarity_score": 0.0-1.0,
  "differences": "brief description of key differences if any",
  "confidence": "high/medium/low"
}

Be precise and check for the types of each for example in laptops - even small differences like scratches, color variations, or missing accessories should be noted.
''',
                },
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image1,
                  },
                },
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image2,
                  },
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'];

        // Extract JSON from the response
        final jsonStart = content.indexOf('{');
        final jsonEnd = content.lastIndexOf('}') + 1;

        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          final jsonStr = content.substring(jsonStart, jsonEnd);
          final result = jsonDecode(jsonStr);

          return ImageComparisonResult(
            isSameItem: result['is_same_item'] ?? false,
            similarityScore:
                (result['similarity_score'] as num?)?.toDouble() ?? 0.0,
            differences: result['differences'] ?? '',
            confidence: result['confidence'] ?? 'low',
          );
        }
      }

      print(
        'IMAGE COMPARISON ERROR: status ${response.statusCode}, body: ${response.body}',
      );
      return null;
    } catch (e) {
      print('IMAGE COMPARISON EXCEPTION: $e');
      return null;
    }
  }

  /// Download image from URL and convert to base64
  Future<String?> _downloadAndEncodeImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return base64Encode(response.bodyBytes);
      }
      return null;
    } catch (e) {
      print('Failed to download image: $e');
      return null;
    }
  }
}

class ImageComparisonResult {
  final bool isSameItem;
  final double similarityScore;
  final String differences;
  final String confidence;

  ImageComparisonResult({
    required this.isSameItem,
    required this.similarityScore,
    required this.differences,
    required this.confidence,
  });
}
