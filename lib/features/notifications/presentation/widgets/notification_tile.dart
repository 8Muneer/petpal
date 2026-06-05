import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/time_ago_text.dart';
import 'package:petpal/features/notifications/domain/entities/app_notification.dart';
import 'package:petpal/features/notifications/presentation/providers/notification_provider.dart';

class NotificationTile extends ConsumerWidget {
  final AppNotification notification;

  const NotificationTile({super.key, required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeConfig = _typeConfig(notification.type);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
        border: notification.isRead
            ? null
            : Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5),
        onTap: () async {
          if (!notification.isRead) {
            await ref
                .read(notificationActionsProvider.notifier)
                .markAsRead(notification.id);
          }
          if (context.mounted) _navigateTo(context);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TypeIcon(color: typeConfig.color, icon: typeConfig.icon),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.bodyBold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6, top: 4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  TimeAgoText(
                    createdAt: notification.createdAt,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context) {
    switch (notification.type) {
      case NotificationType.newMessage:
        final convoId = notification.conversationId;
        if (convoId != null) {
          context.push('/chat/$convoId',
              extra: {'otherName': notification.data['otherName'] ?? ''});
        }
        break;
      case NotificationType.bookingNew:
      case NotificationType.bookingAccepted:
      case NotificationType.bookingDeclined:
      case NotificationType.bookingCancelled:
      case NotificationType.newReview:
        context.push('/profile/bookings');
        break;
    }
  }

  _NotificationTypeConfig _typeConfig(NotificationType type) {
    switch (type) {
      case NotificationType.bookingNew:
        return _NotificationTypeConfig(
            icon: Icons.calendar_today_rounded, color: AppColors.primary);
      case NotificationType.bookingAccepted:
        return _NotificationTypeConfig(
            icon: Icons.check_circle_outline_rounded, color: AppColors.success);
      case NotificationType.bookingDeclined:
        return _NotificationTypeConfig(
            icon: Icons.cancel_outlined, color: AppColors.error);
      case NotificationType.bookingCancelled:
        return _NotificationTypeConfig(
            icon: Icons.event_busy_rounded, color: AppColors.warning);
      case NotificationType.newMessage:
        return _NotificationTypeConfig(
            icon: Icons.chat_bubble_outline_rounded, color: AppColors.sapphire);
      case NotificationType.newReview:
        return _NotificationTypeConfig(
            icon: Icons.star_outline_rounded, color: AppColors.warning);
    }
  }
}

class _NotificationTypeConfig {
  final IconData icon;
  final Color color;
  _NotificationTypeConfig({required this.icon, required this.color});
}

class _TypeIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _TypeIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
