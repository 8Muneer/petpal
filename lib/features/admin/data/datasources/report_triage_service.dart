import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
/// The actual Gemini call runs in the `triageReport` Cloud Function
/// (functions/index.js) so the API key never ships inside the app binary —
/// this class is now a thin client for that callable.
///
/// Advisory only — the admin always makes the final call. Designed to run once
/// per report; the result is cached on the report document by the caller.
class ReportTriageService {
  static const _validActions = {'delete', 'dismiss', 'escalate'};

  /// The Gemini key now lives server-side (functions/.env GEMINI_KEY), so the
  /// client can't check configuration up front anymore. A missing key
  /// surfaces as a failed-precondition error from the callable, which
  /// [analyze] already maps to `null` — the moderation queue then falls back
  /// to keyword severity exactly as before.
  bool get isConfigured => true;

  Future<ReportTriage?> analyze({
    required String type,
    required String reason,
    String? content,
  }) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('triageReport');
      final result = await callable.call<Map<String, dynamic>>({
        'type': type,
        'reason': reason,
        if ((content ?? '').trim().isNotEmpty) 'content': content!.trim(),
      }).timeout(const Duration(seconds: 45));

      final data = Map<String, dynamic>.from(result.data);
      final severity = (data['severity'] as num?)?.toInt() ?? 3;
      final action = (data['action'] as String?)?.toLowerCase() ?? 'escalate';

      return ReportTriage(
        severity: severity.clamp(1, 5),
        category: (data['category'] as String?)?.trim().isNotEmpty == true
            ? (data['category'] as String).trim()
            : 'אחר',
        action: _validActions.contains(action) ? action : 'escalate',
        rationale: (data['rationale'] as String?)?.trim() ?? '',
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
