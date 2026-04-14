import 'dart:convert';
import 'dart:io';

class GeminiMatchResult {
  final bool isMatch;
  final int confidence;
  final String reason;

  const GeminiMatchResult({
    required this.isMatch,
    required this.confidence,
    required this.reason,
  });
}

class GeminiMatchingService {
  static const String _apiKey = 'AIzaSyAJtHyltylV2iE8xWNgLrXCvTZypavgOvs';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  Future<GeminiMatchResult?> compareImages(
      String imageUrl1, String imageUrl2) async {
    try {
      final bytes1 = await _downloadImage(imageUrl1);
      final bytes2 = await _downloadImage(imageUrl2);
      if (bytes1 == null || bytes2 == null) return null;

      final base64Image1 = base64Encode(bytes1);
      final base64Image2 = base64Encode(bytes2);

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text':
                    'You are helping match lost and found pets. Compare these two animal photos carefully.\n\nLook at: species, breed, fur/coat color and pattern, body size, distinctive markings or spots, eye color if visible.\n\nAre these the SAME animal?\n\nRespond ONLY with valid JSON in this exact format:\n{"match": true or false, "confidence": number from 0 to 100, "reason": "brief explanation in Hebrew"}'
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image1,
                }
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image2,
                }
              },
            ]
          }
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'temperature': 0.1,
        }
      });

      final client = HttpClient();
      final request = await client
          .postUrl(Uri.parse('$_endpoint?key=$_apiKey'));
      request.headers.set('Content-Type', 'application/json');
      request.write(body);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final text = decoded['candidates']?[0]?['content']?['parts']?[0]?['text']
          as String?;
      if (text == null) return null;

      final result = jsonDecode(text) as Map<String, dynamic>;
      return GeminiMatchResult(
        isMatch: result['match'] as bool? ?? false,
        confidence: (result['confidence'] as num?)?.toInt() ?? 0,
        reason: result['reason'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<int>?> _downloadImage(String url) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) return null;
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      client.close();
      return bytes;
    } catch (_) {
      return null;
    }
  }
}
