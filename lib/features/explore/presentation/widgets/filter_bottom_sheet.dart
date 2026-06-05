import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/explore/presentation/providers/poi_filters_provider.dart';
import 'package:petpal/features/sitting/presentation/providers/marketplace_provider.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  final bool isOwner;

  const FilterBottomSheet({super.key, required this.isOwner});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  // ── Sitter (marketplace) state ───────────────────────────────────────────
  late double _minPrice;
  late double _maxPrice;
  late double? _minRating;
  late List<String> _selectedServiceTypes;
  late List<String> _selectedPetTypes;
  late int _petCount;
  DateTime? _startDate;
  DateTime? _endDate;

  // ── Owner (POI) state ────────────────────────────────────────────────────
  late double? _poiMinRating;
  late bool _hasReviewsOnly;

  @override
  void initState() {
    super.initState();
    if (widget.isOwner) {
      final f = ref.read(poiFiltersProvider);
      _poiMinRating = f.minRating;
      _hasReviewsOnly = f.hasReviewsOnly;
    } else {
      final f = ref.read(marketplaceFiltersProvider);
      _minPrice = f.minPrice ?? 0;
      _maxPrice = f.maxPrice ?? 1000;
      _minRating = f.minRating;
      _selectedServiceTypes = List.from(f.selectedServiceTypes);
      _selectedPetTypes = List.from(f.selectedPetTypes);
      _petCount = f.petCount;
      _startDate = f.startDate;
      _endDate = f.endDate;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _applyFilters() {
    HapticFeedback.mediumImpact();
    if (widget.isOwner) {
      ref.read(poiFiltersProvider.notifier).updateMinRating(_poiMinRating);
      ref.read(poiFiltersProvider.notifier).updateHasReviewsOnly(_hasReviewsOnly);
    } else {
      ref.read(marketplaceFiltersProvider.notifier).updateFilters(
            minPrice: _minPrice == 0 && _maxPrice == 1000 ? null : _minPrice,
            maxPrice: _minPrice == 0 && _maxPrice == 1000 ? null : _maxPrice,
            minRating: _minRating,
            selectedPetTypes: _selectedPetTypes,
            selectedServiceTypes: _selectedServiceTypes,
            startDate: _startDate,
            endDate: _endDate,
            petCount: _petCount,
          );
    }
    Navigator.pop(context);
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() {
      if (widget.isOwner) {
        _poiMinRating = null;
        _hasReviewsOnly = false;
      } else {
        _minPrice = 0;
        _maxPrice = 1000;
        _minRating = null;
        _selectedServiceTypes = [];
        _selectedPetTypes = [];
        _petCount = 1;
        _startDate = null;
        _endDate = null;
      }
    });
  }

  Future<void> _selectDate(bool isStart) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now().add(const Duration(days: 1)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: AppColors.onSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate!.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _startDate!.isAfter(_endDate!)) {
            _startDate = _endDate!.subtract(const Duration(days: 1));
          }
        }
      });
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: widget.isOwner ? 0.5 : 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Text('סינון', style: AppTextStyles.headlineSm),
                      const Spacer(),
                      TextButton(
                        onPressed: _clearAll,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'נקה הכל',
                          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),

                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    children: widget.isOwner
                        ? _buildOwnerContent()
                        : _buildSitterContent(),
                  ),
                ),

                // Apply button
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.divider)),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: AppRadius.lgRadius,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.30),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _applyFilters,
                        borderRadius: AppRadius.lgRadius,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'הצג תוצאות',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Owner content (POI filters) ──────────────────────────────────────────

  List<Widget> _buildOwnerContent() {
    return [
      _sectionTitle('דירוג מינימלי'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        children: [
          _selectableChip('הכל', _poiMinRating == null,
              () => setState(() => _poiMinRating = null)),
          _selectableChip('3.0+', _poiMinRating == 3.0,
              () => setState(() => _poiMinRating = 3.0)),
          _selectableChip('4.0+', _poiMinRating == 4.0,
              () => setState(() => _poiMinRating = 4.0)),
          _selectableChip('4.5+', _poiMinRating == 4.5,
              () => setState(() => _poiMinRating = 4.5)),
        ],
      ),
      const SizedBox(height: 24),
      const Divider(color: AppColors.divider),
      const SizedBox(height: 16),
      _sectionTitle('מסנן נוסף'),
      const SizedBox(height: 12),
      _toggleRow(
        label: 'יש ביקורות בלבד',
        value: _hasReviewsOnly,
        onChanged: (v) => setState(() => _hasReviewsOnly = v),
      ),
    ];
  }

  // ── Sitter content (marketplace filters) ─────────────────────────────────

  List<Widget> _buildSitterContent() {
    return [
      _sectionTitle('סוג שירות'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _selectableChip('הכל', _selectedServiceTypes.isEmpty,
              () => setState(() => _selectedServiceTypes.clear())),
          _selectableChip(
              'טיול כלבים',
              _selectedServiceTypes.contains('Walking'),
              () => _toggleList(_selectedServiceTypes, 'Walking')),
          _selectableChip(
              'פנסיון',
              _selectedServiceTypes.contains('Sitting'),
              () => _toggleList(_selectedServiceTypes, 'Sitting')),
          _selectableChip(
              'שמרטפות',
              _selectedServiceTypes.contains('House Sitting'),
              () => _toggleList(_selectedServiceTypes, 'House Sitting')),
        ],
      ),
      const SizedBox(height: 24),
      const Divider(color: AppColors.divider),
      const SizedBox(height: 16),

      _sectionTitle('תאריכים'),
      const SizedBox(height: 12),
      _buildDateRow(),
      const SizedBox(height: 24),
      const Divider(color: AppColors.divider),
      const SizedBox(height: 16),

      _sectionTitle('תקציב (₪)'),
      const SizedBox(height: 12),
      _buildPriceSection(),
      const SizedBox(height: 24),
      const Divider(color: AppColors.divider),
      const SizedBox(height: 16),

      _sectionTitle('סוג חיית מחמד'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _selectableChip('כלב', _selectedPetTypes.contains('כלב'),
              () => _toggleList(_selectedPetTypes, 'כלב')),
          _selectableChip('חתול', _selectedPetTypes.contains('חתול'),
              () => _toggleList(_selectedPetTypes, 'חתול')),
          _selectableChip('ציפור', _selectedPetTypes.contains('ציפור'),
              () => _toggleList(_selectedPetTypes, 'ציפור')),
          _selectableChip('ארנב', _selectedPetTypes.contains('ארנב'),
              () => _toggleList(_selectedPetTypes, 'ארנב')),
          _selectableChip('אחר', _selectedPetTypes.contains('אחר'),
              () => _toggleList(_selectedPetTypes, 'אחר')),
        ],
      ),
      const SizedBox(height: 24),
      const Divider(color: AppColors.divider),
      const SizedBox(height: 16),

      _sectionTitle('מספר חיות מחמד'),
      const SizedBox(height: 12),
      _buildPetCountStepper(),
      const SizedBox(height: 24),
      const Divider(color: AppColors.divider),
      const SizedBox(height: 16),

      _sectionTitle('דירוג מינימלי'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        children: [
          _selectableChip('הכל', _minRating == null,
              () => setState(() => _minRating = null)),
          _selectableChip('4.0+', _minRating == 4.0,
              () => setState(() => _minRating = 4.0)),
          _selectableChip('4.5+', _minRating == 4.5,
              () => setState(() => _minRating = 4.5)),
        ],
      ),
    ];
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _toggleList(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.bodyMd.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _selectableChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.border.withValues(alpha: 0.7),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMd.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _toggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textPrimary)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildDateRow() {
    return Row(
      children: [
        Expanded(child: _dateCard('תאריך התחלה', _startDate, true)),
        const SizedBox(width: 12),
        Expanded(child: _dateCard('תאריך סיום', _endDate, false)),
      ],
    );
  }

  Widget _dateCard(String label, DateTime? date, bool isStart) {
    return GestureDetector(
      onTap: () => _selectDate(isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: date != null ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.labelSm
                          .copyWith(color: AppColors.textMuted)),
                  Text(
                    date != null
                        ? DateFormat('dd MMM', 'he_IL').format(date)
                        : 'בחר תאריך',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: date != null
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
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

  Widget _buildPriceSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₪${_minPrice.round()}',
              style: AppTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            Text(
              '₪${_maxPrice.round()}',
              style: AppTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.primary.withValues(alpha: 0.15),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.10),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: 1000,
            divisions: 20,
            onChanged: (v) => setState(() {
              _minPrice = v.start;
              _maxPrice = v.end;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildPetCountStepper() {
    return Row(
      children: [
        _stepperBtn(Icons.remove_rounded, _petCount <= 1 ? null : () {
          HapticFeedback.selectionClick();
          setState(() => _petCount--);
        }),
        const SizedBox(width: 16),
        Text(
          '$_petCount',
          style: AppTextStyles.headlineSm.copyWith(color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        _stepperBtn(Icons.add_rounded, () {
          HapticFeedback.selectionClick();
          setState(() => _petCount++);
        }),
      ],
    );
  }

  Widget _stepperBtn(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.border.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18,
            color: enabled ? Colors.white : AppColors.textMuted),
      ),
    );
  }
}
