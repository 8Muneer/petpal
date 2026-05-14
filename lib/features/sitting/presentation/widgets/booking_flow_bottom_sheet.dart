import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_service.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart';

class BookingFlowBottomSheet extends ConsumerStatefulWidget {
  final SittingService sitter;
  final Function(DateTimeRange, Map<String, dynamic>) onConfirm;

  const BookingFlowBottomSheet({
    super.key,
    required this.sitter,
    required this.onConfirm,
  });

  @override
  ConsumerState<BookingFlowBottomSheet> createState() => _BookingFlowBottomSheetState();
}

class _BookingFlowBottomSheetState extends ConsumerState<BookingFlowBottomSheet> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  DateTimeRange? _selectedDateRange;
  Map<String, dynamic>? _selectedPet;

  // Mock pets for now
  final List<Map<String, dynamic>> _myPets = [
    {
      'name': 'קימי',
      'type': PetType.dog,
      'gender': PetGender.male,
      'imageUrl': 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?q=80&w=400',
    },
    {
      'name': 'לונא',
      'type': PetType.cat,
      'gender': PetGender.female,
      'imageUrl': 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?q=80&w=400',
    },
  ];

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          // Content
          Column(
            children: [
              const SizedBox(height: 12),
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: List.generate(3, (index) {
                    final isActive = index <= _currentStep;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : AppColors.borderFaint,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildDateStep(),
                    _buildPetStep(),
                    _buildSummaryStep(),
                  ],
                ),
              ),
              // Bottom Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: AppButton(
                          label: 'חזור',
                          variant: AppButtonVariant.secondary,
                          onTap: _prevStep,
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: _currentStep == 2 ? 'אשר הזמנה' : 'המשך',
                        onTap: ((_currentStep == 0 && _selectedDateRange == null) ||
                                    (_currentStep == 1 && _selectedPet == null)) 
                                    ? null 
                                    : () {
                          if (_currentStep == 0 && _selectedDateRange != null) {
                            _nextStep();
                          } else if (_currentStep == 1 && _selectedPet != null) {
                            _nextStep();
                          } else if (_currentStep == 2) {
                            if (_selectedDateRange != null && _selectedPet != null) {
                              widget.onConfirm(_selectedDateRange!, _selectedPet!);
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Close button
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('מתי תרצו את השירות?', style: AppTextStyles.headlineMd),
          const SizedBox(height: 8),
          Text('בחרו את טווח התאריכים הרצוי לשמירה.', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 32),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: CalendarDatePicker(
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateChanged: (date) {
                  // Simplified for now: just pick one date and we create a range of 1 day
                  setState(() {
                    _selectedDateRange = DateTimeRange(
                      start: date,
                      end: date.add(const Duration(days: 1)),
                    );
                  });
                },
              ),
            ),
          ),
          if (_selectedDateRange != null)
             Padding(
               padding: const EdgeInsets.only(top: 16),
               child: Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: AppColors.primary.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(16),
                 ),
                 child: Row(
                   children: [
                     const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                     const SizedBox(width: 12),
                     Text(
                       '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                       style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
                     ),
                   ],
                 ),
               ),
             ),
        ],
      ),
    );
  }

  Widget _buildPetStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('עבור מי ההזמנה?', style: AppTextStyles.headlineMd),
          const SizedBox(height: 8),
          Text('בחרו את חיית המחמד שלכם עבורה נדרשת השמירה.', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: _myPets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final pet = _myPets[i];
                final isSelected = _selectedPet == pet;
                return InkWell(
                  onTap: () => setState(() => _selectedPet = pet),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(pet['imageUrl']),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pet['name'], style: AppTextStyles.bodyBold),
                              Text(
                                pet['type'] == PetType.dog ? 'כלב' : 'חתול',
                                style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStep() {
    final dates = _selectedDateRange;
    if (dates == null) {
      return const Center(child: Text('נא לבחור תאריכים'));
    }

    final nights = dates.duration.inDays.clamp(1, 999);
    final pricePerNight = int.tryParse(widget.sitter.priceText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final totalPrice = nights * pricePerNight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('סיכום הזמנה', style: AppTextStyles.headlineMd),
          const SizedBox(height: 8),
          Text('בדקו את פרטי ההזמנה לפני האישור.', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 32),
          // Summary Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.subtle,
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  icon: Icons.person_rounded,
                  label: 'מטפל',
                  value: widget.sitter.providerName,
                ),
                const Divider(height: 32),
                _buildSummaryRow(
                  icon: Icons.pets_rounded,
                  label: 'חיית מחמד',
                  value: _selectedPet?['name'] ?? '',
                ),
                const Divider(height: 32),
                _buildSummaryRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'תאריכים',
                  value: '${dates.start.day}/${dates.start.month} - ${dates.end.day}/${dates.end.month}',
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('סה"כ לתשלום', style: AppTextStyles.bodyBold),
                      Text(
                        '₪$totalPrice',
                        style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Text(label, style: AppTextStyles.labelMd.copyWith(color: AppColors.textMuted)),
        const Spacer(),
        Text(value, style: AppTextStyles.bodyBold),
      ],
    );
  }
}
