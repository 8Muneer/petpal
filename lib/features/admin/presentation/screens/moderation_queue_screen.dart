import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/admin/data/datasources/report_triage_service.dart';
import 'package:petpal/features/admin/data/repositories/moderation_repository.dart';
import 'package:petpal/features/admin/domain/entities/report_model.dart';
import 'package:petpal/features/admin/presentation/widgets/admin_theme.dart';

class ModerationQueueScreen extends ConsumerStatefulWidget {
  const ModerationQueueScreen({super.key});

  @override
  ConsumerState<ModerationQueueScreen> createState() =>
      _ModerationQueueScreenState();
}

class _ModerationQueueScreenState extends ConsumerState<ModerationQueueScreen> {
  /// Report ids currently being analyzed, to avoid duplicate AI calls.
  final Set<String> _analyzing = {};

  /// Report ids already attempted this session (success or failure), so a
  /// failed/unreachable call isn't retried on every rebuild.
  final Set<String> _attempted = {};

  // ── Ranking helpers ────────────────────────────────────────────────────────

  /// Keyword-based fallback severity used until the AI score lands.
  int _keywordSeverity(String reason) {
    final r = reason.toLowerCase();
    bool has(List<String> w) => w.any(r.contains);
    if (has(const [
      'אכזריות',
      'התעללות',
      'פגיעה',
      'סכנה',
      'איום',
      'נשק',
      'דם',
      'abuse',
      'cruelty',
      'threat',
      'danger',
      'weapon',
      'kill',
      'blood',
    ])) {
      return 5;
    }
    if (has(const [
      'הטרדה',
      'גזענות',
      'אלימות',
      'הונאה',
      'נוכל',
      'harass',
      'scam',
      'fraud',
      'violence',
      'hate',
    ])) {
      return 4;
    }
    if (has(const ['ספאם', 'פרסומת', 'spam', 'advert', 'promo'])) return 2;
    return 3;
  }

  int _effectiveSeverity(ContentReport r) =>
      r.aiSeverity ?? _keywordSeverity(r.reason);

  Future<void> _ensureAnalyzed(List<ContentReport> reports) async {
    final service = ref.read(reportTriageServiceProvider);
    if (!service.isConfigured) return;
    final repo = ref.read(moderationRepositoryProvider);

    var didWork = false;
    for (final r in reports) {
      if (r.isAnalyzed ||
          _analyzing.contains(r.id) ||
          _attempted.contains(r.id)) {
        continue;
      }
      _analyzing.add(r.id);
      _attempted.add(r.id); // don't retry this one on later rebuilds
      didWork = true;
      // Enrich with the actual reported content when reachable.
      final content = await repo.fetchReportedContent(r.type, r.targetId);
      final triage = await service.analyze(
        type: r.type.name,
        reason: r.reason,
        content: content,
      );
      if (triage != null) {
        await repo.saveReportAnalysis(
          reportId: r.id,
          severity: triage.severity,
          category: triage.category,
          action: triage.action,
          rationale: triage.rationale,
        );
      }
      _analyzing.remove(r.id);
    }
    // Refresh the "analyzing…" indicator once the batch settles (failures
    // won't re-emit from Firestore, so we nudge a rebuild ourselves).
    if (didWork && mounted) setState(() {});
  }

  List<_Cluster> _buildClusters(List<ContentReport> reports) {
    final byTarget = <String, List<ContentReport>>{};
    for (final r in reports) {
      byTarget.putIfAbsent(r.targetId, () => []).add(r);
    }
    final clusters = byTarget.values.map((group) {
      final severity =
          group.map(_effectiveSeverity).reduce((a, b) => a > b ? a : b);
      final newest =
          group.map((r) => r.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
      return _Cluster(reports: group, severity: severity, newest: newest);
    }).toList();

    clusters.sort((a, b) {
      // Severity first, then how many reports, then recency.
      final s = b.severity.compareTo(a.severity);
      if (s != 0) return s;
      final c = b.reports.length.compareTo(a.reports.length);
      if (c != 0) return c;
      return b.newest.compareTo(a.newest);
    });
    return clusters;
  }

  @override
  Widget build(BuildContext context) {
    final modRepo = ref.watch(moderationRepositoryProvider);

    return StreamBuilder<List<ContentReport>>(
      stream: modRepo.watchOpenReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data ?? [];
        if (reports.isEmpty) return const _EmptyState();

        // Kick off AI triage for any unscored reports (cached once each).
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _ensureAnalyzed(reports);
        });

        final clusters = _buildClusters(reports);
        // Only show the AI indicator while there is real work pending — i.e.
        // the service is configured and some reports haven't been attempted yet.
        final aiConfigured = ref.read(reportTriageServiceProvider).isConfigured;
        final analyzing = aiConfigured &&
            reports.any((r) => !r.isAnalyzed && !_attempted.contains(r.id));

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          itemCount: clusters.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text('${reports.length} דיווחים פתוחים',
                        style: AdminText.section),
                    const Spacer(),
                    if (analyzing)
                      const Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 6),
                          Text('AI מנתח…', style: AdminText.rowSub),
                        ],
                      )
                    else
                      const Text('ממוין לפי חומרה', style: AdminText.rowSub),
                  ],
                ),
              );
            }
            return _ClusterCard(
              cluster: clusters[i - 1],
              effectiveSeverity: _effectiveSeverity,
              onResolve: (status, deleteContent) =>
                  _resolveCluster(clusters[i - 1], status, deleteContent),
            );
          },
        );
      },
    );
  }

  Future<void> _resolveCluster(
    _Cluster cluster,
    ReportStatus status,
    bool deleteContent,
  ) async {
    final repo = ref.read(moderationRepositoryProvider);
    final adminId = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
    try {
      for (var i = 0; i < cluster.reports.length; i++) {
        final r = cluster.reports[i];
        await repo.resolveReport(
          reportId: r.id,
          status: status,
          adminId: adminId,
          // Delete the underlying content only once, on the first report.
          deleteContent: deleteContent && i == 0,
          targetId: r.targetId,
          type: r.type,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הדיווח טופל')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')),
        );
      }
    }
  }
}

// ─── Cluster model ─────────────────────────────────────────────────────────

class _Cluster {
  final List<ContentReport> reports;
  final int severity;
  final DateTime newest;
  const _Cluster({
    required this.reports,
    required this.severity,
    required this.newest,
  });
}

// ─── Severity / label helpers ──────────────────────────────────────────────

({String label, Color color}) _severityStyle(int s) {
  if (s >= 5) return (label: 'קריטי', color: AppColors.error);
  if (s == 4) return (label: 'גבוה', color: AppColors.warning);
  if (s == 3) return (label: 'בינוני', color: AppColors.smartBlue);
  if (s == 2) return (label: 'נמוך', color: AppColors.blueSlate);
  return (label: 'זניח', color: AppColors.slateGrey);
}

String _typeLabel(ReportType t) => switch (t) {
      ReportType.post => 'פוסט',
      ReportType.comment => 'תגובה',
      ReportType.user => 'משתמש',
    };

String _actionLabel(String action) => switch (action) {
      'delete' => 'מומלץ: מחיקה',
      'escalate' => 'מומלץ: הסלמה',
      'dismiss' => 'מומלץ: התעלמות',
      _ => '',
    };

// ─── Cluster card ──────────────────────────────────────────────────────────

class _ClusterCard extends StatelessWidget {
  final _Cluster cluster;
  final int Function(ContentReport) effectiveSeverity;
  final void Function(ReportStatus status, bool deleteContent) onResolve;

  const _ClusterCard({
    required this.cluster,
    required this.effectiveSeverity,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    // Lead with the highest-severity report (carries the AI rationale).
    final primary = cluster.reports
        .reduce((a, b) => effectiveSeverity(a) >= effectiveSeverity(b) ? a : b);
    final sev = _severityStyle(cluster.severity);
    final count = cluster.reports.length;

    return Container(
      decoration: BoxDecoration(
        color: AdminColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Pill(label: sev.label, color: sev.color, filled: true),
                  const SizedBox(width: 6),
                  if (primary.aiCategory != null)
                    _Pill(
                        label: primary.aiCategory!, color: AdminColors.accent),
                  const Spacer(),
                  if (count > 1)
                    _Pill(label: '$count דיווחים', color: AppColors.error),
                ],
              ),
              const SizedBox(height: 8),
              Text('${_typeLabel(primary.type)} שדווח',
                  style: AdminText.rowTitle),
              const SizedBox(height: 2),
              Text(
                primary.reason.trim().isEmpty ? 'ללא פירוט' : primary.reason,
                style: AdminText.rowSub,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if ((primary.aiRationale ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AdminColors.accent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 13, color: AdminColors.accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          primary.aiRationale!,
                          style:
                              AdminText.rowSub.copyWith(color: AdminColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          children: [
            if (primary.aiAction != null) ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _Pill(
                  label: _actionLabel(primary.aiAction!),
                  color: AppColors.twilightIndigo,
                ),
              ),
              const SizedBox(height: 10),
            ],
            // If clustered, list every reason behind it.
            if (count > 1) ...[
              for (final r in cluster.reports)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: AdminText.rowSub),
                      Expanded(
                        child: Text(
                          r.reason.trim().isEmpty ? 'ללא פירוט' : r.reason,
                          style: AdminText.rowSub,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
            ],
            _infoRow('מזהה יעד', primary.targetId),
            _infoRow('תאריך', _date(cluster.newest)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onResolve(ReportStatus.dismissed, false),
                    child: const Text('התעלם'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => onResolve(ReportStatus.resolved, true),
                    child: const Text('מחק תוכן'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: AdminText.rowSub.copyWith(fontWeight: FontWeight.w800)),
          Expanded(
            child: Text(value,
                style: AdminText.rowSub, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  const _Pill({required this.label, required this.color, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: filled ? Colors.white : color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gavel_rounded,
              size: 56, color: AppColors.success.withValues(alpha: 0.6)),
          const SizedBox(height: 14),
          const Text('אין דיווחים פתוחים', style: AdminText.rowTitle),
          const SizedBox(height: 2),
          const Text('תור הניהול נקי כרגע', style: AdminText.rowSub),
        ],
      ),
    );
  }
}
