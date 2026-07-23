// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
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

  bool get isEmpty =>
      studentNumber == null &&
          fullName == null &&
          course == null &&
          additionalText == null;
}

class ImageAnalysisService {
  static const String _apiKey = geminiApiKey;

  /// Extract text and personal identifiers from an image URL (e.g. a
  /// Cloudinary URL after upload).
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

  /// Extract text and personal identifiers from a local image file path
  /// (e.g. the path returned by an image picker, before upload).
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
You are an OCR and identity-extraction assistant for a lost-and-found app.
Look ONLY at the text that is physically printed, written, or displayed in
this image (e.g. on a student ID card, notebook cover, luggage tag, phone
lock screen, etc). Do not guess, infer, or autocomplete missing characters.
If a field is not clearly and legibly present in the image, set it to null
rather than guessing.

Transcribe text EXACTLY as it appears (same spelling, spacing, capitalization
where legible). Do not translate, normalize, or "correct" names.

Extract:
- studentNumber: a student/ID/registration number if visible, exactly as printed
- fullName: the full name of the person if visible, exactly as printed
- course: course, program, faculty, or department if visible
- additionalText: any other short identifying text (e.g. serial number,
  phone number, email, house/room number) that is clearly visible

Respond ONLY with valid JSON, no markdown fences, no commentary, in exactly
this format:
{
  "studentNumber": "string or null",
  "fullName": "string or null",
  "course": "string or null",
  "additionalText": "string or null"
}
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
          // Keep the model literal/deterministic — this is transcription,
          // not creative writing.
          'generationConfig': {'temperature': 0},
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
      print(
        'Failed to download image: status ${response.statusCode} for $imageUrl',
      );
      return null;
    } catch (e) {
      print('Failed to download image: $e');
      return null;
    }
  }

  /// Reads raw bytes from a LOCAL file path on disk.
  /// (Previously this incorrectly used http.get on the local path, which
  /// meant local images were never actually analyzed.)
  Future<List<int>?> _readLocalImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        print('Local image file does not exist: $imagePath');
        return null;
      }
      return await file.readAsBytes();
    } catch (e) {
      print('Failed to read local image: $e');
      return null;
    }
  }

  /// Returns true if the two identifier sets clearly belong to the SAME
  /// person/item (a positive match signal).
  bool identifiersMatch(
      ExtractedIdentifiers? id1,
      ExtractedIdentifiers? id2,
      ) {
    if (id1 == null || id2 == null) return false;

    // Student number match is the strongest signal.
    if (_normalized(id1.studentNumber) != null &&
        _normalized(id2.studentNumber) != null &&
        _normalized(id1.studentNumber) == _normalized(id2.studentNumber)) {
      return true;
    }

    // Full name match, optionally corroborated by course.
    if (_normalized(id1.fullName) != null &&
        _normalized(id2.fullName) != null &&
        _normalized(id1.fullName) == _normalized(id2.fullName)) {
      final course1 = _normalized(id1.course);
      final course2 = _normalized(id2.course);
      if (course1 == null || course2 == null || course1 == course2) {
        return true;
      }
    }

    return false;
  }

  /// Returns true if the two identifier sets clearly belong to DIFFERENT
  /// people/items — i.e. a hard conflict that should block a match even if
  /// other signals (image similarity, description text) looked promising.
  /// This is what lets you say "it's the same category/description, but the
  /// name on the ID doesn't match, so it's not the same item."
  bool identifiersConflict(
      ExtractedIdentifiers? id1,
      ExtractedIdentifiers? id2,
      ) {
    if (id1 == null || id2 == null) return false;

    final num1 = _normalized(id1.studentNumber);
    final num2 = _normalized(id2.studentNumber);
    if (num1 != null && num2 != null && num1 != num2) return true;

    final name1 = _normalized(id1.fullName);
    final name2 = _normalized(id2.fullName);
    if (name1 != null && name2 != null && name1 != name2) return true;

    return false;
  }

  String? _normalized(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return null;
    return trimmed.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}