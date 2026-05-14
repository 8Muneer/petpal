import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:petpal/core/secrets.dart';

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
  static const String _apiKey = geminiApiKey;
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  Future<GeminiMatchResult?> compareImages(
      String imageUrl1, String imageUrl2) async {
    try {
      final bytes1 = await _downloadImage(imageUrl1);
      final bytes2 = await _downloadImage(imageUrl2);
      if (bytes1 == null || bytes2 == null) {
        debugPrint('[Gemini] Failed to download one or both images');
        return null;
      }

      final mime1 = _mimeFromUrl(imageUrl1);
      final mime2 = _mimeFromUrl(imageUrl2);

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': '''You are a forensic animal identification expert. Your ONLY job is to determine whether two photos show the EXACT SAME individual animal — not the same breed, not the same color, not a similar-looking animal. The EXACT SAME individual.

CRITICAL MINDSET:
- Two golden retrievers are NOT a match just because they look alike.
- Two black cats are NOT a match just because they are black.
- A match means: this is biologically the SAME animal, photographed twice.
- You must find INDIVIDUAL-SPECIFIC evidence, not breed-level or color-level similarities.

STEP 1 — Deep analysis of Photo 1. For each feature, describe it with maximum precision:
A) FACE & HEAD:
   - Exact shape and size of nose (color, size, any spots or asymmetry)
   - Eye color, shape, and any unique reflections or heterochromia
   - Ear shape, size, position, any notches, tears, or folding
   - Forehead and muzzle markings with exact location and shape
   - Any facial asymmetries

B) COAT PATTERN (most important for individual ID):
   - Every visible patch, stripe, spot — describe EXACT shape, edge, and location on body
   - Where exactly do color transitions happen (e.g. "white starts at mid-chest, not collar")
   - Any swirls, whorls, or fur direction anomalies
   - Belly, chest, paw coloring — exact description

C) BODY:
   - Overall body proportions and build (lean, stocky, long-bodied, etc.)
   - Tail shape, length, color pattern
   - Leg coloring — which legs have which colors and how far up
   - Any physical abnormalities: limps, missing fur patches, wounds, scars, ear tags, collar

D) UNIQUE IDENTIFIERS:
   - Scars, healed wounds, bald spots
   - Collar or harness details (color, pattern, tag shape)
   - Any tattoos, microchip bumps, ear marks
   - Any deformity or injury visible

STEP 2 — Deep analysis of Photo 2 using the exact same framework as Step 1.

STEP 3 — Individual-level forensic comparison:
For each feature catalogued above, explicitly state: MATCH / MISMATCH / CANNOT DETERMINE.
Focus especially on:
- Coat pattern shape and boundaries (are the exact same patches in the exact same positions?)
- Facial markings (same nose spot? same ear notch?)
- Unique identifiers (same scar? same collar?)
- Any ONE clear MISMATCH in a unique feature = strong evidence these are DIFFERENT animals
- Any ONE clear MATCH in a unique identifier (scar, specific patch shape) = strong evidence these are the SAME animal

STEP 4 — Individual Identity Score:
Assign a confidence score based ONLY on individual-specific evidence:
- 85-100: Multiple unique identifiers match (e.g. same scar + same patch shape + same ear notch). Near-certain same animal.
- 65-84: Strong individual evidence, most unique features align, minor photo differences explain rest.
- 45-64: Moderate evidence — same general pattern but cannot confirm unique features due to photo angle/quality.
- 20-44: Weak evidence — same breed/color but no individual features confirmed. Probably different animals.
- 0-19: Clear individual mismatch — same breed but different markings/features visible. Different animals.

RULES:
- Same breed + same color = maximum 25 confidence on its own. Individual features must push it higher.
- If photos are low quality or angles hide key features, cap at 55 maximum unless unique identifiers are visible.
- A unique marking present in Photo 1 but ABSENT in Photo 2 (and would be visible at that angle) = strong mismatch signal.
- set match=true only if confidence >= 50.
- The "reason" must be in Hebrew and must name the SPECIFIC features that drove the score up or down.

OUTPUT: Respond with ONLY this JSON, no markdown, no text before or after:
{"match": false, "confidence": 30, "reason": "תיאור מפורט בעברית של המאפיינים הספציפיים שהתאימו ושלא התאימו"}'''
              },
              {
                'inline_data': {
                  'mime_type': mime1,
                  'data': base64Encode(bytes1),
                }
              },
              {
                'inline_data': {
                  'mime_type': mime2,
                  'data': base64Encode(bytes2),
                }
              },
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
        }
      });

      debugPrint('[Gemini] Sending request...');
      final response = await http
          .post(
            Uri.parse('$_endpoint?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode != 200) {
        debugPrint('[Gemini] API error ${response.statusCode}: ${response.body}');
        return null;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      String? text = decoded['candidates']?[0]?['content']?['parts']?[0]?['text']
          as String?;
      if (text == null) {
        debugPrint('[Gemini] No text in response: ${response.body}');
        return null;
      }

      // Strip markdown code fences if present
      text = text.trim();
      if (text.startsWith('```')) {
        text = text.replaceAll(RegExp(r'```[a-z]*\n?'), '').trim();
      }

      final result = jsonDecode(text) as Map<String, dynamic>;
      return GeminiMatchResult(
        isMatch: result['match'] as bool? ?? false,
        confidence: (result['confidence'] as num?)?.toInt() ?? 0,
        reason: result['reason'] as String? ?? '',
      );
    } catch (e, st) {
      debugPrint('[Gemini] Exception: $e\n$st');
      return null;
    }
  }

  Future<List<int>?> _downloadImage(String url) async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        debugPrint('[Gemini] Image download failed ${response.statusCode}: $url');
        return null;
      }
      return response.bodyBytes;
    } catch (e) {
      debugPrint('[Gemini] Image download exception: $e — $url');
      return null;
    }
  }

  String _mimeFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.png')) return 'image/png';
    if (lower.contains('.webp')) return 'image/webp';
    if (lower.contains('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
