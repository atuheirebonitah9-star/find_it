// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_keys.dart';

class ImageClassificationService {
  static const String _apiKey = geminiApiKey;

  // Categorize image using Google Vision API
  Future<String?> classifyImage(String imagePath) async {
    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(imageBytes);

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
                  'text':
                      'Analyze this image and categorize it into one of these categories: Wallet, Phone, ID Card, Keys, Bag, Other. Return only the category name, nothing else.',
                },
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image,
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
        return _normalizeCategory(content.trim());
      } else {
        print(
          'IMAGE CLASSIFICATION ERROR: status ${response.statusCode}, body: ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('IMAGE CLASSIFICATION EXCEPTION: $e');
      return null;
    }
  }

  String _normalizeCategory(String category) {
    final validCategories = [
      'Wallet',
      'Phone',
      'ID Card',
      'Keys',
      'Bag',
      'Other',
    ];

    for (var valid in validCategories) {
      if (category.toLowerCase().contains(valid.toLowerCase())) {
        return valid;
      }
    }

    return 'Other';
  }
}
