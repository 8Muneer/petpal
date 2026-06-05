import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/core/theme/app_theme.dart';

/// Wraps the app entry widget to handle FCM foreground messages,
/// background-tap deep links, and cold-start notification taps.
class NotificationShell extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationShell({super.key, required this.child});

  @override
  ConsumerState<NotificationShell> createState() => _NotificationShellState();
}

class _NotificationShellState extends ConsumerState<NotificationShell> {
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  Timer? _bannerDismissTimer;

  @override
  void initState() {
    super.initState();
    _foregroundSub = ref
        .read(notificationServiceProvider)
        .onForegroundMessage
        .listen(_onForeground);

    _openedSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_onMessageTapped);

    // Handle cold-start tap (app was terminated when notification arrived).
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null && mounted) _onMessageTapped(message);
    });
  }

  @override
  void dispose() {
    _foregroundSub?.cancel();
    _openedSub?.cancel();
    _bannerDismissTimer?.cancel();
    super.dispose();
  }

  void _onForeground(RemoteMessage message) {
    if (!mounted) return;
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    if (title.isEmpty && body.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearMaterialBanners();

    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: AppColors.surface,
        dividerColor: AppColors.divider,
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, 0, 0),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title.isNotEmpty)
              Text(title,
                  style: AppTextStyles.bodyBold
                      .copyWith(color: AppColors.textPrimary)),
            if (body.isNotEmpty)
              Text(body,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              messenger.clearMaterialBanners();
              _navigateTo(message.data);
            },
            child: Text('צפה',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: messenger.clearMaterialBanners,
            child: Text('סגור',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          ),
        ],
      ),
    );

    // Auto-dismiss after 4 seconds.
    _bannerDismissTimer?.cancel();
    _bannerDismissTimer = Timer(
      const Duration(seconds: 4),
      () => messenger.clearMaterialBanners(),
    );
  }

  void _onMessageTapped(RemoteMessage message) {
    if (!mounted) return;
    _navigateTo(message.data);
  }

  void _navigateTo(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'newMessage':
        final convoId = data['conversationId'] as String?;
        if (convoId != null) {
          context.push('/chat/$convoId',
              extra: {'otherName': data['otherName'] ?? ''});
        }
        break;
      default:
        context.push('/notifications');
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
