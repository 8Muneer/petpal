import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/luxury_hero.dart' show ProfileAvatarButton;
import 'package:petpal/core/widgets/notification_bell_button.dart';
import 'package:petpal/core/widgets/profile_menu.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';

/// Shared top bar used across every tab except Home (which keeps its hero).
///
/// Layout mirrors the home hero exactly: in RTL the profile avatar sits on the
/// right (leading), the screen title is centered, and the notification bell sits
/// on the left (trailing). Background matches the body surface so the bar blends
/// in, separated only by a hairline divider underneath.
///
/// Use [AppHeaderBar.sliver] inside a `CustomScrollView` for a pinned header, or
/// [AppHeaderBar] directly above a `Column`-based body.
class AppHeaderBar extends ConsumerWidget {
  /// Centered screen title (e.g. the active tab name).
  final String title;

  /// Optional small caption shown under the title.
  final String? subtitle;

  const AppHeaderBar({super.key, required this.title, this.subtitle});

  /// Height of the bar content, excluding the status-bar inset.
  static const double contentHeight = 60;

  /// A pinned sliver variant for `CustomScrollView`-based tabs.
  static Widget sliver({Key? key, required String title, String? subtitle}) {
    return _PinnedAppHeader(key: key, title: title, subtitle: subtitle);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topInset = MediaQuery.of(context).padding.top;
    return _HeaderSurface(
      topInset: topInset,
      child: _HeaderContent(title: title, subtitle: subtitle, ref: ref),
    );
  }
}

// ─── Visual surface (body color + divider) ───────────────────────────────────

class _HeaderSurface extends StatelessWidget {
  final double topInset;
  final Widget child;
  const _HeaderSurface({required this.topInset, required this.child});

  @override
  Widget build(BuildContext context) {
    // Matches the body surface so the header blends seamlessly; the hairline
    // divider is the only separation, and it keeps content hidden as it scrolls
    // beneath the pinned bar.
    return Container(
      padding: EdgeInsets.only(top: topInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SizedBox(height: AppHeaderBar.contentHeight, child: child),
    );
  }
}

// ─── Content row (avatar · title · bell) ─────────────────────────────────────

class _HeaderContent extends StatelessWidget {
  final String title;
  final String? subtitle;
  final WidgetRef ref;
  const _HeaderContent({required this.title, this.subtitle, required this.ref});

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    // Guests (logged out) get a plain title bar — no profile menu or bell, both
    // of which would only bounce them to onboarding.
    final isLoggedIn = ref.watch(authStateChangesProvider).valueOrNull != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginPage),
      child: Row(
        children: [
          // Leading (right in RTL): profile avatar + side menu.
          SizedBox(
            width: 48,
            child: isLoggedIn
                ? Center(
                    child: ProfileAvatarButton(
                      imageUrl: profile?.photoUrl,
                      name: profile?.name,
                      menuItems: profileMenuItemsForRole(
                        context,
                        profile?.role,
                        onMyServices: () => ref
                            .read(showProviderServicesProvider.notifier)
                            .state = true,
                      ),
                    ),
                  )
                : null,
          ),
          // Centered title block.
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineLg.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.primary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          // Trailing (left in RTL): chat + notification bell.
          if (isLoggedIn)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => context.push('/chat'),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.20),
                              width: 1),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                NotificationBellButton(
                  onLight: true,
                  onTap: () => context.push('/notifications'),
                ),
              ],
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ─── Pinned sliver ───────────────────────────────────────────────────────────

/// Reads the status-bar inset so the pinned header reserves space for it,
/// keeping content from sliding under the system bar when scrolled to the top.
class _PinnedAppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _PinnedAppHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _AppHeaderSliverDelegate(
        title: title,
        subtitle: subtitle,
        topInset: topInset,
      ),
    );
  }
}

class _AppHeaderSliverDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final String? subtitle;
  final double topInset;
  const _AppHeaderSliverDelegate({
    required this.title,
    required this.topInset,
    this.subtitle,
  });

  @override
  double get minExtent => AppHeaderBar.contentHeight + topInset;

  @override
  double get maxExtent => AppHeaderBar.contentHeight + topInset;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Consumer(
      builder: (context, ref, _) => _HeaderSurface(
        topInset: topInset,
        child: _HeaderContent(title: title, subtitle: subtitle, ref: ref),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _AppHeaderSliverDelegate oldDelegate) {
    return oldDelegate.title != title ||
        oldDelegate.subtitle != subtitle ||
        oldDelegate.topInset != topInset;
  }
}
