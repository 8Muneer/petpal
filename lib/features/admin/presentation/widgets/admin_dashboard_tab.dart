import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/admin/domain/entities/report_model.dart';
import 'package:petpal/features/admin/presentation/providers/admin_providers.dart';
import 'package:petpal/features/admin/presentation/widgets/admin_theme.dart';
import 'package:petpal/features/admin/presentation/widgets/global_alert_creator.dart';

/// Real-data admin dashboard: a compact KPI strip plus a "needs attention"
/// worklist merging pending verifications and open reports.
class AdminDashboardTab extends ConsumerWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider).valueOrNull;
    final verifsAsync = ref.watch(pendingVerificationsProvider);
    final reportsAsync = ref.watch(openReportsProvider);
    final verifs = verifsAsync.valueOrNull ?? const [];
    final reports = reportsAsync.valueOrNull ?? const [];

    // Prefer the live stream counts; fall back to the aggregate snapshot.
    final pendingCount =
        verifsAsync.hasValue ? verifs.length : stats?['pendingVerifications'];
    final reportsCount =
        reportsAsync.hasValue ? reports.length : stats?['openReports'];

    final work = <_WorkItem>[
      for (final v in verifs)
        _WorkItem(
          icon: Icons.verified_user_outlined,
          accent: AppColors.warning,
          title: 'בקשת אימות ספק',
          subtitle: 'משתמש ${_short(v.userId)} · ${v.documents.length} מסמכים',
          date: v.requestedAt,
          onTap: () => context.push('/admin/verification'),
        ),
      for (final r in reports)
        _WorkItem(
          icon: Icons.flag_outlined,
          accent: AppColors.error,
          title: 'דיווח על ${_reportTypeLabel(r.type)}',
          subtitle: r.reason.trim().isEmpty ? 'ללא פירוט' : r.reason.trim(),
          date: r.createdAt,
          onTap: () => context.push('/admin/moderation'),
        ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        const _SectionLabel('סקירת מערכת'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth >= 560 ? 4 : 2;
            final tileW = (c.maxWidth - (cols - 1) * 12) / cols;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _KpiTile(
                  width: tileW,
                  label: 'משתמשים',
                  value: stats?['totalUsers'],
                  icon: Icons.people_alt_outlined,
                  accent: AdminColors.accent,
                ),
                _KpiTile(
                  width: tileW,
                  label: 'אימותים ממתינים',
                  value: pendingCount,
                  icon: Icons.verified_user_outlined,
                  accent: AppColors.warning,
                  onTap: () => context.push('/admin/verification'),
                ),
                _KpiTile(
                  width: tileW,
                  label: 'נקודות עניין',
                  value: stats?['totalPois'],
                  icon: Icons.place_outlined,
                  accent: AppColors.success,
                ),
                _KpiTile(
                  width: tileW,
                  label: 'דיווחים פתוחים',
                  value: reportsCount,
                  icon: Icons.flag_outlined,
                  accent: AppColors.error,
                  onTap: () => context.push('/admin/moderation'),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            const _SectionLabel('דורש טיפול'),
            const Spacer(),
            if (work.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${work.length}',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (work.isEmpty)
          const _EmptyWork()
        else
          ...work.take(8).map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _WorklistRow(item: w),
                ),
              ),
        const SizedBox(height: 28),
        const _SectionLabel('פעולות'),
        const SizedBox(height: 12),
        const _BroadcastCard(),
      ],
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _short(String uid) => uid.length <= 6 ? uid : '${uid.substring(0, 6)}…';

String _reportTypeLabel(ReportType t) => switch (t) {
      ReportType.post => 'פוסט',
      ReportType.comment => 'תגובה',
      ReportType.user => 'משתמש',
    };

String _timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'עכשיו';
  if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} ד׳';
  if (diff.inHours < 24) return 'לפני ${diff.inHours} ש׳';
  if (diff.inDays < 7) return 'לפני ${diff.inDays} ימים';
  return '${d.day}/${d.month}';
}

// ─── Pieces ──────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text, style: AdminText.section);
}

class _KpiTile extends StatelessWidget {
  final double width;
  final String label;
  final int? value;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const _KpiTile({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AdminColors.panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdminColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 18, color: accent),
                    ),
                    const Spacer(),
                    if (onTap != null)
                      const Icon(Icons.chevron_left_rounded,
                          size: 18, color: AdminColors.inkMuted),
                  ],
                ),
                const SizedBox(height: 14),
                Text(value == null ? '—' : '$value', style: AdminText.metric),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: AdminText.rowSub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkItem {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final DateTime date;
  final VoidCallback onTap;

  const _WorkItem({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.onTap,
  });
}

class _WorklistRow extends StatelessWidget {
  final _WorkItem item;
  const _WorklistRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AdminColors.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 20, color: item.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: AdminText.rowTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: AdminText.rowSub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _timeAgo(item.date),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AdminColors.inkMuted,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_left_rounded,
                  size: 18, color: AdminColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyWork extends StatelessWidget {
  const _EmptyWork();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AdminColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 32, color: AppColors.success.withValues(alpha: 0.8)),
          const SizedBox(height: 10),
          const Text('אין משימות שדורשות טיפול', style: AdminText.rowTitle),
          const SizedBox(height: 2),
          const Text('הכול נקי כרגע — נחזור לכאן כשתיפתח משימה חדשה',
              style: AdminText.rowSub, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _BroadcastCard extends StatelessWidget {
  const _BroadcastCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => const GlobalAlertCreator(),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AdminColors.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.campaign_outlined,
                    size: 20, color: AppColors.error),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('שידור התראת חירום', style: AdminText.rowTitle),
                    SizedBox(height: 2),
                    Text(
                      'שליחת התראה לכל המשתמשים על עדכון מערכת או בעיית בטיחות',
                      style: AdminText.rowSub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_left_rounded,
                  size: 18, color: AdminColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
