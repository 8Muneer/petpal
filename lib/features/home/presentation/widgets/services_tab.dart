import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_avatar.dart';
import 'package:petpal/core/widgets/app_header_bar.dart';
import 'package:petpal/core/widgets/app_search_bar.dart';
import 'package:petpal/core/widgets/filter_button.dart';
import 'package:petpal/core/widgets/empty_state_card.dart';
import 'package:petpal/core/utils/price_formatter.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';
import 'package:petpal/features/messaging/data/datasources/messaging_datasource.dart';

import 'package:petpal/features/walks/domain/entities/walk_service.dart';
import 'package:petpal/features/walks/presentation/providers/walk_provider.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_service.dart';
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';

class _ServiceEntry {
  final bool isWalk;
  final WalkService? walk;
  final SittingService? sitting;

  const _ServiceEntry.walk(this.walk)
      : isWalk = true,
        sitting = null;
  const _ServiceEntry.sitting(this.sitting)
      : isWalk = false,
        walk = null;

  String get providerName =>
      isWalk ? walk!.providerName : sitting!.providerName;
  String get area => isWalk ? walk!.area : sitting!.area;
  List<String> get petTypes => isWalk ? walk!.petTypes : sitting!.petTypes;
  List<String> get availableDays =>
      isWalk ? walk!.availableDays : sitting!.availableDays;
  bool get isActive => isWalk ? walk!.isActive : sitting!.isActive;
  double? get rating => isWalk ? walk!.rating : sitting!.rating;
  int? get reviewCount => isWalk ? walk!.reviewCount : sitting!.reviewCount;
  String get priceText => isWalk ? walk!.priceText : sitting!.priceText;
  String get priceType => isWalk ? walk!.priceType : sitting!.priceType;

  double get parsedPrice {
    final cleaned = priceText.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }
}

const double _kMaxPrice = 1000.0;

class _FilterState {
  String typeFilter;
  Set<String> petTypes;
  Set<String> selectedDays;
  double minRating;
  RangeValues priceRange;
  bool activeOnly;
  bool hasReviewsOnly;
  String sortBy;

  _FilterState({
    this.typeFilter = 'הכל',
    Set<String>? petTypes,
    Set<String>? selectedDays,
    this.minRating = 0,
    this.priceRange = const RangeValues(0, _kMaxPrice),
    this.activeOnly = false,
    this.hasReviewsOnly = false,
    this.sortBy = 'ברירת מחדל',
  })  : petTypes = petTypes ?? {},
        selectedDays = selectedDays ?? {};

  _FilterState copyWith({
    String? typeFilter,
    Set<String>? petTypes,
    Set<String>? selectedDays,
    double? minRating,
    RangeValues? priceRange,
    bool? activeOnly,
    bool? hasReviewsOnly,
    String? sortBy,
  }) =>
      _FilterState(
        typeFilter: typeFilter ?? this.typeFilter,
        petTypes: petTypes ?? Set.from(this.petTypes),
        selectedDays: selectedDays ?? Set.from(this.selectedDays),
        minRating: minRating ?? this.minRating,
        priceRange: priceRange ?? this.priceRange,
        activeOnly: activeOnly ?? this.activeOnly,
        hasReviewsOnly: hasReviewsOnly ?? this.hasReviewsOnly,
        sortBy: sortBy ?? this.sortBy,
      );

  bool get isDefault =>
      typeFilter == 'הכל' &&
      petTypes.isEmpty &&
      selectedDays.isEmpty &&
      minRating == 0 &&
      priceRange.start == 0 &&
      priceRange.end == _kMaxPrice &&
      !activeOnly &&
      !hasReviewsOnly &&
      sortBy == 'ברירת מחדל';

  int get activeCount {
    int n = 0;
    if (typeFilter != 'הכל') n++;
    if (petTypes.isNotEmpty) n++;
    if (selectedDays.isNotEmpty) n++;
    if (minRating > 0) n++;
    if (priceRange.start > 0 || priceRange.end < _kMaxPrice) n++;
    if (activeOnly) n++;
    if (hasReviewsOnly) n++;
    if (sortBy != 'ברירת מחדל') n++;
    return n;
  }
}

List<_ServiceEntry> _runFilter(
  List<WalkService> walks,
  List<SittingService> sittings,
  _FilterState f,
  String query,
) {
  List<_ServiceEntry> all = [];
  if (f.typeFilter != 'שמירה') all.addAll(walks.map(_ServiceEntry.walk));
  if (f.typeFilter != 'טיולים') all.addAll(sittings.map(_ServiceEntry.sitting));

  if (f.activeOnly) all = all.where((e) => e.isActive).toList();
  if (f.hasReviewsOnly) {
    all = all.where((e) => (e.reviewCount ?? 0) > 0).toList();
  }
  if (f.petTypes.isNotEmpty) {
    all = all.where((e) => f.petTypes.any(e.petTypes.contains)).toList();
  }
  if (f.selectedDays.isNotEmpty) {
    all =
        all.where((e) => f.selectedDays.any(e.availableDays.contains)).toList();
  }
  if (f.minRating > 0) {
    all = all.where((e) => (e.rating ?? 0) >= f.minRating).toList();
  }
  final priceDefault =
      f.priceRange.start == 0 && f.priceRange.end == _kMaxPrice;
  if (!priceDefault) {
    all = all
        .where((e) =>
            e.parsedPrice >= f.priceRange.start &&
            e.parsedPrice <= f.priceRange.end)
        .toList();
  }
  if (query.isNotEmpty) {
    all = all
        .where((e) =>
            e.providerName.toLowerCase().contains(query) ||
            e.area.toLowerCase().contains(query))
        .toList();
  }
  switch (f.sortBy) {
    case 'דירוג גבוה':
      all.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    case 'מחיר נמוך':
      all.sort((a, b) => a.parsedPrice.compareTo(b.parsedPrice));
    case 'מחיר גבוה':
      all.sort((a, b) => b.parsedPrice.compareTo(a.parsedPrice));
  }
  return all;
}

class ServicesTab extends ConsumerStatefulWidget {
  const ServicesTab({super.key});

  @override
  ConsumerState<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends ConsumerState<ServicesTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _FilterState _filter = _FilterState();
  Timer? _searchDebounce;

  static const _typeFilters = ['הכל', 'טיולים', 'שמירה'];

  static const _days = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];
  static const _dayLabels = ['א׳', 'ב׳', 'ג׳', 'ד׳', 'ה׳', 'ו׳', 'ש׳'];
  static const _petOptions = ['כלב', 'חתול', 'אחר'];
  static const _sortOptions = [
    'ברירת מחדל',
    'דירוג גבוה',
    'מחיר נמוך',
    'מחיר גבוה'
  ];
  static const _ratingOptions = [3.0, 4.0, 4.5];

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openFilterSheet(
      List<WalkService> walks, List<SittingService> sittings) {
    var draft = _filter.copyWith();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (ctx, scrollCtrl) => StatefulBuilder(
            builder: (ctx, setSheet) {
              final liveCount =
                  _runFilter(walks, sittings, draft, _query).length;

              // ── helpers ──────────────────────────────────────────────────
              Widget sectionTitle(String t) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(t,
                        style: AppTextStyles.headlineSm.copyWith(fontSize: 16)),
                  );

              Widget divider() => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(color: AppColors.divider, height: 1),
                  );

              Widget filterChip(
                String label, {
                required bool selected,
                required VoidCallback onTap,
                IconData? icon,
              }) =>
                  GestureDetector(
                    onTap: onTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color:
                            selected ? AppColors.primary : AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color:
                              selected ? AppColors.primary : AppColors.border,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon,
                                size: 14,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textSecondary),
                            const SizedBox(width: 5),
                          ],
                          Text(label,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: selected
                                    ? Colors.white
                                    : AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              )),
                        ],
                      ),
                    ),
                  );

              // ── sheet body ───────────────────────────────────────────────
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    // Handle + header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('סינון ומיון',
                                  style: AppTextStyles.headlineSm),
                              GestureDetector(
                                onTap: () => Navigator.pop(ctx),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: AppColors.divider,
                                    shape: BoxShape.circle,
                                  ),
                                  child:
                                      const Icon(Icons.close_rounded, size: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: AppColors.divider, height: 1),
                        ],
                      ),
                    ),

                    // Scrollable content
                    Expanded(
                      child: ListView(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        children: [
                          // ── Service type ──────────────────────────────────
                          sectionTitle('סוג שירות'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _typeFilters.map((t) {
                              final icons = {
                                'הכל': Icons.grid_view_rounded,
                                'טיולים': Icons.directions_walk_rounded,
                                'שמירה': Icons.home_work_rounded,
                              };
                              return filterChip(t,
                                  selected: draft.typeFilter == t,
                                  icon: icons[t],
                                  onTap: () => setSheet(() =>
                                      draft = draft.copyWith(typeFilter: t)));
                            }).toList(),
                          ),

                          divider(),

                          // ── Sort ──────────────────────────────────────────
                          sectionTitle('מיון לפי'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _sortOptions.map((s) {
                              final icons = {
                                'ברירת מחדל': Icons.sort_rounded,
                                'דירוג גבוה': Icons.star_rounded,
                                'מחיר נמוך': Icons.arrow_downward_rounded,
                                'מחיר גבוה': Icons.arrow_upward_rounded,
                              };
                              return filterChip(s,
                                  selected: draft.sortBy == s,
                                  icon: icons[s],
                                  onTap: () => setSheet(
                                      () => draft = draft.copyWith(sortBy: s)));
                            }).toList(),
                          ),

                          divider(),

                          // ── Price range ───────────────────────────────────
                          sectionTitle('טווח מחירים'),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _PriceLabel('₪${draft.priceRange.start.round()}'),
                              _PriceLabel('₪${draft.priceRange.end.round()}'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SliderTheme(
                            data: SliderTheme.of(ctx).copyWith(
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: AppColors.border,
                              thumbColor: AppColors.primary,
                              overlayColor:
                                  AppColors.primary.withValues(alpha: 0.12),
                              trackHeight: 3,
                            ),
                            child: RangeSlider(
                              values: draft.priceRange,
                              min: 0,
                              max: _kMaxPrice,
                              divisions: 50,
                              onChanged: (v) => setSheet(
                                  () => draft = draft.copyWith(priceRange: v)),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('₪0', style: AppTextStyles.labelSm),
                              Text('₪${_kMaxPrice.round()}+',
                                  style: AppTextStyles.labelSm),
                            ],
                          ),

                          divider(),

                          // ── Available days ────────────────────────────────
                          sectionTitle('ימים זמינים'),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(7, (i) {
                              final day = _days[i];
                              final label = _dayLabels[i];
                              final sel = draft.selectedDays.contains(day);
                              return GestureDetector(
                                onTap: () => setSheet(() {
                                  final days =
                                      Set<String>.from(draft.selectedDays);
                                  sel ? days.remove(day) : days.add(day);
                                  draft = draft.copyWith(selectedDays: days);
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: sel
                                        ? AppColors.primary
                                        : AppColors.pureWhite,
                                    border: Border.all(
                                      color: sel
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: sel ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: sel
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                        )),
                                  ),
                                ),
                              );
                            }),
                          ),

                          divider(),

                          // ── Minimum rating ────────────────────────────────
                          sectionTitle('דירוג מינימלי'),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => setSheet(
                                    () => draft = draft.copyWith(minRating: 0)),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: draft.minRating == 0
                                        ? AppColors.primary
                                        : AppColors.pureWhite,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: draft.minRating == 0
                                          ? AppColors.primary
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Text('הכל',
                                      style: AppTextStyles.bodyMd.copyWith(
                                        color: draft.minRating == 0
                                            ? Colors.white
                                            : AppColors.onSurface,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      )),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ..._ratingOptions.map((r) {
                                final sel = draft.minRating == r;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: GestureDetector(
                                    onTap: () => setSheet(() =>
                                        draft = draft.copyWith(minRating: r)),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 160),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 9),
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? AppColors.primary
                                            : AppColors.pureWhite,
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: sel
                                              ? AppColors.primary
                                              : AppColors.border,
                                          width: sel ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star_rounded,
                                              size: 14,
                                              color: sel
                                                  ? Colors.white
                                                  : AppColors.warning),
                                          const SizedBox(width: 4),
                                          Text('$r+',
                                              style:
                                                  AppTextStyles.bodyMd.copyWith(
                                                color: sel
                                                    ? Colors.white
                                                    : AppColors.onSurface,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              )),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),

                          divider(),

                          // ── Pet type (multi-select) ────────────────────────
                          sectionTitle('סוג חיה'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _petOptions.map((p) {
                              final icons = {
                                'כלב': Icons.directions_walk_rounded,
                                'חתול': Icons.pets_rounded,
                                'אחר': Icons.cruelty_free_rounded,
                              };
                              final sel = draft.petTypes.contains(p);
                              return filterChip(p,
                                  selected: sel,
                                  icon: icons[p],
                                  onTap: () => setSheet(() {
                                        final pets =
                                            Set<String>.from(draft.petTypes);
                                        sel ? pets.remove(p) : pets.add(p);
                                        draft = draft.copyWith(petTypes: pets);
                                      }));
                            }).toList(),
                          ),

                          divider(),

                          // ── Extra options ─────────────────────────────────
                          sectionTitle('אפשרויות נוספות'),
                          _SwitchRow(
                            label: 'זמינים בלבד',
                            subtitle: 'הצג רק ספקים פעילים',
                            value: draft.activeOnly,
                            onChanged: (v) => setSheet(
                                () => draft = draft.copyWith(activeOnly: v)),
                          ),
                          const SizedBox(height: 14),
                          _SwitchRow(
                            label: 'עם ביקורות בלבד',
                            subtitle: 'הצג רק ספקים שקיבלו ביקורות',
                            value: draft.hasReviewsOnly,
                            onChanged: (v) => setSheet(() =>
                                draft = draft.copyWith(hasReviewsOnly: v)),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // Sticky bottom bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: const Border(
                            top: BorderSide(color: AppColors.divider)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.fromLTRB(
                          20, 14, 20, MediaQuery.of(ctx).padding.bottom + 14),
                      child: Row(
                        children: [
                          // Reset
                          GestureDetector(
                            onTap: () => setSheet(() => draft = _FilterState()),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.pureWhite,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text('איפוס הכל',
                                  style: AppTextStyles.bodyMd.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Show results
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _filter = draft);
                                Navigator.pop(ctx);
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    liveCount > 0
                                        ? 'הצג $liveCount שירותים'
                                        : 'אין תוצאות',
                                    style: AppTextStyles.bodyMd.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walksAsync = ref.watch(walkServicesProvider);
    final sittingAsync = ref.watch(sittingServicesProvider);

    final walks = walksAsync.asData?.value ?? <WalkService>[];
    final sittings = sittingAsync.asData?.value ?? <SittingService>[];
    final items = _runFilter(walks, sittings, _filter, _query);
    final activeCount = _filter.activeCount;

    return Column(
      children: [
        const AppHeaderBar(title: 'שירותים'),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search bar + filter button ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    FilterButton(
                      activeCount: activeCount,
                      onTap: () => _openFilterSheet(walks, sittings),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppSearchBar(
                        controller: _searchCtrl,
                        hint: 'חפש/י לפי שם או אזור...',
                        onChanged: (v) {
                          _searchDebounce?.cancel();
                          _searchDebounce = Timer(
                            const Duration(milliseconds: 280),
                            () =>
                                setState(() => _query = v.trim().toLowerCase()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ── Active filter removable chips ─────────────────────────────────
              if (!_filter.isDefault) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (_filter.typeFilter != 'הכל')
                        _ActiveChip(
                            label: _filter.typeFilter,
                            onRemove: () => setState(() =>
                                _filter = _filter.copyWith(typeFilter: 'הכל'))),
                      if (_filter.minRating > 0)
                        _ActiveChip(
                            label: '★ ${_filter.minRating}+',
                            onRemove: () => setState(() =>
                                _filter = _filter.copyWith(minRating: 0))),
                      if (_filter.priceRange.start > 0 ||
                          _filter.priceRange.end < 500)
                        _ActiveChip(
                            label:
                                '₪${_filter.priceRange.start.round()}–₪${_filter.priceRange.end.round()}',
                            onRemove: () => setState(() => _filter =
                                _filter.copyWith(
                                    priceRange: const RangeValues(0, 500)))),
                      if (_filter.selectedDays.isNotEmpty)
                        _ActiveChip(
                            label: _filter.selectedDays.join(' '),
                            onRemove: () => setState(() =>
                                _filter = _filter.copyWith(selectedDays: {}))),
                      for (final p in _filter.petTypes)
                        _ActiveChip(
                            label: p,
                            onRemove: () => setState(() {
                                  final s = Set<String>.from(_filter.petTypes)
                                    ..remove(p);
                                  _filter = _filter.copyWith(petTypes: s);
                                })),
                      if (_filter.activeOnly)
                        _ActiveChip(
                            label: 'זמינים',
                            onRemove: () => setState(() =>
                                _filter = _filter.copyWith(activeOnly: false))),
                      if (_filter.hasReviewsOnly)
                        _ActiveChip(
                            label: 'עם ביקורות',
                            onRemove: () => setState(() => _filter =
                                _filter.copyWith(hasReviewsOnly: false))),
                      if (_filter.sortBy != 'ברירת מחדל')
                        _ActiveChip(
                            label: _filter.sortBy,
                            onRemove: () => setState(() => _filter =
                                _filter.copyWith(sortBy: 'ברירת מחדל'))),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // ── Unified grid ──────────────────────────────────────────────────
              Expanded(
                child: Builder(builder: (_) {
                  if (walksAsync.isLoading || sittingAsync.isLoading) {
                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 0, 16,
                          MediaQuery.of(context).viewPadding.bottom + 84),
                      itemCount: 3,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: 14),
                        child: _ProviderCardSkeleton(),
                      ),
                    );
                  }
                  if (walksAsync.hasError || sittingAsync.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off_rounded,
                              size: 48,
                              color:
                                  AppColors.textMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('שגיאה בטעינת השירותים',
                              style: AppTextStyles.headlineSm
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }
                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 52,
                                color:
                                    AppColors.textMuted.withValues(alpha: 0.4)),
                            const SizedBox(height: 14),
                            Text(
                              'לא נמצאו ספקים עם הסינון הנוכחי',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.headlineSm
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _filter = _FilterState()),
                              child: Text(
                                'נקה סינון',
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 0, 16,
                        MediaQuery.of(context).viewPadding.bottom + 84),
                    itemCount: items.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ProviderCard(entry: items[i]),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceLabel extends StatelessWidget {
  final String text;
  const _PriceLabel(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w800)),
      );
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.bodyMd
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.labelMd),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
            onChanged: onChanged,
          ),
        ],
      );
}

class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close_rounded,
                    size: 13, color: AppColors.primary),
              ),
            ],
          ),
        ),
      );
}

class WalkServicesView extends ConsumerStatefulWidget {
  const WalkServicesView({super.key});

  @override
  ConsumerState<WalkServicesView> createState() => _WalkServicesViewState();
}

class _WalkServicesViewState extends ConsumerState<WalkServicesView> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'הכל';

  static const _filters = ['הכל', 'כלב', 'חתול', 'אחר'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(walkServicesProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: AppSearchBar(
            controller: _searchCtrl,
            hint: 'חפש/י ספק טיולים...',
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),

        // Filter chips
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => _FilterChip(
              label: _filters[i],
              selected: _filter == _filters[i],
              onTap: () => setState(() => _filter = _filters[i]),
            ),
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: servicesAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => const Center(
              child: Text('שגיאה בטעינת השירותים',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            data: (all) {
              final services = all.where((s) {
                final matchFilter =
                    _filter == 'הכל' || s.petTypes.contains(_filter);
                final matchQuery = _query.isEmpty ||
                    s.providerName.toLowerCase().contains(_query) ||
                    s.area.toLowerCase().contains(_query);
                return matchFilter && matchQuery;
              }).toList();

              if (services.isEmpty) {
                return const Center(
                  child: EmptyStateWidget(
                    title: 'אין שירותי טיולים',
                    subtitle: 'נסה/י לשנות את הסינון',
                    icon: Icons.directions_walk_rounded,
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.58,
                ),
                itemCount: services.length,
                itemBuilder: (_, i) => _WalkServiceCard(service: services[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SittingServicesView extends ConsumerStatefulWidget {
  const SittingServicesView({super.key});

  @override
  ConsumerState<SittingServicesView> createState() =>
      _SittingServicesViewState();
}

class _SittingServicesViewState extends ConsumerState<SittingServicesView> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'הכל';

  static const _filters = ['הכל', 'כלב', 'חתול', 'אחר'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(sittingServicesProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: AppSearchBar(
            controller: _searchCtrl,
            hint: 'חפש/י ספק שמירה...',
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),

        // Filter chips
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => _FilterChip(
              label: _filters[i],
              selected: _filter == _filters[i],
              onTap: () => setState(() => _filter = _filters[i]),
            ),
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: servicesAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.sitting)),
            error: (e, _) => Center(child: Text('שגיאה: $e')),
            data: (all) {
              final services = all.where((s) {
                final matchFilter =
                    _filter == 'הכל' || s.petTypes.contains(_filter);
                final matchQuery = _query.isEmpty ||
                    s.providerName.toLowerCase().contains(_query) ||
                    s.area.toLowerCase().contains(_query);
                return matchFilter && matchQuery;
              }).toList();

              if (services.isEmpty) {
                return const Center(
                  child: EmptyStateWidget(
                    title: 'אין שירותי שמירה',
                    subtitle: 'נסה/י לשנות את הסינון',
                    icon: Icons.home_work_rounded,
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.58,
                ),
                itemCount: services.length,
                itemBuilder: (_, i) =>
                    _SittingServiceCard(service: services[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SittingServiceCard extends ConsumerWidget {
  final SittingService service;
  const _SittingServiceCard({required this.service});

  void _showDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SittingServiceDetailSheet(service: service, ref: ref),
    );
  }

  Future<void> _startChat(BuildContext context, WidgetRef ref) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    final myProfile = ref.read(currentUserProfileProvider).asData?.value;
    final myPhotoUrl = myProfile?.photoUrl ?? me.photoURL ?? '';
    final providerPhotoUrl = service.providerPhotoUrl ?? '';
    final ds = MessagingDatasource(db: FirebaseFirestore.instance);
    final convoId = await ds.getOrCreateConversation(
      myUid: me.uid,
      myName: me.displayName ?? me.email ?? 'משתמש',
      otherUid: service.providerUid,
      otherName: service.providerName,
      myPhotoUrl: myPhotoUrl,
      otherPhotoUrl: providerPhotoUrl,
    );
    if (context.mounted) {
      context.push('/chat/$convoId', extra: {
        'otherName': service.providerName,
        'otherPhotoUrl': providerPhotoUrl,
        'otherUid': service.providerUid,
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const accent = AppColors.primary;
    final displayPrice = formatPrice(service.priceText, service.priceType);

    return GestureDetector(
      onTap: () => _showDetail(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Photo / avatar area ──────────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (service.providerPhotoUrl != null &&
                        service.providerPhotoUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: service.providerPhotoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.surface,
                                AppColors.twilightIndigo
                              ],
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.surface,
                                AppColors.twilightIndigo
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.home_work_rounded,
                                size: 48, color: AppColors.twilightIndigo),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.surface,
                              AppColors.twilightIndigo
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.home_work_rounded,
                              size: 48, color: AppColors.twilightIndigo),
                        ),
                      ),
                    if (service.isActive)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.statusOpen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'זמין',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // ── Info area ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    service.providerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (service.rating != null)
                    _RatingRow(
                        rating: service.rating!,
                        reviewCount: service.reviewCount)
                  else if (service.createdAt != null)
                    Text(
                      _timeAgo(service.createdAt!),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted),
                    ),
                  const SizedBox(height: 4),
                  const Text(
                    'שמירה',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    displayPrice,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniChip(
                          icon: Icons.location_on_rounded,
                          label: service.area,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _MiniChip(
                          icon: Icons.home_work_rounded,
                          label: service.sittingLocation,
                          color: AppColors.smartBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _startChat(context, ref),
                    child: SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded,
                                  color: Colors.white, size: 13),
                              SizedBox(width: 5),
                              Text('צור קשר',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return 'לפני פחות משעה';
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return 'לפני ${h == 1 ? 'שעה' : '$h שעות'}';
  }
  final d = diff.inDays;
  if (d == 1) return 'לפני יום';
  if (d < 30) return 'לפני $d ימים';
  final m = (d / 30).floor();
  if (m == 1) return 'לפני חודש';
  if (m < 12) return 'לפני $m חודשים';
  final y = (d / 365).floor();
  return 'לפני ${y == 1 ? 'שנה' : '$y שנים'}';
}

class _WalkServiceCard extends ConsumerWidget {
  final WalkService service;
  const _WalkServiceCard({required this.service});

  void _showDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WalkServiceDetailSheet(service: service, ref: ref),
    );
  }

  Future<void> _startChat(BuildContext context, WidgetRef ref) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    final myProfile = ref.read(currentUserProfileProvider).asData?.value;
    final myPhotoUrl = myProfile?.photoUrl ?? me.photoURL ?? '';
    final providerPhotoUrl = service.providerPhotoUrl ?? '';
    final ds = MessagingDatasource(db: FirebaseFirestore.instance);
    final convoId = await ds.getOrCreateConversation(
      myUid: me.uid,
      myName: me.displayName ?? me.email ?? 'משתמש',
      otherUid: service.providerUid,
      otherName: service.providerName,
      myPhotoUrl: myPhotoUrl,
      otherPhotoUrl: providerPhotoUrl,
    );
    if (context.mounted) {
      context.push('/chat/$convoId', extra: {
        'otherName': service.providerName,
        'otherPhotoUrl': providerPhotoUrl,
        'otherUid': service.providerUid,
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayPrice = formatPrice(service.priceText, service.priceType);

    return GestureDetector(
      onTap: () => _showDetail(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Photo / avatar area ──────────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (service.providerPhotoUrl != null &&
                        service.providerPhotoUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: service.providerPhotoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFCCFBF1), Color(0xFF99F6E4)],
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFCCFBF1), Color(0xFF99F6E4)],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.directions_walk_rounded,
                                size: 48, color: Color(0xFF99F6E4)),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFCCFBF1), Color(0xFF99F6E4)],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.directions_walk_rounded,
                              size: 48, color: Color(0xFF99F6E4)),
                        ),
                      ),
                    if (service.isActive)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.statusOpen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'זמין',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // ── Info area ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    service.providerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (service.rating != null)
                    _RatingRow(
                        rating: service.rating!,
                        reviewCount: service.reviewCount)
                  else if (service.createdAt != null)
                    Text(
                      _timeAgo(service.createdAt!),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted),
                    ),
                  const SizedBox(height: 4),
                  const Text(
                    'טיול',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    displayPrice,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniChip(
                          icon: Icons.location_on_rounded,
                          label: service.area,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _MiniChip(
                          icon: Icons.timer_rounded,
                          label: service.duration,
                          color: AppColors.smartBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _startChat(context, ref),
                    child: SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded,
                                  color: Colors.white, size: 13),
                              SizedBox(width: 5),
                              Text('צור קשר',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  const _RatingRow({required this.rating, this.reviewCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: 3),
          Text(
            '($reviewCount)',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _SittingServiceDetailSheet extends ConsumerStatefulWidget {
  final SittingService service;
  final WidgetRef ref;
  const _SittingServiceDetailSheet({required this.service, required this.ref});
  @override
  ConsumerState<_SittingServiceDetailSheet> createState() =>
      _SittingServiceDetailSheetState();
}

class _SittingServiceDetailSheetState
    extends ConsumerState<_SittingServiceDetailSheet> {
  bool _loading = false;

  Future<void> _startChat() async {
    setState(() => _loading = true);
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    final myProfile = ref.read(currentUserProfileProvider).asData?.value;
    final myPhotoUrl = myProfile?.photoUrl ?? me.photoURL ?? '';
    final providerPhotoUrl = widget.service.providerPhotoUrl ?? '';
    final ds = MessagingDatasource(db: FirebaseFirestore.instance);
    final convoId = await ds.getOrCreateConversation(
      myUid: me.uid,
      myName: me.displayName ?? me.email ?? 'משתמש',
      otherUid: widget.service.providerUid,
      otherName: widget.service.providerName,
      myPhotoUrl: myPhotoUrl,
      otherPhotoUrl: providerPhotoUrl,
    );
    if (mounted) {
      Navigator.pop(context);
      context.push('/chat/$convoId', extra: {
        'otherName': widget.service.providerName,
        'otherPhotoUrl': providerPhotoUrl,
        'otherUid': widget.service.providerUid,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.primary;
    final s = widget.service;
    final displayPrice = formatPrice(s.priceText, s.priceType);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    LiveUserAvatar(
                      uid: s.providerUid,
                      fallbackName: s.providerName,
                      fallbackPhotoUrl: s.providerPhotoUrl,
                      size: 56,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.providerName,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          const Text('שירות שמירה',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    if (s.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.statusOpen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('זמין',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined,
                          size: 18, color: accent),
                      const SizedBox(width: 8),
                      const Text('מחיר:  ',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: accent)),
                      Text(displayPrice,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: accent)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _DetailInfoRow(
                    icon: Icons.location_on_rounded,
                    label: 'אזור',
                    value: s.area,
                    color: AppColors.error),
                _DetailInfoRow(
                    icon: Icons.home_work_rounded,
                    label: 'מיקום השמירה',
                    value: s.sittingLocation,
                    color: AppColors.smartBlue),
                if (s.petTypes.isNotEmpty)
                  _DetailInfoRow(
                      icon: Icons.pets_rounded,
                      label: 'סוגי חיות',
                      value: s.petTypes.join(', '),
                      color: AppColors.success),
                if (s.availableDays.isNotEmpty)
                  _DetailInfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'ימים זמינים',
                      value: s.availableDays.join(', '),
                      color: AppColors.regalNavy),
                if (s.rating != null)
                  _DetailInfoRow(
                      icon: Icons.star_rounded,
                      label: 'דירוג',
                      value:
                          '${s.rating!.toStringAsFixed(1)}  (${s.reviewCount ?? 0} ביקורות)',
                      color: AppColors.warning),
                if (s.bio != null && s.bio!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: AppColors.warning),
                          SizedBox(width: 6),
                          Text('אודות',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.warning)),
                        ]),
                        const SizedBox(height: 8),
                        Text(s.bio!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.6)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _loading ? null : _startChat,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(colors: [
                              AppColors.primary,
                              AppColors.blueSlate
                            ]),
                            boxShadow: [
                              BoxShadow(
                                  color: accent.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5))
                            ],
                          ),
                          child: Center(
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.chat_bubble_outline_rounded,
                                          color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text('צור קשר',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/bookings/create', extra: {
                            'providerUid': widget.service.providerUid,
                            'providerName': widget.service.providerName,
                            'providerPhotoUrl': widget.service.providerPhotoUrl,
                            'serviceId': widget.service.id,
                            'serviceType': 'sitting',
                            'priceText': widget.service.priceText,
                          });
                        },
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5))
                            ],
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_month_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('הזמן עכשיו',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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

class _WalkServiceDetailSheet extends ConsumerStatefulWidget {
  final WalkService service;
  final WidgetRef ref;
  const _WalkServiceDetailSheet({required this.service, required this.ref});
  @override
  ConsumerState<_WalkServiceDetailSheet> createState() =>
      _WalkServiceDetailSheetState();
}

class _WalkServiceDetailSheetState
    extends ConsumerState<_WalkServiceDetailSheet> {
  bool _loading = false;

  Future<void> _startChat() async {
    setState(() => _loading = true);
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    final myProfile = ref.read(currentUserProfileProvider).asData?.value;
    final myPhotoUrl = myProfile?.photoUrl ?? me.photoURL ?? '';
    final providerPhotoUrl = widget.service.providerPhotoUrl ?? '';
    final ds = MessagingDatasource(db: FirebaseFirestore.instance);
    final convoId = await ds.getOrCreateConversation(
      myUid: me.uid,
      myName: me.displayName ?? me.email ?? 'משתמש',
      otherUid: widget.service.providerUid,
      otherName: widget.service.providerName,
      myPhotoUrl: myPhotoUrl,
      otherPhotoUrl: providerPhotoUrl,
    );
    if (mounted) {
      Navigator.pop(context);
      context.push('/chat/$convoId', extra: {
        'otherName': widget.service.providerName,
        'otherPhotoUrl': providerPhotoUrl,
        'otherUid': widget.service.providerUid,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final displayPrice = formatPrice(s.priceText, s.priceType);
    const accent = AppColors.primary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    LiveUserAvatar(
                      uid: s.providerUid,
                      fallbackName: s.providerName,
                      fallbackPhotoUrl: s.providerPhotoUrl,
                      size: 56,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.providerName,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          const Text('שירות טיולים',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    if (s.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.statusOpen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('זמין',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined,
                          size: 18, color: accent),
                      const SizedBox(width: 8),
                      const Text('מחיר:  ',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: accent)),
                      Text(displayPrice,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: accent)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _DetailInfoRow(
                    icon: Icons.location_on_rounded,
                    label: 'אזור',
                    value: s.area,
                    color: AppColors.error),
                _DetailInfoRow(
                    icon: Icons.timer_rounded,
                    label: 'משך הטיול',
                    value: s.duration,
                    color: accent),
                if (s.petTypes.isNotEmpty)
                  _DetailInfoRow(
                      icon: Icons.pets_rounded,
                      label: 'סוגי חיות',
                      value: s.petTypes.join(', '),
                      color: AppColors.success),
                if (s.availableDays.isNotEmpty)
                  _DetailInfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'ימים זמינים',
                      value: s.availableDays.join(', '),
                      color: AppColors.regalNavy),
                if (s.rating != null)
                  _DetailInfoRow(
                      icon: Icons.star_rounded,
                      label: 'דירוג',
                      value:
                          '${s.rating!.toStringAsFixed(1)}  (${s.reviewCount ?? 0} ביקורות)',
                      color: AppColors.warning),
                if (s.bio != null && s.bio!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: AppColors.warning),
                          SizedBox(width: 6),
                          Text('אודות',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.warning)),
                        ]),
                        const SizedBox(height: 8),
                        Text(s.bio!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.6)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _loading ? null : _startChat,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(colors: [
                              AppColors.primary,
                              AppColors.statusOpen
                            ]),
                            boxShadow: [
                              BoxShadow(
                                  color: accent.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5))
                            ],
                          ),
                          child: Center(
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.chat_bubble_outline_rounded,
                                          color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text('צור קשר',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/bookings/create', extra: {
                            'providerUid': widget.service.providerUid,
                            'providerName': widget.service.providerName,
                            'providerPhotoUrl': widget.service.providerPhotoUrl,
                            'serviceId': widget.service.id,
                            'serviceType': 'walk',
                            'priceText': widget.service.priceText,
                          });
                        },
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5))
                            ],
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_month_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('הזמן עכשיו',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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

class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.65))),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      );
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Horizontal card for ServicesTab ──────────────────────────────────────────

class _ProviderCard extends StatelessWidget {
  final _ServiceEntry entry;

  const _ProviderCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final photo = entry.isWalk
        ? entry.walk?.providerPhotoUrl
        : entry.sitting?.providerPhotoUrl;
    final name = entry.providerName;
    final area = entry.area;
    final displayPrice = formatPrice(entry.priceText, entry.priceType);
    final rating = entry.rating;
    final reviewCount = entry.reviewCount;
    final isActive = entry.isActive;
    final isWalk = entry.isWalk;
    final detail =
        isWalk ? entry.walk!.duration : entry.sitting!.sittingLocation;

    return GestureDetector(
      onTap: () {
        if (isWalk) {
          context.push('/services/provider/walk', extra: entry.walk);
        } else {
          context.push('/services/provider/sitting', extra: entry.sitting);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Photo + info row ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: (photo != null && photo.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: photo,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _CardPhotoPlaceholder(
                                  name: name, isWalk: isWalk),
                              errorWidget: (_, __, ___) =>
                                  _CardPhotoPlaceholder(
                                      name: name, isWalk: isWalk),
                            )
                          : _CardPhotoPlaceholder(name: name, isWalk: isWalk),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + available badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isActive) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.statusOpen,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'זמין',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Service type
                        Text(
                          isWalk ? 'טיול' : 'שמירה',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        // Info chips
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            _MiniChip(
                                icon: Icons.location_on_rounded,
                                label: area,
                                color: AppColors.error),
                            _MiniChip(
                              icon: isWalk
                                  ? Icons.timer_rounded
                                  : Icons.home_work_rounded,
                              label: detail,
                              color: AppColors.primary,
                            ),
                            if (rating != null)
                              _MiniChip(
                                icon: Icons.star_rounded,
                                label: rating.toStringAsFixed(1) +
                                    (reviewCount != null
                                        ? ' ($reviewCount)'
                                        : ''),
                                color: AppColors.warning,
                              ),
                          ],
                        ),
                        if (entry.availableDays.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _AvailabilityDotRow(days: entry.availableDays),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Price + CTA ───────────────────────────────────────────────
            Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Row(
                children: [
                  Text(
                    displayPrice,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const SizedBox(
                        height: 44,
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded,
                                  color: Colors.white, size: 15),
                              SizedBox(width: 6),
                              Text(
                                'צור קשר',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardPhotoPlaceholder extends StatelessWidget {
  final String name;
  final bool isWalk;

  const _CardPhotoPlaceholder({required this.name, required this.isWalk});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isWalk ? AppColors.prussianBlue : AppColors.regalNavy,
      child: Center(
        child: Text(
          name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
          style: GoogleFonts.frankRuhlLibre(
            fontSize: 64,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }
}

class _AvailabilityDotRow extends StatelessWidget {
  final List<String> days;
  static const _allDays = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];

  const _AvailabilityDotRow({required this.days});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.calendar_today_outlined,
            size: 12, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Row(
          children: _allDays.map((d) {
            final active = days.contains(d);
            return Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: active ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ProviderCardSkeleton extends StatelessWidget {
  const _ProviderCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 16,
                          width: 120,
                          decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(8))),
                      const SizedBox(height: 8),
                      Container(
                          height: 12,
                          width: 60,
                          decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(6))),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                              height: 22,
                              width: 70,
                              decoration: BoxDecoration(
                                  color: AppColors.divider,
                                  borderRadius: BorderRadius.circular(11))),
                          const SizedBox(width: 6),
                          Container(
                              height: 22,
                              width: 60,
                              decoration: BoxDecoration(
                                  color: AppColors.divider,
                                  borderRadius: BorderRadius.circular(11))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                Container(
                    height: 20,
                    width: 60,
                    decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(8))),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceCard,
          borderRadius: AppRadius.fullRadius,
          boxShadow: selected ? null : AppShadows.subtle,
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
