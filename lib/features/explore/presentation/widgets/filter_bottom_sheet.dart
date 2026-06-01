import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:petpal/core/theme/app_theme.dart';

import 'package:petpal/features/sitting/presentation/providers/marketplace_provider.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late double _minPrice;
  late double _maxPrice;
  double? _minRating;
  late List<String> _selectedPetTypes;
  late List<String> _selectedServiceTypes;
  DateTime? _startDate;
  DateTime? _endDate;
  late int _petCount;

  // Custom Bronze Color from Prompt
  static const Color _bronzeColor = Color(0xFFC19A6B);
  static const Color _lightBg = Color(0xFFF9F9F7);

  @override
  void initState() {
    super.initState();
    final currentFilters = ref.read(marketplaceFiltersProvider);
    _minPrice = currentFilters.minPrice ?? 0;
    _maxPrice = currentFilters.maxPrice ?? 1000;
    _minRating = currentFilters.minRating;
    _selectedPetTypes = List.from(currentFilters.selectedPetTypes);
    _selectedServiceTypes = List.from(currentFilters.selectedServiceTypes);
    _startDate = currentFilters.startDate;
    _endDate = currentFilters.endDate;
    _petCount = currentFilters.petCount;
  }

  void _applyFilters() {
    HapticFeedback.mediumImpact();
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
    Navigator.pop(context);
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() {
      _minPrice = 0;
      _maxPrice = 1000;
      _minRating = null;
      _selectedPetTypes = [];
      _selectedServiceTypes = [];
      _startDate = null;
      _endDate = null;
      _petCount = 1;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now().add(const Duration(days: 1)));
    final firstDate = DateTime.now();
    final lastDate = DateTime.now().add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _bronzeColor,
              onPrimary: Colors.white,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
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

  @override
  Widget build(BuildContext context) {
    final isOwner = ref.watch(marketplaceFiltersProvider).showSitters;
    final resultsCount = isOwner
        ? ref.watch(filteredSittingServicesProvider).value?.length ?? 0
        : ref.watch(filteredPublicJobsProvider).value?.length ?? 0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: _lightBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _clearAll,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'נקה הכל',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Text(
                    'תסננת התוצאות',
                    style: AppTextStyles.headlineMd.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'IBM Plex Sans Arabic',
                    ),
                  ),
                  const SizedBox(width: 60), // Balance
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dates
                    _buildDatesSection(),
                    const SizedBox(height: 32),

                    // Service Types
                    _buildSectionTitle('סוג השירות'),
                    const SizedBox(height: 16),
                    _buildServiceTypeChips(),
                    const SizedBox(height: 32),

                    // Price Range
                    _buildSectionTitle('טווח מחירים (₪)'),
                    const SizedBox(height: 16),
                    _buildPriceRangeSection(),
                    const SizedBox(height: 32),

                    // Guests / Pets
                    _buildSectionTitle('מספר חיות מחמד'),
                    const SizedBox(height: 16),
                    _buildPetCountSection(),
                    const SizedBox(height: 32),
                    
                    // Rating & Pet Types
                    _buildSectionTitle('דירוג מינימלי'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildRatingChip('הכל', null),
                        const SizedBox(width: 12),
                        _buildRatingChip('4.0+', 4.0),
                        const SizedBox(width: 12),
                        _buildRatingChip('4.5+', 4.5),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Footer Apply Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [_bronzeColor, Color(0xFFD4AF37)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _bronzeColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _applyFilters,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'הצג $resultsCount תוצאות ✨',
                          style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold).copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'IBM Plex Sans Arabic',
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: AppTextStyles.bodyBold.copyWith(
        fontSize: 16,
        fontFamily: 'IBM Plex Sans Arabic',
      ),
    );
  }

  Widget _buildDatesSection() {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(child: _buildDateCard('תאריך התחלה', _startDate, true)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
        ),
        Expanded(child: _buildDateCard('תאריך סיום', _endDate, false)),
      ],
    );
  }

  Widget _buildDateCard(String label, DateTime? date, bool isStart) {
    return GestureDetector(
      onTap: () => _selectDate(context, isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.border.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  date != null ? DateFormat('dd MMM', 'he_IL').format(date) : 'בחר תאריך',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: date != null ? AppColors.onSurface : AppColors.textMuted,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.calendar_today_rounded,
              color: date != null ? _bronzeColor : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypeChips() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        _buildBoutiqueChip('הכל', null, Icons.dashboard_rounded),
        _buildBoutiqueChip('פנסיון', 'Sitting', Icons.home_rounded),
        _buildBoutiqueChip('טיול כלבים', 'Walking', Icons.directions_walk_rounded),
        _buildBoutiqueChip('שמרטפות', 'House Sitting', Icons.nightlight_round),
      ],
    );
  }

  Widget _buildBoutiqueChip(String label, String? value, IconData icon) {
    final isSelected = value == null
        ? _selectedServiceTypes.isEmpty
        : _selectedServiceTypes.contains(value);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          if (value == null) {
            _selectedServiceTypes.clear();
          } else {
            if (_selectedServiceTypes.contains(value)) {
              _selectedServiceTypes.remove(value);
            } else {
              _selectedServiceTypes.add(value);
            }
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _bronzeColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _bronzeColor : AppColors.border.withValues(alpha: 0.1),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: _bronzeColor.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMd.copyWith(
                color: isSelected ? Colors.white : AppColors.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRangeSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildPriceBox('החד המקסימלי', _maxPrice.round())),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('-', style: TextStyle(color: AppColors.textMuted)),
            ),
            Expanded(child: _buildPriceBox('החד המינימלי', _minPrice.round())),
          ],
        ),
        const SizedBox(height: 24),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 8,
            activeTrackColor: _bronzeColor,
            inactiveTrackColor: _bronzeColor.withValues(alpha: 0.2),
            thumbColor: _bronzeColor,
            overlayColor: _bronzeColor.withValues(alpha: 0.1),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
          ),
          child: RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: 1000,
            divisions: 20,
            onChanged: (values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriceBox(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value.toString(),
                style: AppTextStyles.headlineMd.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              const Text(
                '₪',
                style: TextStyle(fontSize: 16, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPetCountSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: TextDirection.rtl,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              const Icon(Icons.pets_rounded, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              Text(
                'חיות מחמד',
                style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
              ),
            ],
          ),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              _buildStepperButton(Icons.add, () {
                HapticFeedback.selectionClick();
                setState(() => _petCount++);
              }),
              SizedBox(
                width: 40,
                child: Center(
                  child: Text(
                    '$_petCount',
                    style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold).copyWith(
                      color: _bronzeColor,
                    ),
                  ),
                ),
              ),
              _buildStepperButton(Icons.remove, () {
                if (_petCount > 1) {
                  HapticFeedback.selectionClick();
                  setState(() => _petCount--);
                }
              }, enabled: _petCount > 1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton(IconData icon, VoidCallback onTap, {bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? _bronzeColor : AppColors.border.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? Colors.white : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildRatingChip(String label, double? value) {
    final isSelected = _minRating == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _minRating = value);
      },
      selectedColor: _bronzeColor,
      backgroundColor: Colors.white,
      labelStyle: AppTextStyles.bodyMd.copyWith(
        color: isSelected ? Colors.white : AppColors.onSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? _bronzeColor : AppColors.border.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}
