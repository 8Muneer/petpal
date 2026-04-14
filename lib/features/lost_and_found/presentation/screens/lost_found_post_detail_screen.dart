import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/lost_and_found/domain/entities/lost_found_post.dart';
import 'package:petpal/features/lost_and_found/presentation/providers/lost_found_provider.dart';

class LostFoundPostDetailScreen extends ConsumerWidget {
  final LostFoundPost post;
  const LostFoundPostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLost = post.type == LostFoundType.lost;
    final accent =
        isLost ? const Color(0xFFFB7185) : const Color(0xFF60A5FA);
    final isOwner = post.reporterUid == currentUserUid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: Color(0xFF1A1A2E)),
                ),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: CachedNetworkImage(
                  imageUrl: post.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: const Color(0xFFF0F2F5),
                    child: const Center(
                      child: Icon(Icons.pets_rounded,
                          color: Colors.grey, size: 64),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFFF0F2F5),
                    child: const Center(
                      child: Icon(Icons.pets_rounded,
                          color: Colors.grey, size: 64),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge + name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isLost ? 'אבוד' : 'נמצא',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: accent,
                                fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          post.petName.isNotEmpty
                              ? post.petName
                              : post.species,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A2E)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Info chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                            icon: Icons.pets_rounded, label: post.species),
                        if (post.breed.isNotEmpty)
                          _InfoChip(
                              icon: Icons.info_outline_rounded,
                              label: post.breed),
                        if (post.color.isNotEmpty)
                          _InfoChip(
                              icon: Icons.palette_outlined,
                              label: post.color),
                        _InfoChip(
                            icon: Icons.location_on_rounded,
                            label: post.area),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Description
                    if (post.description.isNotEmpty) ...[
                      const Text(
                        'פרטים',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1A2E)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Text(
                          post.description,
                          style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // AI Matches section
                    if (post.matches.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'התאמות AI',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A1A2E)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${post.matches.length}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF10B981),
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...post.matches.map(
                          (match) => _MatchCard(match: match)),
                      const SizedBox(height: 20),
                    ],

                    if (post.matches.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981)
                              .withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                color: Color(0xFF10B981), size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ה-AI מחפש התאמות',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF10B981),
                                        fontSize: 14),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'כשתמצא התאמה תקבל עדכון',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Resolve button (only for post owner)
                    if (isOwner &&
                        post.status == LostFoundStatus.active) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => Directionality(
                                textDirection: TextDirection.rtl,
                                child: AlertDialog(
                                  backgroundColor: Colors.white,
                                  surfaceTintColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(22)),
                                  title: const Text('לסמן כנפתר?',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w900)),
                                  content: const Text(
                                      'הדיווח יוסר מהרשימה הפעילה.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('ביטול'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                      ),
                                      child: const Text('כן, נפתר!',
                                          style: TextStyle(
                                              fontWeight:
                                                  FontWeight.w900)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              final fn =
                                  ref.read(markResolvedProvider);
                              await fn(post.id);
                              if (context.mounted) context.pop();
                            }
                          },
                          icon: const Icon(Icons.check_circle_rounded),
                          label: const Text(
                            'החיה נמצאה / נפתר',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final LostFoundMatch match;
  const _MatchCard({required this.match});

  Color get _confidenceColor {
    if (match.confidence >= 80) return const Color(0xFF10B981);
    if (match.confidence >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFFB7185);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: match.imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: const Color(0xFFF0F2F5),
                child: const Icon(Icons.pets_rounded,
                    color: Colors.grey, size: 28),
              ),
              errorWidget: (_, __, ___) => Container(
                color: const Color(0xFFF0F2F5),
                child: const Icon(Icons.pets_rounded,
                    color: Colors.grey, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.reporterName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 4),
                Text(
                  match.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(
                '${match.confidence}%',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: _confidenceColor),
              ),
              Text(
                'התאמה',
                style: TextStyle(
                    fontSize: 11, color: _confidenceColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
