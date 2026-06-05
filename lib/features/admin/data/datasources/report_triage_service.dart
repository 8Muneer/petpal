import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:petpal/core/secrets.dart';

/// Result of an AI triage pass over a single content report.
class ReportTriage {
  final int severity; // 1 (trivial) – 5 (critical)
  final String category; // Hebrew label
  final String action; // delete | dismiss | escalate
  final String rationale; // short Hebrew explanation

  const ReportTriage({
    required this.severity,
    required this.category,
    required this.action,
    required this.rationale,
  });
}

/// Classifies a moderation report's free-text reason into a severity score,
/// category, suggested action, and a short rationale, using Gemini.
///
/// Advisory only — the admin always makes the final call. Designed to run once
/// per report; the result is cached on the report document by the caller.
class ReportTriageService {
  static const String _apiKey = geminiApiKey;
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static const _validActions = {'delete', 'dismiss', 'escalate'};

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<ReportTriage?> analyze({
    required String type,
    required String reason,
    String? content,
  }) async {
    if (!isConfigured) return null;

    final hasContent = (content ?? '').trim().isNotEmpty;
    // Cap content length to keep the request small and cheap.
    final clipped = hasContent
        ? (content!.trim().length > 600
            ? '${content.trim().substring(0, 600)}…'
            : content.trim())
        : '';

    final prompt = '''
אתה מנהל קהילה של אפליקציית טיפול בחיות מחמד. קיבלת דיווח של משתמש על תוכן.
סוג היעד: $type
סיבת הדיווח: "$reason"
${hasContent ? 'התוכן שדווח: "$clipped"' : '(התוכן שדווח אינו זמין — התבסס על סיבת הדיווח בלבד)'}

${hasContent ? 'התבסס בעיקר על התוכן שדווח עצמו, ולאחר מכן על סיבת הדיווח.' : ''}
דרג את חומרת הדיווח לפי ההשפעה הפוטנציאלית על המשתמשים והחיות:
- 5 = קריטי: סכנת בטיחות, אכזריות לבעלי חיים, איום, הונאה חמורה
- 4 = גבוה: הטרדה, תוכן פוגעני חמור, הונאה
- 3 = בינוני: תוכן לא הולם, ויכוח
- 2 = נמוך: ספאם, פרסומת
- 1 = זניח: תלונה קלה, אי-הבנה

קטגוריות אפשריות: בטיחות, אכזריות לבעלי חיים, הטרדה, ספאם, הונאה, תוכן לא הולם, אחר.
פעולה מומלצת: "delete" (מחיקת התוכן), "escalate" (הסלמה לבדיקה), או "dismiss" (התעלמות).

החזר אך ורק JSON, ללא markdown וללא טקסט נוסף:
{"severity": 3, "category": "ספאם", "action": "dismiss", "rationale": "משפט קצר בעברית"}''';

    try {
      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {'temperature': 0.2},
      });

      final response = await http
          .post(
            Uri.parse('$_endpoint?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        debugPrint(
            '[Triage] API error ${response.statusCode}: ${response.body}');
        return null;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      var text = decoded['candidates']?[0]?['content']?['parts']?[0]?['text']
          as String?;
      if (text == null) return null;

      // Strip markdown fences if present.
      text = text.trim();
      if (text.startsWith('```')) {
        text = text
            .replaceAll(RegExp(r'```[a-zA-Z]*'), '')
            .replaceAll('```', '')
            .trim();
      }

      final json = jsonDecode(text) as Map<String, dynamic>;
      final severity = (json['severity'] as num?)?.toInt() ?? 3;
      final action = (json['action'] as String?)?.toLowerCase() ?? 'escalate';

      return ReportTriage(
        severity: severity.clamp(1, 5),
        category: (json['category'] as String?)?.trim().isNotEmpty == true
            ? (json['category'] as String).trim()
            : 'אחר',
        action: _validActions.contains(action) ? action : 'escalate',
        rationale: (json['rationale'] as String?)?.trim() ?? '',
      );
    } catch (e) {
      debugPrint('[Triage] analyze failed: $e');
      return null;
    }
  }
}

final reportTriageServiceProvider = Provider<ReportTriageService>((ref) {
  return ReportTriageService();
});
