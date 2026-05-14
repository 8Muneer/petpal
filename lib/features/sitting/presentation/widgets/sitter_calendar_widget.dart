import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

class SitterCalendarWidget extends StatelessWidget {
  final List<DateTime> availableDates;
  final DateTime currentMonth;

  const SitterCalendarWidget({
    super.key,
    required this.availableDates,
    required this.currentMonth,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    
    final int emptySlots = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    final int totalDays = lastDayOfMonth.day;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.borderFaint.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'זמינות השומר',
            style: AppTextStyles.h2.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DayHeader(text: 'א׳'),
              _DayHeader(text: 'ב׳'),
              _DayHeader(text: 'ג׳'),
              _DayHeader(text: 'ד׳'),
              _DayHeader(text: 'ה׳'),
              _DayHeader(text: 'ו׳'),
              _DayHeader(text: 'ש׳'),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: emptySlots + totalDays,
            itemBuilder: (context, index) {
              if (index < emptySlots) return const SizedBox.shrink();
              
              final day = index - emptySlots + 1;
              final date = DateTime(currentMonth.year, currentMonth.month, day);
              final isAvailable = availableDates.any((d) => 
                d.year == date.year && d.month == date.month && d.day == date.day);
              
              return _CalendarDay(
                day: day,
                isAvailable: isAvailable,
              );
            },
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              _LegendItem(color: AppColors.primary, label: 'זמין'),
              SizedBox(width: 16),
              _LegendItem(color: AppColors.borderFaint, label: 'תפוס'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String text;
  const _DayHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: AppTextStyles.label.copyWith(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  final int day;
  final bool isAvailable;

  const _CalendarDay({required this.day, required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isAvailable ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable ? AppColors.primary.withOpacity(0.2) : AppColors.borderFaint.withOpacity(0.5),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.toString(),
              style: AppTextStyles.bodyBold.copyWith(
                fontSize: 14,
                color: isAvailable ? AppColors.primary : AppColors.textPrimary.withOpacity(0.5),
              ),
            ),
            if (isAvailable)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
