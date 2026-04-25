import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/lost_and_found/domain/entities/lost_found_post.dart';
import 'package:petpal/features/lost_and_found/presentation/providers/lost_found_provider.dart';

class LostFoundPostDetailScreen extends ConsumerStatefulWidget {
  final LostFoundPost initialPost;
  const LostFoundPostDetailScreen({super.key, required this.initialPost});

  @override
  ConsumerState<LostFoundPostDetailScreen> createState() =>
      _LostFoundPostDetailScreenState();
}

class _LostFoundPostDetailScreenState
    extends ConsumerState<LostFoundPostDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _matchCardController;
  bool _isRerunning = false;

  @override
  void initState() {
    super.initState();
    _matchCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _matchCardController.dispose();
    super.dispose();
  }

  Future<void> _rerunMatching(LostFoundPost post) async {
    setState(() => _isRerunning = true);
    final fn = ref.read(rerunMatchingProvider);
    await fn(post);
    if (mounted) setState(() => _isRerunning = false);
  }

  @override
  Widget build(BuildContext context) {
    final livePost =
        ref.watch(singlePostProvider(widget.initialPost.id)).asData?.value ??
            widget.initialPost;

    final isLost = livePost.type == LostFoundType.lost;
    final accent =
        isLost ? const Color(0xFFFB7185) : const Color(0xFF60A5FA);
    final isOwner = livePost.reporterUid == currentUserUid;
    final isSearching = livePost.matchingStatus == MatchingStatus.searching;

    // Trigger match card animation when matches arrive
    if (livePost.matches.isNotEmpty) {
      _matchCardController.forward();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: CustomScrollView(
          slivers: [
            _buildAppBar(livePost, accent),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleRow(livePost, accent),
                    const SizedBox(height: 16),
                    _buildInfoChips(livePost),
                    const SizedBox(height: 20),
                    if (livePost.description.isNotEmpty)
                      _buildDescription(livePost),
                    const SizedBox(height: 20),
                    _buildAiSection(livePost, isSearching),
                    const SizedBox(height: 20),
                    if (isOwner && livePost.status == LostFoundStatus.active)
                      _buildResolveButton(livePost),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(LostFoundPost post, Color accent) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8)
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: Color(0xFF1A1A2E)),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: CachedNetworkImage(
          imageUrl: post.imageUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
              color: const Color(0xFFF0F2F5),
              child: const Center(
                  child:
                      Icon(Icons.pets_rounded, color: Colors.grey, size: 64))),
          errorWidget: (_, __, ___) => Container(
              color: const Color(0xFFF0F2F5),
              child: const Center(
                  child:
                      Icon(Icons.pets_rounded, color: Colors.grey, size: 64))),
        ),
      ),
    );
  }

  Widget _buildTitleRow(LostFoundPost post, Color accent) {
    final isLost = post.type == LostFoundType.lost;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            isLost ? 'אבוד' : 'נמצא',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: accent, fontSize: 13),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            post.petName.isNotEmpty ? post.petName : post.species,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A2E)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChips(LostFoundPost post) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InfoChip(icon: Icons.pets_rounded, label: post.species),
        if (post.breed.isNotEmpty)
          _InfoChip(icon: Icons.info_outline_rounded, label: post.breed),
        if (post.color.isNotEmpty)
          _InfoChip(icon: Icons.palette_outlined, label: post.color),
        _InfoChip(icon: Icons.location_on_rounded, label: post.area),
      ],
    );
  }

  Widget _buildDescription(LostFoundPost post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('פרטים',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A2E))),
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
                  offset: const Offset(0, 2))
            ],
          ),
          child: Text(post.description,
              style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _buildAiSection(LostFoundPost post, bool isSearching) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded,
                color: Color(0xFF8B5CF6), size: 20),
            const SizedBox(width: 8),
            const Text('התאמות AI',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A2E))),
            if (post.matches.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${post.matches.length}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                        fontSize: 13)),
              ),
            ],
            const Spacer(),
            if (!isSearching && post.matchingStatus == MatchingStatus.done)
              _RerunButton(
                isLoading: _isRerunning,
                onTap: () => _rerunMatching(post),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOut,
          child: isSearching || _isRerunning
              ? const _SearchingIndicator(key: ValueKey('searching'))
              : post.matchingStatus == MatchingStatus.done &&
                      post.matches.isEmpty
                  ? _NoMatchesState(
                      key: const ValueKey('no-matches'),
                      post: post,
                      onRerun: () => _rerunMatching(post),
                    )
                  : post.matches.isEmpty
                      ? const _PendingState(key: ValueKey('pending'))
                      : _MatchesList(
                          key: ValueKey(post.matches.length),
                          matches: post.matches,
                          post: post,
                        ),
        ),
      ],
    );
  }

  Widget _buildResolveButton(LostFoundPost post) {
    return SizedBox(
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
                    borderRadius: BorderRadius.circular(22)),
                title: const Text('לסמן כנפתר?',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                content: const Text('הדיווח יוסר מהרשימה הפעילה.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('ביטול'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text('כן, נפתר!',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          );
          if (confirm == true && context.mounted) {
            await ref.read(markResolvedProvider)(post.id);
            if (context.mounted) context.pop();
          }
        },
        icon: const Icon(Icons.check_circle_rounded),
        label: const Text('החיה נמצאה / נפתר',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SearchingIndicator extends StatefulWidget {
  const _SearchingIndicator({super.key});

  @override
  State<_SearchingIndicator> createState() => _SearchingIndicatorState();
}

class _SearchingIndicatorState extends State<_SearchingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(const Color(0xFF8B5CF6),
                        const Color(0xFF6366F1), _pulse.value)!,
                    const Color(0xFF6366F1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6)
                        .withValues(alpha: 0.2 + _pulse.value * 0.3),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(height: 14),
          const Text('AI מחפש התאמות...',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          const Text('בודק תמונות של דיווחים אחרים',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          _DotsLoader(),
        ],
      ),
    );
  }
}

class _DotsLoader extends StatefulWidget {
  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader>
    with TickerProviderStateMixin {
  late List<AnimationController> _dots;

  @override
  void initState() {
    super.initState();
    _dots = List.generate(3, (i) {
      final c = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 500));
      Future.delayed(Duration(milliseconds: i * 160),
          () => mounted ? c.repeat(reverse: true) : null);
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _dots) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _dots[i],
          builder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 7,
            height: 7 + _dots[i].value * 7,
            decoration: BoxDecoration(
              color: Color.lerp(
                const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                const Color(0xFF8B5CF6),
                _dots[i].value,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

class _PendingState extends StatelessWidget {
  const _PendingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.hourglass_empty_rounded,
              color: Color(0xFF8B5CF6), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ממתין להתחלת חיפוש',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8B5CF6),
                        fontSize: 14)),
                SizedBox(height: 2),
                Text('ה-AI יתחיל לחפש בקרוב',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoMatchesState extends StatelessWidget {
  final LostFoundPost post;
  final VoidCallback onRerun;
  const _NoMatchesState(
      {super.key, required this.post, required this.onRerun});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded,
              color: AppColors.textMuted, size: 36),
          const SizedBox(height: 10),
          const Text('לא נמצאו התאמות כרגע',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          const Text('ה-AI לא מצא חיות דומות בדיווחים הקיימים',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRerun,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('חפש שוב',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5CF6),
                    side: const BorderSide(color: Color(0xFF8B5CF6)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/lost-found/browse', extra: post),
                  icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                  label: const Text('השווה ידנית',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MatchesList extends StatelessWidget {
  final List<LostFoundMatch> matches;
  final LostFoundPost post;
  const _MatchesList({super.key, required this.matches, required this.post});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...matches.map((match) => _MatchCard(match: match, post: post)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () =>
                context.push('/lost-found/browse', extra: post),
            icon: const Icon(Icons.compare_arrows_rounded, size: 16),
            label: const Text('השווה עם דיווחים נוספים',
                style:
                    TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B5CF6),
              side: const BorderSide(color: Color(0xFF8B5CF6)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final LostFoundMatch match;
  final LostFoundPost post;
  const _MatchCard({required this.match, required this.post});

  Color get _color {
    if (match.confidence >= 80) return const Color(0xFF10B981);
    if (match.confidence >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFFB7185);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to compare screen
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: match.imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        color: const Color(0xFFF0F2F5),
                        child: const Icon(Icons.pets_rounded,
                            color: Colors.grey)),
                    errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFF0F2F5),
                        child: const Icon(Icons.pets_rounded,
                            color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(match.reporterName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 4),
                      Text(match.reason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    Text('${match.confidence}%',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: _color)),
                    Text('התאמה',
                        style: TextStyle(fontSize: 11, color: _color)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RerunButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _RerunButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF8B5CF6)))
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded,
                      size: 14, color: Color(0xFF8B5CF6)),
                  SizedBox(width: 4),
                  Text('חפש שוב',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8B5CF6))),
                ],
              ),
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
              offset: const Offset(0, 1))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
