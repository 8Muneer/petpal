import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/notifications/presentation/providers/notification_provider.dart';

/// Reusable notification bell with unread badge.
/// [onLight] switches the icon/border to dark-on-light colours (for light backgrounds).
class NotificationBellButton extends ConsumerWidget {
  final VoidCallback? onTap;
  final bool onLight;

  const NotificationBellButton({super.key, this.onTap, this.onLight = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final fg = onLight ? AppColors.textPrimary : Colors.white;
    final bg = onLight
        ? AppColors.primary.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.15);
    final border = onLight
        ? AppColors.primary.withValues(alpha: 0.20)
        : Colors.white.withValues(alpha: 0.30);

    return GestureDetector(
      onTap: onTap,
      // 48dp hit target (Material minimum) around the 40dp visual circle.
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(
              unreadCount > 9 ? '9+' : '$unreadCount',
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            offset: const Offset(4, -4),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(color: border, width: 1),
              ),
              child: Icon(
                unreadCount > 0
                    ? Icons.notifications_rounded
                    : Icons.notifications_none_rounded,
                color: fg,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
