// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_keys.dart';

class ExtractedIdentifiers {
  final String? studentNumber;
  final String? fullName;
  final String? course;
  final String? additionalText;

  ExtractedIdentifiers({
    this.studentNumber,
    this.fullName,
    this.course,
    this.additionalText,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentNumber': studentNumber,
      'fullName': fullName,
      'course': course,
      'additionalText': additionalText,
    };
  }

  factory ExtractedIdentifiers.fromMap(Map<String, dynamic> map) {
    return ExtractedIdentifiers(
      studentNumber: map['studentNumber'],
      fullName: map['fullName'],
      course: map['course'],
      additionalText: map['additionalText'],
    );
  }
}

class ImageAnalysisService {
  static const String _apiKey = geminiApiKey;

  /// Extract text and personal identifiers from an image URL or local path
  Future<ExtractedIdentifiers?> analyzeImageFromUrl(String imageUrl) async {
    try {
      final base64Image = await _downloadAndEncodeImage(imageUrl);
      if (base64Image == null) return null;
      return await _analyzeImage(base64Image);
    } catch (e) {
      print('IMAGE ANALYSIS EXCEPTION (URL): $e');
      return null;
    }
  }

  /// Extract text and personal identifiers from a local image file
  Future<ExtractedIdentifiers?> analyzeImageFromFile(String imagePath) async {
    try {
      final imageBytes = await _readLocalImage(imagePath);
      if (imageBytes == null) return null;
      final base64Image = base64Encode(imageBytes);
      return await _analyzeImage(base64Image);
    } catch (e) {
      print('IMAGE ANALYSIS EXCEPTION (FILE): $e');
      return null;
    }
  }

  Future<ExtractedIdentifiers?> _analyzeImage(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''
Analyze this image and extract any identifiable information that can help match it to its owner. Common items include student IDs, notebooks, wallets, phones, etc.

Extract the following information if present:
- Student number or ID number
- Full name of the person
- Course or program
- Any other relevant text that might help identify the owner

Respond ONLY with valid JSON in this exact format:
{
  "studentNumber": "string or null",
  "fullName": "string or null",
  "course": "string or null",
  "additionalText": "string or null (any other relevant text from the image)"
}

If none of these are present, set all fields to null.
''',
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

        // Extract JSON from the response
        final jsonStart = content.indexOf('{');
        final jsonEnd = content.lastIndexOf('}') + 1;

        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          final jsonStr = content.substring(jsonStart, jsonEnd);
          final result = jsonDecode(jsonStr);

          return ExtractedIdentifiers(
            studentNumber: result['studentNumber'],
            fullName: result['fullName'],
            course: result['course'],
            additionalText: result['additionalText'],
          );
        }
      }

      print(
        'IMAGE ANALYSIS ERROR: status ${response.statusCode}, body: ${response.body}',
      );
      return null;
    } catch (e) {
      print('IMAGE ANALYSIS EXCEPTION: $e');
      return null;
    }
  }

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

  Future<List<int>?> _readLocalImage(String imagePath) async {
    try {
      final file = await http.get(Uri.parse(imagePath));
      if (file.statusCode == 200) {
        return file.bodyBytes;
      }
      return null;
    } catch (e) {
      print('Failed to read local image: $e');
      return null;
    }
  }

  /// Check if two sets of extracted identifiers match
  bool identifiersMatch(
    ExtractedIdentifiers? id1,
    ExtractedIdentifiers? id2,
  ) {
    if (id1 == null || id2 == null) return false;

    // Check student number match (strongest match)
    if (id1.studentNumber != null &&
        id2.studentNumber != null &&
        id1.studentNumber!.trim().toLowerCase() ==
            id2.studentNumber!.trim().toLowerCase()) {
      return true;
    }

    // Check full name match with course
    if (id1.fullName != null &&
        id2.fullName != null &&
        id1.fullName!.trim().toLowerCase() ==
            id2.fullName!.trim().toLowerCase()) {
      // If names match and either course matches or one course is null
      if ((id1.course == null || id2.course == null) ||
          (id1.course!.trim().toLowerCase() ==
              id2.course!.trim().toLowerCase())) {
        return true;
      }
    }

    return false;
  }
}
