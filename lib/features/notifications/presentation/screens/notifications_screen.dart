import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/empty_state_card.dart';
import 'package:petpal/features/notifications/presentation/providers/notification_provider.dart';
import 'package:petpal/features/notifications/presentation/widgets/notification_tile.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final uid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          title: Text('התראות', style: AppTextStyles.headlineSm),
          actions: [
            if (unreadCount > 0 && uid.isNotEmpty)
              TextButton(
                onPressed: () => ref
                    .read(notificationActionsProvider.notifier)
                    .markAllAsRead(uid),
                child: Text(
                  'סמן הכל כנקרא',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        body: notificationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) {
            debugPrint('[NotificationsScreen] Stream error: $e\n$st');
            return Center(
              child: Text('שגיאה בטעינת ההתראות', style: AppTextStyles.caption),
            );
          },
          data: (notifications) {
            if (notifications.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.notifications_none_rounded,
                title: 'אין התראות',
                subtitle: 'כאן יופיעו עדכונים על הזמנות, הודעות וחוות דעת',
                iconColor: AppColors.primary,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xl),
              itemCount: notifications.length,
              itemBuilder: (_, i) =>
                  NotificationTile(notification: notifications[i]),
            );
          },
        ),
      ),
    );
  }
}
