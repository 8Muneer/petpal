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

  Future<void> submitReport(ContentReport report) async {
    await _firestore.collection('reports').add(report.toFirestore());
  }

  /// Best-effort fetch of the actual reported content, so the AI can judge the
  /// content itself rather than only the reporter's reason. Returns null when
  /// the target can't be read (e.g. comments stored as subcollections).
  Future<String?> fetchReportedContent(ReportType type, String targetId) async {
    if (targetId.isEmpty) return null;
    try {
      switch (type) {
        case ReportType.post:
          final d =
              (await _firestore.collection('posts').doc(targetId).get()).data();
          return (d?['content'] ?? d?['text'] ?? d?['caption'])?.toString();
        case ReportType.comment:
          final d =
              (await _firestore.collection('comments').doc(targetId).get())
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

  Future<void> resolveReport({
    required String reportId,
    required ReportStatus status,
    required String adminId,
    bool deleteContent = false,
    String? targetId,
    ReportType? type,
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
      String collection;
      switch (type) {
        case ReportType.post:
          collection = 'posts';
          break;
        case ReportType.comment:
          // Comments are usually subcollections, so this might need adjustment
          // For now assuming a flat comments collection or specific logic
          collection = 'comments';
          break;
        case ReportType.user:
          collection = 'users';
          break;
      }
      batch.delete(_firestore.collection(collection).doc(targetId));
    }

    await batch.commit();
  }
}

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return ModerationRepository(FirebaseFirestore.instance);
});
