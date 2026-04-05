import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';

/// User avatar with photo URL, initials fallback, and optional online dot.
class AppAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;
  final bool showOnline;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 44,
    this.showOnline = false,
    this.onTap,
    this.backgroundColor,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppColors.primaryFaint,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                placeholder: (_, __) => _Placeholder(
                  initials: _initials,
                  fontSize: size * 0.34,
                ),
                errorWidget: (_, __, ___) => _Placeholder(
                  initials: _initials,
                  fontSize: size * 0.34,
                ),
              )
            : _Placeholder(initials: _initials, fontSize: size * 0.34),
      ),
    );

    if (showOnline) {
      final dotSize = size * 0.26;
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }
}

class _Placeholder extends StatelessWidget {
  final String initials;
  final double fontSize;
  const _Placeholder({required this.initials, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryFaint,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Avatar that always streams the latest photo from Firestore for [uid].
/// Pass [fallbackName] for the initials fallback.
/// Pass [fallbackPhotoUrl] as the photo to show while the stream loads
/// (e.g. the snapshot URL stored in the document).
class LiveUserAvatar extends ConsumerWidget {
  final String uid;
  final String fallbackName;
  final String? fallbackPhotoUrl;
  final double size;
  final VoidCallback? onTap;

  const LiveUserAvatar({
    super.key,
    required this.uid,
    required this.fallbackName,
    this.fallbackPhotoUrl,
    this.size = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileStreamProvider(uid));
    final livePhotoUrl = profileAsync.asData?.value?.photoUrl;
    // Use the live URL if available, otherwise the fallback snapshot
    final photoUrl = (livePhotoUrl != null && livePhotoUrl.isNotEmpty)
        ? livePhotoUrl
        : fallbackPhotoUrl;

    return AppAvatar(
      name: fallbackName,
      photoUrl: photoUrl,
      size: size,
      onTap: onTap,
    );
  }
}
