import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/features/admin/domain/entities/report_model.dart';

class ModerationRepository {
  final FirebaseFirestore _firestore;

  ModerationRepository(this._firestore);

  Stream<List<ContentReport>> watchOpenReports() {
    return _firestore
        .collection('reports')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContentReport.fromFirestore(doc))
            .toList());
  }

  /// Writes with a deterministic id (`type_targetId_reporterId`) instead of
  /// `.add()` — a second report by the same user on the same target
  /// overwrites the first instead of creating a duplicate document. This is
  /// what makes AI triage actually O(distinct targets): without it, rapid
  /// re-taps or resubmits each became a separate report and a separate
  /// Gemini call on identical content. Overwriting (not merging) is
  /// intentional: if the prior report on this id was already resolved, a
  /// fresh report on the same content should reopen it as a new `open` case
  /// rather than silently staying closed.
  Future<void> submitReport(ContentReport report) async {
    final id = '${report.type.name}_${report.targetId}_${report.reporterId}';
    await _firestore.collection('reports').doc(id).set(report.toFirestore());
  }

  /// Best-effort fetch of the actual reported content, so the AI can judge the
  /// content itself rather than only the reporter's reason. Returns null when
  /// the target can't be read. Comments and messages live in subcollections
  /// (`posts/{parentId}/comments/{targetId}`, `conversations/{parentId}/messages/{targetId}`)
  /// so [parentId] is required to locate them.
  Future<String?> fetchReportedContent(
    ReportType type,
    String targetId, {
    String? parentId,
  }) async {
    if (targetId.isEmpty) return null;
    try {
      switch (type) {
        case ReportType.post:
          final d =
              (await _firestore.collection('posts').doc(targetId).get()).data();
          return (d?['content'] ?? d?['text'] ?? d?['caption'])?.toString();
        case ReportType.comment:
          if (parentId == null || parentId.isEmpty) return null;
          final d = (await _firestore
                  .collection('posts')
                  .doc(parentId)
                  .collection('comments')
                  .doc(targetId)
                  .get())
              .data();
          return (d?['text'] ?? d?['content'])?.toString();
        case ReportType.message:
          if (parentId == null || parentId.isEmpty) return null;
          final d = (await _firestore
                  .collection('conversations')
                  .doc(parentId)
                  .collection('messages')
                  .doc(targetId)
                  .get())
              .data();
          return (d?['text'] ?? d?['content'])?.toString();
        case ReportType.user:
          final d =
              (await _firestore.collection('users').doc(targetId).get()).data();
          if (d == null) return null;
          final parts = [d['name'] ?? d['displayName'] ?? '', d['bio'] ?? '']
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty);
          return parts.isEmpty ? null : parts.join(' — ');
      }
    } catch (_) {
      return null;
    }
  }

  /// Caches the AI triage result on the report document.
  Future<void> saveReportAnalysis({
    required String reportId,
    required int severity,
    required String category,
    required String action,
    required String rationale,
  }) async {
    await _firestore.collection('reports').doc(reportId).update({
      'aiSeverity': severity,
      'aiCategory': category,
      'aiAction': action,
      'aiRationale': rationale,
    });
  }

  /// Same as [saveReportAnalysis], applied to every report in [reportIds] in
  /// one batch. All reports targeting the same content share a single
  /// Gemini analysis (see ModerationQueueScreen._ensureAnalyzed), so the
  /// result is fanned out to the whole cluster instead of one report at a
  /// time — keeps every report on a target carrying the same severity, and
  /// is one write instead of N round trips.
  Future<void> saveReportAnalysisForCluster({
    required List<String> reportIds,
    required int severity,
    required String category,
    required String action,
    required String rationale,
  }) async {
    final batch = _firestore.batch();
    for (final reportId in reportIds) {
      batch.update(_firestore.collection('reports').doc(reportId), {
        'aiSeverity': severity,
        'aiCategory': category,
        'aiAction': action,
        'aiRationale': rationale,
      });
    }
    await batch.commit();
  }

  Future<void> resolveReport({
    required String reportId,
    required ReportStatus status,
    required String adminId,
    bool deleteContent = false,
    String? targetId,
    ReportType? type,
    String? parentId,
  }) async {
    final batch = _firestore.batch();

    // Update report status
    batch.update(_firestore.collection('reports').doc(reportId), {
      'status': status.name,
      'resolvedBy': adminId,
      'resolvedAt': FieldValue.serverTimestamp(),
    });

    // Optionally delete the reported content
    if (deleteContent && targetId != null && type != null) {
      DocumentReference<Map<String, dynamic>>? ref;
      switch (type) {
        case ReportType.post:
          ref = _firestore.collection('posts').doc(targetId);
          break;
        case ReportType.comment:
          if (parentId != null && parentId.isNotEmpty) {
            ref = _firestore
                .collection('posts')
                .doc(parentId)
                .collection('comments')
                .doc(targetId);
          }
          break;
        case ReportType.message:
          if (parentId != null && parentId.isNotEmpty) {
            ref = _firestore
                .collection('conversations')
                .doc(parentId)
                .collection('messages')
                .doc(targetId);
          }
          break;
        case ReportType.user:
          ref = _firestore.collection('users').doc(targetId);
          break;
      }
      if (ref != null) batch.delete(ref);
    }

    await batch.commit();
  }
}

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return ModerationRepository(FirebaseFirestore.instance);
});
