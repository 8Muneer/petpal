import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportType {
  post,
  comment,
  user,
}

enum ReportStatus {
  open,
  resolved,
  dismissed,
}

class ContentReport {
  final String id;
  final String targetId; // ID of post, comment, or user
  final ReportType type;
  final String reporterId;
  final String reason;
  final ReportStatus status;
  final DateTime createdAt;
  final String? resolvedBy;
  final DateTime? resolvedAt;

  // ── AI triage (cached once per report) ──
  /// 1 (trivial) – 5 (critical), null until analyzed.
  final int? aiSeverity;
  final String? aiCategory;
  final String? aiAction; // delete | dismiss | escalate
  final String? aiRationale;

  ContentReport({
    required this.id,
    required this.targetId,
    required this.type,
    required this.reporterId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.resolvedBy,
    this.resolvedAt,
    this.aiSeverity,
    this.aiCategory,
    this.aiAction,
    this.aiRationale,
  });

  bool get isAnalyzed => aiSeverity != null;

  factory ContentReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContentReport(
      id: doc.id,
      targetId: data['targetId'] ?? '',
      type: ReportType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ReportType.post,
      ),
      reporterId: data['reporterId'] ?? '',
      reason: data['reason'] ?? '',
      status: ReportStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ReportStatus.open,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      resolvedBy: data['resolvedBy'],
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      aiSeverity: (data['aiSeverity'] as num?)?.toInt(),
      aiCategory: data['aiCategory'] as String?,
      aiAction: data['aiAction'] as String?,
      aiRationale: data['aiRationale'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'targetId': targetId,
      'type': type.name,
      'reporterId': reporterId,
      'reason': reason,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'aiSeverity': aiSeverity,
      'aiCategory': aiCategory,
      'aiAction': aiAction,
      'aiRationale': aiRationale,
    };
  }
}
