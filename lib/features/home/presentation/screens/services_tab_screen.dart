import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_service.dart';
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';
import 'package:petpal/features/walks/domain/entities/walk_request.dart';
import 'package:petpal/features/walks/domain/entities/walk_service.dart';
import 'package:petpal/features/walks/presentation/providers/walk_provider.dart';

// ─── Filter enum ──────────────────────────────────────────────────────────────

enum _ServiceFilter { all, walks, sitting }

// ─── Unified provider item ────────────────────────────────────────────────────

class _ServiceItem {
  final String id;
  final String providerName;
  final String? providerPhotoUrl;
  final String area;
  final String priceText;
  final double? rating;
  final int? reviewCount;
  final bool isWalk;
  final Object source;

  const _ServiceItem({
    required this.id,
    required this.providerName,
    this.providerPhotoUrl,
    required this.area,
    required this.priceText,
    this.rating,
    this.reviewCount,
    required this.isWalk,
    required this.source,
  });

  factory _ServiceItem.fromWalk(WalkService s) => _ServiceItem(
        id: s.id,
        providerName: s.providerName,
        providerPhotoUrl: s.providerPhotoUrl,
        area: s.area,
        priceText: s.priceText,
        rating: s.rating,
        reviewCount: s.reviewCount,
        isWalk: true,
        source: s,
      );

  factory _ServiceItem.fromSitting(SittingService s) => _ServiceItem(
        id: s.id,
        providerName: s.providerName,
        providerPhotoUrl: s.providerPhotoUrl,
        area: s.area,
        priceText: s.priceText,
        rating: s.rating,
        reviewCount: s.reviewCount,
        isWalk: false,
        source: s,
      );
}

// ─── Pet summary derived from requests ────────────────────────────────────────

class _PetSummary {
  final String name;
  final String typeLabel;
  final String? imageUrl;
  const _PetSummary({
    required this.name,
    required this.typeLabel,
    this.imageUrl,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Main widget
// ─────────────────────────────────────────────────────────────────────────────

class ServicesTabScreen extends ConsumerStatefulWidget {
  const ServicesTabScreen({super.key});

  @override
  ConsumerState<ServicesTabScreen> createState() => _ServicesTabScreenState();
}

class _ServicesTabScreenState extends ConsumerState<ServicesTabScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  _ServiceFilter _filter = _ServiceFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildTopTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ProvidersView(
                  filter: _filter,
                  onFilterChanged: (f) => setState(() => _filter = f),
                ),
                const _MyPetsAndRequestsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.subtle,
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTextStyles.labelMd.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: AppTextStyles.labelMd.copyWith(
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'ספקי שירות'),
            Tab(text: 'החיות שלי'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0 – Providers
// ─────────────────────────────────────────────────────────────────────────────

class _ProvidersView extends ConsumerWidget {
  final _ServiceFilter filter;
  final ValueChanged<_ServiceFilter> onFilterChanged;

  const _ProvidersView({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walksAsync = ref.watch(walkServicesProvider);
    final sittingAsync = ref.watch(sittingServicesProvider);

    final isLoading = walksAsync.isLoading || sittingAsync.isLoading;

    final walks = walksAsync.valueOrNull ?? [];
    final sitting = sittingAsync.valueOrNull ?? [];

    final all = [
      ...walks.where((s) => s.isActive).map(_ServiceItem.fromWalk),
      ...sitting.where((s) => s.isActive).map(_ServiceItem.fromSitting),
    ];

    final filtered = switch (filter) {
      _ServiceFilter.all => all,
      _ServiceFilter.walks => all.where((s) => s.isWalk).toList(),
      _ServiceFilter.sitting => all.where((s) => !s.isWalk).toList(),
    };

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: _FilterChipRow(
              current: filter,
              onChanged: onFilterChanged,
            ),
          ),
        ),
        if (isLoading)
          const SliverFillRemaining(
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          )
        else if (filtered.isEmpty)
          const SliverFillRemaining(child: _EmptyProviders())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 300 + (i * 70)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutCubic,
                  builder: (ctx, v, child) => Opacity(
                    opacity: v,
                    child: Transform.translate(
                        offset: Offset(0, 20 * (1 - v)), child: child),
                  ),
                  child: _ProviderCard(item: filtered[i]),
                ),
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Filter chips ─────────────────────────────────────────────────────────────

class _FilterChipRow extends StatelessWidget {
  final _ServiceFilter current;
  final ValueChanged<_ServiceFilter> onChanged;

  const _FilterChipRow({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChip(
          label: 'כולם',
          icon: Icons.apps_rounded,
          selected: current == _ServiceFilter.all,
          onTap: () => onChanged(_ServiceFilter.all),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'טיולים',
          icon: Icons.directions_walk_rounded,
          selected: current == _ServiceFilter.walks,
          onTap: () => onChanged(_ServiceFilter.walks),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'שמירה',
          icon: Icons.home_work_rounded,
          selected: current == _ServiceFilter.sitting,
          onTap: () => onChanged(_ServiceFilter.sitting),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.labelMd.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Provider card ────────────────────────────────────────────────────────────

class _ProviderCard extends StatelessWidget {
  final _ServiceItem item;
  const _ProviderCard({required this.item});

  static const _walkGreen = Color(0xFF3D8B5E);

  @override
  Widget build(BuildContext context) {
    final typeColor = item.isWalk ? _walkGreen : AppColors.primary;

    return GestureDetector(
      onTap: () => context.push(
        item.isWalk ? '/walks/create' : '/sitting/create',
        extra: item.source,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: AppRadius.organicRadius,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ProviderAvatar(
                photoUrl: item.providerPhotoUrl,
                name: item.providerName,
              ),
              const SizedBox(height: 10),
              Text(
                item.providerName,
                style: AppTextStyles.headlineSm.copyWith(fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 12, color: AppColors.primary),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      item.area,
                      style: AppTextStyles.labelMd
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isWalk
                          ? Icons.directions_walk_rounded
                          : Icons.home_work_rounded,
                      size: 11,
                      color: typeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.isWalk ? 'טיול' : 'שמירה',
                      style: AppTextStyles.labelMd.copyWith(
                        color: typeColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      item.priceText,
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.rating != null) ...[
                    const SizedBox(width: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 12, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 2),
                        Text(
                          item.rating!.toStringAsFixed(1),
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  const _ProviderAvatar({this.photoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 2),
        color: AppColors.surface,
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _Initials(initial),
              )
            : _Initials(initial),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String initial;
  const _Initials(this.initial);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: AppTextStyles.headlineSm
            .copyWith(color: AppColors.primary, fontSize: 22),
      ),
    );
  }
}

class _EmptyProviders extends StatelessWidget {
  const _EmptyProviders();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 52, color: AppColors.border),
            const SizedBox(height: 20),
            Text('אין ספקי שירות זמינים', style: AppTextStyles.headlineSm),
            const SizedBox(height: 8),
            const Text(
              'נסה לשנות את הפילטר',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 – My Pets & Requests
// ─────────────────────────────────────────────────────────────────────────────

class _MyPetsAndRequestsView extends ConsumerWidget {
  const _MyPetsAndRequestsView();

  List<_PetSummary> _derivePets(
      List<WalkRequest> walks, List<SittingRequest> sitting) {
    final seen = <String>{};
    final pets = <_PetSummary>[];
    for (final r in walks) {
      if (seen.add(r.petName)) {
        pets.add(_PetSummary(
          name: r.petName,
          typeLabel: _petLabel(r.petType),
          imageUrl: r.petImageUrl,
        ));
      }
    }
    for (final r in sitting) {
      if (seen.add(r.petName)) {
        pets.add(_PetSummary(
          name: r.petName,
          typeLabel: _petLabel(r.petType),
          imageUrl: r.petImageUrl,
        ));
      }
    }
    return pets;
  }

  String _petLabel(PetType t) => switch (t) {
        PetType.dog => 'כלב',
        PetType.cat => 'חתול',
        PetType.other => 'חיית מחמד',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walkReqs = ref.watch(walkRequestsProvider).valueOrNull ?? [];
    final sittingReqs = ref.watch(sittingRequestsProvider).valueOrNull ?? [];

    final pets = _derivePets(walkReqs, sittingReqs);

    // Merge and sort all requests by createdAt desc
    final walkItems = walkReqs.map((r) => (r.createdAt, r as Object)).toList();
    final sittingItems =
        sittingReqs.map((r) => (r.createdAt, r as Object)).toList();
    final allRequests = [...walkItems, ...sittingItems]
      ..sort((a, b) =>
          (b.$1 ?? DateTime(0)).compareTo(a.$1 ?? DateTime(0)));
    final sortedRequests = allRequests.map((e) => e.$2).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── My Pets ──────────────────────────────────────────────────────────
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: _SectionHeader(
              title: 'החיות שלי',
              icon: Icons.pets_rounded,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: pets.isEmpty
              ? const _EmptyPetsHint()
              : SizedBox(
                  height: 104,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemCount: pets.length,
                    itemBuilder: (ctx, i) => _PetCard(pet: pets[i]),
                  ),
                ),
        ),

        // ── My Requests ───────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: _SectionHeader(
              title: 'הבקשות שלי',
              icon: Icons.receipt_long_rounded,
              trailing: sortedRequests.isEmpty
                  ? null
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${sortedRequests.length}',
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        if (sortedRequests.isEmpty)
          const SliverFillRemaining(child: _EmptyRequests())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final req = sortedRequests[i];
                  Widget card;
                  if (req is WalkRequest) {
                    card = _WalkRequestCard(request: req);
                  } else if (req is SittingRequest) {
                    card = _SittingRequestCard(request: req);
                  } else {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: card,
                  );
                },
                childCount: sortedRequests.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Pet card ─────────────────────────────────────────────────────────────────

class _PetCard extends StatelessWidget {
  final _PetSummary pet;
  const _PetCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    final hasImage = pet.imageUrl != null && pet.imageUrl!.isNotEmpty;
    final initial = pet.name.isNotEmpty ? pet.name[0].toUpperCase() : '?';
    return Container(
      width: 76,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.08),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: ClipOval(
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: pet.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _Initials(initial),
                    )
                  : _Initials(initial),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              pet.name,
              style: AppTextStyles.labelMd
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          Text(
            pet.typeLabel,
            style:
                AppTextStyles.labelMd.copyWith(color: AppColors.textMuted, fontSize: 10),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _EmptyPetsHint extends StatelessWidget {
  const _EmptyPetsHint();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            const Icon(Icons.pets_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'שלח בקשת שירות כדי לראות את החיות שלך כאן',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Request cards ────────────────────────────────────────────────────────────

class _WalkRequestCard extends StatelessWidget {
  final WalkRequest request;
  const _WalkRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final date = request.preferredDate;
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : request.preferredTime;

    final (statusLabel, statusColor) = switch (request.status) {
      WalkStatus.open => ('פתוח', const Color(0xFF059669)),
      WalkStatus.taken => ('טופל', AppColors.primary),
      WalkStatus.closed => ('סגור', AppColors.textMuted),
    };

    return _BaseRequestCard(
      isWalk: true,
      petName: request.petName,
      dateText: dateStr,
      area: request.area,
      statusLabel: statusLabel,
      statusColor: statusColor,
      onTap: () => context.push('/walks/detail', extra: request),
    );
  }
}

class _SittingRequestCard extends StatelessWidget {
  final SittingRequest request;
  const _SittingRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final start = request.startDate;
    final end = request.endDate;
    final dateStr = (start != null && end != null)
        ? '${start.day}/${start.month} – ${end.day}/${end.month}'
        : (start != null ? '${start.day}/${start.month}/${start.year}' : '');

    final (statusLabel, statusColor) = switch (request.status) {
      SittingStatus.open => ('פתוח', const Color(0xFF059669)),
      SittingStatus.taken => ('טופל', AppColors.primary),
      SittingStatus.closed => ('סגור', AppColors.textMuted),
    };

    return _BaseRequestCard(
      isWalk: false,
      petName: request.petName,
      dateText: dateStr,
      area: request.area,
      statusLabel: statusLabel,
      statusColor: statusColor,
      onTap: () => context.push('/sitting/detail', extra: request),
    );
  }
}

class _BaseRequestCard extends StatelessWidget {
  final bool isWalk;
  final String petName;
  final String dateText;
  final String area;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onTap;

  const _BaseRequestCard({
    required this.isWalk,
    required this.petName,
    required this.dateText,
    required this.area,
    required this.statusLabel,
    required this.statusColor,
    required this.onTap,
  });

  static const _walkGreen = Color(0xFF3D8B5E);

  @override
  Widget build(BuildContext context) {
    final typeColor = isWalk ? _walkGreen : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: AppRadius.organicRadius,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.subtle,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isWalk
                    ? Icons.directions_walk_rounded
                    : Icons.home_work_rounded,
                color: typeColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        petName,
                        style:
                            AppTextStyles.headlineSm.copyWith(fontSize: 14),
                      ),
                      _StatusPill(
                          label: statusLabel, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        isWalk ? 'טיול' : 'שמירה',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.textMuted),
                      ),
                      if (dateText.isNotEmpty) ...[
                        const Text(' · ',
                            style:
                                TextStyle(color: AppColors.textMuted)),
                        Text(
                          dateText,
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          area,
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_left_rounded,
                color: AppColors.border, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMd.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_rounded,
                size: 52, color: AppColors.border),
            const SizedBox(height: 20),
            Text('אין בקשות עדיין', style: AppTextStyles.headlineSm),
            const SizedBox(height: 8),
            const Text(
              'כאשר תשלח בקשה לספק שירות, היא תופיע כאן',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(child: Text(title, style: AppTextStyles.headlineSm)),
        if (trailing != null) trailing!,
      ],
    );
  }
}
