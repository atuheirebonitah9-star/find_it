// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_keys.dart';
import '../matching_logic.dart';

class GeminiJudgmentService {
  static const String _apiKey = geminiApiKey;
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent';

  Future<MatchResult?> judgeMatch(Report lost, Report found) async {
    final prompt =
        '''
You are helping a campus lost-and-found app decide if two reports describe the same physical item.

Report A (lost item):
- Item name: ${lost.itemName}
- Category: ${lost.category}
- Location: ${lost.location}
- Description: ${lost.description}

Report B (found item):
- Item name: ${found.itemName}
- Category: ${found.category}
- Location: ${found.location}
- Description: ${found.description}

Rules:
- Location does NOT need to match. A genuine match can happen even if the locations are different.
- Pay close attention to brand, model, and distinguishing details (e.g. "Dell" vs "HP" are different brands and should NOT be considered a match even if everything else is similar).
- Judge primarily on whether these two reports likely describe the same physical item.

Respond ONLY with valid JSON in this exact format, no other text:
{"score": <integer 0-100>, "reason": "<short reason>"}
''';

    try {
      final response = await http.post(
        Uri.parse('$_endpoint?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;
        final cleaned = text
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final parsed = jsonDecode(cleaned);
        final score = parsed['score'] as int;

        print('GEMINI JUDGMENT: score=$score, reason=${parsed['reason']}');

        if (score >= 80) {
          return MatchResult.strong;
        } else if (score >= 50) {
          return MatchResult.weak;
        } else {
          return MatchResult.none;
        }
      } else {
        print(
          'GEMINI JUDGMENT ERROR: status ${response.statusCode}, body: ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('GEMINI JUDGMENT EXCEPTION: $e');
      return null;
    }
  }
}
