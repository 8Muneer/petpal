import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/features/profile/presentation/providers/sitter_availability_state.dart';
import 'package:petpal/features/profile/presentation/widgets/bento_calendar.dart';
import 'package:petpal/features/profile/presentation/widgets/service_toggles_card.dart';

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  DateTime _currentMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sitterAvailabilityProvider);
    final notifier = ref.read(sitterAvailabilityProvider.notifier);

    return AppScaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Top Bar
                    _buildTopBar(context),
                    
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // Global Toggle
                          _buildGlobalToggle(state, notifier),
                          
                          const SizedBox(height: 24),
                          
                          // Master Calendar
                          BentoCalendar(
                            currentMonth: _currentMonth,
                            isDateAvailable: (date) => notifier.isDateAvailable(date),
                            onDateTap: (date) => notifier.toggleDate(date),
                            onPreviousMonth: () => setState(() {
                              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                            }),
                            onNextMonth: () => setState(() {
                              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                            }),
                            onTodayTap: () => setState(() {
                              _currentMonth = DateTime.now();
                            }),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Service Toggles
                          ServiceTogglesCard(
                            serviceAvailability: state.serviceAvailability,
                            onToggle: (key) => notifier.toggleService(key),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Weekly Pattern Summary
                          _buildWeeklyPatternCard(state, notifier),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AppButton(
          label: 'שמירת כל השינויים',
          leadingIcon: Icons.check_rounded,
          isLoading: state.isSaving,
          onTap: () async {
            final success = await notifier.save();
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('הזמינות עודכנה בהצלחה! ✨'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.all(16),
                ),
              );
              context.pop();
            }
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderFaint),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ניהול זמינות', style: AppTextStyles.h2),
              Text('Mission Control / Availability', 
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalToggle(SitterAvailabilityState state, SitterAvailabilityNotifier notifier) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      color: state.isAvailable ? AppColors.successLight.withOpacity(0.3) : Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: state.isAvailable ? AppColors.success : AppColors.borderFaint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.bolt_rounded,
              color: state.isAvailable ? Colors.white : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('מצב פעיל', style: AppTextStyles.bodyBold),
                Text(
                  state.isAvailable ? 'מקבל/ת בקשות חדשות' : 'לא מופיע/ת בחיפוש',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: state.isAvailable,
            onChanged: (v) => notifier.toggleGlobal(v),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyPatternCard(SitterAvailabilityState state, SitterAvailabilityNotifier notifier) {
    const days = ['א׳', 'ב׳', 'ג׳', 'ד׳', 'ה׳', 'ו׳', 'ש׳'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'זמינות שבועית קבועה',
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final active = state.availableDays[i];
            return GestureDetector(
              onTap: () => notifier.toggleDay(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    days[i],
                    style: AppTextStyles.label.copyWith(
                      color: active ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
