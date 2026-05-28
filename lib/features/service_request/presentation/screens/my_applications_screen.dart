import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/features/service_request/data/models/application_model.dart';
import 'package:petpal/features/service_request/domain/entities/application.dart';
import 'package:petpal/features/service_request/presentation/providers/service_request_provider.dart';

class MyApplicationsScreen extends ConsumerWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    final applicationsAsync = ref.watch(myApplicationsProvider(uid));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppScaffold(
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      color: AppColors.textPrimary,
                    ),
                    const Expanded(
                      child: Text(
                        'המועמדויות שלי',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Content ─────────────────────────────────────────────
              Expanded(
                child: applicationsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) =>
                      Center(child: Text('שגיאה בטעינת מועמדויות: $e')),
                  data: (apps) {
                    if (apps.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.assignment_outlined,
                                size: 64,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            const Text(
                              'לא הגשת מועמדויות עדיין',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'עיין/י בבקשות הפתוחות והגש/י מועמדות',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                          16,
                          4,
                          16,
                          MediaQuery.of(context).viewPadding.bottom + 24),
                      itemCount: apps.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) =>
                          _ApplicationCard(application: apps[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  const _ApplicationCard({required this.application});

  Color _statusColor(ApplicationStatus s) => switch (s) {
        ApplicationStatus.accepted => AppColors.success,
        ApplicationStatus.rejected => AppColors.error,
        _ => AppColors.warning,
      };

  String _statusLabel(ApplicationStatus s) => switch (s) {
        ApplicationStatus.accepted => 'התקבלת!',
        ApplicationStatus.rejected => 'נדחית',
        _ => 'ממתין',
      };

  IconData _statusIcon(ApplicationStatus s) => switch (s) {
        ApplicationStatus.accepted => Icons.check_circle_rounded,
        ApplicationStatus.rejected => Icons.cancel_rounded,
        _ => Icons.hourglass_empty_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final status = application.status;
    final statusColor = _statusColor(status);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: status + request id ────────────────────────────
          Row(
            children: [
              Icon(_statusIcon(status), size: 18, color: statusColor),
              const SizedBox(width: 6),
              Text(
                _statusLabel(status),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              if (application.createdAt != null)
                Text(
                  '${application.createdAt!.day.toString().padLeft(2, '0')}/${application.createdAt!.month.toString().padLeft(2, '0')}/${application.createdAt!.year}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          // ── Application details ────────────────────────────────────
          if (application.proposedPrice != null) ...[
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    size: 15, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'מחיר מוצע: ₪${application.proposedPrice!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          if (application.message?.isNotEmpty == true)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                application.message!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),

          // ── Accepted: prompt to chat ───────────────────────────────
          if (status == ApplicationStatus.accepted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.celebration_rounded,
                      color: AppColors.success, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'מזל טוב! בעל החיה קיבל את מועמדותך. תוכל/י לפנות אליו דרך הצ׳אט.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
