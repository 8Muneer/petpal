import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/walks/domain/entities/walk_request.dart'
    show WalkRequest, WalkStatus, PetType, PetGender;
import 'package:petpal/features/walks/presentation/providers/walk_provider.dart'
    show walkRequestsProvider;

// ═══════════════════════════════════════════════════════════════════════════
// Walk Requests View (List / Grid)
// ═══════════════════════════════════════════════════════════════════════════

class WalkRequestsView extends ConsumerWidget {
  const WalkRequestsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(walkRequestsProvider);
    return Column(
      children: [
        // Requests list
        Expanded(
          child: requestsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(
              child: Text('שגיאה בטעינת הבקשות: $e'),
            ),
            data: (requests) {
              if (requests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_walk_rounded,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'אין בקשות טיול עדיין',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'לחץ/י על הכפתור למעלה כדי לפרסם בקשה',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.list_alt_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'הבקשות שלי (${requests.length})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewPadding.bottom + 84),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.47,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: requests.length,
                      itemBuilder: (ctx, i) => WalkRequestCard(
                        request: requests[i],
                        colorIndex: i,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Walk Request Card (compact — taps through to detail screen)
// ═══════════════════════════════════════════════════════════════════════════

class WalkRequestCard extends StatefulWidget {
  final WalkRequest request;
  final int colorIndex;
  const WalkRequestCard({super.key, required this.request, required this.colorIndex});

  @override
  State<WalkRequestCard> createState() => _WalkRequestCardState();
}

class _WalkRequestCardState extends State<WalkRequestCard> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _bgColors = [
    AppColors.sapphire, AppColors.smartBlue, AppColors.blueSlate,
    AppColors.regalNavy, AppColors.prussianBlue, AppColors.twilightIndigo,
    AppColors.prussianBlue2, AppColors.blueSlate,
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  String get _statusLabel {
    switch (widget.request.status) {
      case WalkStatus.open:   return 'פתוח';
      case WalkStatus.taken:  return 'נלקח';
      case WalkStatus.closed: return 'הושלם';
    }
  }

  Color get _statusColor {
    switch (widget.request.status) {
      case WalkStatus.open:   return AppColors.statusOpen;
      case WalkStatus.taken:  return AppColors.warning;
      case WalkStatus.closed: return AppColors.textMuted;
    }
  }

  String get _petTypeLabel {
    switch (widget.request.petType) {
      case PetType.dog: return 'כלב';
      case PetType.cat: return 'חתול';
      case PetType.other: return 'אחר';
    }
  }

  String get _genderLabel {
    if (widget.request.petGender == PetGender.male) return 'זכר';
    if (widget.request.petGender == PetGender.female) return 'נקבה';
    return '';
  }

  IconData get _fallbackIcon {
    switch (widget.request.petType) {
      case PetType.dog: return Icons.directions_walk_rounded;
      case PetType.cat: return Icons.pets_rounded;
      case PetType.other: return Icons.cruelty_free_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bgColors[widget.colorIndex % _bgColors.length];
    final images = widget.request.allImages;

    return GestureDetector(
      onTap: () => context.push('/walks/detail', extra: widget.request),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo area (carousel if multiple images)
            Expanded(
              flex: 56,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: bg),
                    if (images.isEmpty)
                      Center(child: Icon(_fallbackIcon, size: 60,
                          color: Colors.white.withValues(alpha: 0.7)))
                    else if (images.length == 1)
                      CachedNetworkImage(
                        imageUrl: images.first,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Center(child: Icon(
                            _fallbackIcon, size: 52,
                            color: Colors.white.withValues(alpha: 0.6))),
                        errorWidget: (_, __, ___) => Center(child: Icon(
                            _fallbackIcon, size: 52,
                            color: Colors.white.withValues(alpha: 0.6))),
                      )
                    else ...[
                      PageView.builder(
                        controller: _pageCtrl,
                        itemCount: images.length,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemBuilder: (_, i) => CachedNetworkImage(
                          imageUrl: images[i],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Center(child: Icon(
                              _fallbackIcon, size: 52,
                              color: Colors.white.withValues(alpha: 0.6))),
                          errorWidget: (_, __, ___) => Center(child: Icon(
                              _fallbackIcon, size: 52,
                              color: Colors.white.withValues(alpha: 0.6))),
                        ),
                      ),
                      // Dot indicators
                      Positioned(
                        bottom: 6,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (i) =>
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: i == _page ? 12 : 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: i == _page
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    // Status pill
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusLabel,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info area
            Expanded(
              flex: 44,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      widget.request.petName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    // Type + gender pills
                    Row(
                      children: [
                        _MiniPill(label: _petTypeLabel, color: AppColors.primary),
                        if (_genderLabel.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          _MiniPill(
                            label: _genderLabel,
                            color: widget.request.petGender == PetGender.female
                                ? AppColors.error
                                : AppColors.smartBlue,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Location
                    _InfoRow(icon: Icons.location_on_rounded, label: widget.request.area),
                    // Time
                    if (widget.request.preferredTime.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _InfoRow(icon: Icons.access_time_rounded, label: widget.request.preferredTime),
                    ],
                    const Spacer(),
                    // Button — always pinned to bottom
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('הצג פרטים',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11)),
                        ),
                      ),
                    ),
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

// ═══════════════════════════════════════════════════════════════════════════
// Private Helper Widgets
// ═══════════════════════════════════════════════════════════════════════════

class _MiniPill extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 11, color: AppColors.textMuted),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
          ),
        ],
      );
}
