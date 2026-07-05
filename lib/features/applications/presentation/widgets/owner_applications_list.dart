import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_avatar.dart';
import 'package:petpal/core/widgets/inline_error_retry.dart';
import 'package:petpal/features/applications/domain/entities/service_application.dart';
import 'package:petpal/features/applications/presentation/providers/application_provider.dart';
import 'package:petpal/features/messaging/data/datasources/messaging_datasource.dart';

/// Owner-facing list of provider offers on their request. Each pending offer can
/// be accepted (→ server creates the booking), refused with a reason, or opened
/// in chat. Reused by the walk and sitting request detail screens.
class OwnerApplicationsList extends ConsumerWidget {
  final String requestType; // 'walk' | 'sitting'
  final String requestId;

  const OwnerApplicationsList({
    super.key,
    required this.requestType,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
        requestApplicationsProvider((type: requestType, id: requestId)));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
            child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (_, __) => InlineErrorRetry(
        message: 'שגיאה בטעינת ההצעות',
        onRetry: () => ref.invalidate(
            requestApplicationsProvider((type: requestType, id: requestId))),
      ),
      data: (apps) {
        if (apps.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined,
                    size: 30, color: AppColors.textMuted.withValues(alpha: 0.6)),
                const SizedBox(height: 8),
                Text('עדיין לא התקבלו הצעות',
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('הצעות שהתקבלו (${apps.length})',
                style: AppTextStyles.headlineSm),
            const SizedBox(height: 10),
            ...apps.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ApplicationCard(application: a),
                )),
          ],
        );
      },
    );
  }
}

class _ApplicationCard extends ConsumerStatefulWidget {
  final ServiceApplication application;
  const _ApplicationCard({required this.application});

  @override
  ConsumerState<_ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends ConsumerState<_ApplicationCard> {
  bool _busy = false;

  ServiceApplication get a => widget.application;

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _accept() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('אישור הצעה'),
          content: Text(
              'לאשר את ההצעה של ${a.providerName}? תיווצר הזמנה והבקשה תיסגר לשאר המציעים.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('ביטול')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white),
              child: const Text('אשר'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(applicationDatasourceProvider).acceptApplication(
            requestType: a.requestType,
            requestId: a.requestId,
            providerUid: a.providerUid,
          );
      _snack('ההצעה אושרה ונוצרה הזמנה', success: true);
    } catch (_) {
      _snack('שגיאה באישור ההצעה, נסה שוב');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refuse() async {
    final ctrl = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('דחיית הצעה'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('אפשר לציין סיבה (יישלח למציע):'),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'סיבה (אופציונלי)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('ביטול')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white),
                child: const Text('דחה'),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => _busy = true);
      try {
        await ref.read(applicationDatasourceProvider).refuseApplication(
              requestType: a.requestType,
              requestId: a.requestId,
              providerUid: a.providerUid,
              reason: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
            );
      } catch (_) {
        _snack('שגיאה בדחיית ההצעה, נסה שוב');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _chat() async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    setState(() => _busy = true);
    try {
      final ds = MessagingDatasource(db: FirebaseFirestore.instance);
      final convoId = await ds.getOrCreateConversation(
        myUid: me.uid,
        myName: me.displayName ?? me.email ?? 'משתמש',
        otherUid: a.providerUid,
        otherName: a.providerName,
        myPhotoUrl: me.photoURL ?? '',
        otherPhotoUrl: a.providerPhotoUrl ?? '',
      );
      if (!mounted) return;
      context.push('/chat/$convoId', extra: {
        'otherName': a.providerName,
        'otherPhotoUrl': a.providerPhotoUrl,
        'otherUid': a.providerUid,
      });
    } catch (_) {
      _snack('שגיאה בפתיחת הצ׳אט');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = a.status == ApplicationStatus.pending;
    final isAccepted = a.status == ApplicationStatus.accepted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAccepted
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.border,
        ),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LiveUserAvatar(
                uid: a.providerUid,
                fallbackName: a.providerName,
                fallbackPhotoUrl: a.providerPhotoUrl,
                size: 44,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.providerName,
                        style: AppTextStyles.bodyMd
                            .copyWith(fontWeight: FontWeight.w800)),
                    if ((a.ratingCount ?? 0) > 0)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 13, color: AppColors.warning),
                          const SizedBox(width: 3),
                          Text(
                            '${a.ratingAvg!.toStringAsFixed(1)} (${a.ratingCount})',
                            style: AppTextStyles.labelSm
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (a.price != null && a.price!.isNotEmpty)
                Text(a.price!,
                    style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          // Availability
          Row(
            children: [
              Icon(
                a.availabilityConfirmed
                    ? Icons.check_circle_rounded
                    : Icons.schedule_rounded,
                size: 15,
                color: a.availabilityConfirmed
                    ? AppColors.success
                    : AppColors.warning,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  a.availabilityConfirmed
                      ? 'זמין בתאריך המבוקש'
                      : 'מועד חלופי: ${a.alternativeNote ?? ''}',
                  style: AppTextStyles.labelMd
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          if (a.experienceYears != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.workspace_premium_outlined,
                    size: 15, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('ניסיון: ${a.experienceYears} שנים',
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ],
          if (a.bio != null && a.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(a.bio!,
                style: AppTextStyles.labelMd
                    .copyWith(color: AppColors.textSecondary, height: 1.5)),
          ],
          const SizedBox(height: 12),
          if (_busy)
            const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)))
          else if (isPending) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _accept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('קבל'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _refuse,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('סרב'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _chat,
                  icon: const Icon(Icons.chat_bubble_outline_rounded,
                      color: AppColors.primary),
                ),
              ],
            ),
          ] else
            _StatusPill(status: a.status, reason: a.refusalReason),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ApplicationStatus status;
  final String? reason;
  const _StatusPill({required this.status, this.reason});

  @override
  Widget build(BuildContext context) {
    final accepted = status == ApplicationStatus.accepted;
    final color = accepted ? AppColors.success : AppColors.textMuted;
    final label = accepted ? 'נבחר' : 'נדחה';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(label,
              style: AppTextStyles.labelMd
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
        ),
        if (!accepted && reason != null && reason!.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text('סיבה: $reason',
                style: AppTextStyles.labelSm
                    .copyWith(color: AppColors.textMuted)),
          ),
        ],
      ],
    );
  }
}
