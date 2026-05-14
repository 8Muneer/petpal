import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petpal/core/theme/app_theme.dart';

class BentoCalendar extends StatelessWidget {
  final DateTime currentMonth;
  final bool Function(DateTime) isDateAvailable;
  final Function(DateTime) onDateTap;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onTodayTap;

  const BentoCalendar({
    super.key,
    required this.currentMonth,
    required this.isDateAvailable,
    required this.onDateTap,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onTodayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0);

    final int emptySlots =
        firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    final int totalDays = lastDayOfMonth.day;

    final monthName = DateFormat('MMMM yyyy', 'he').format(currentMonth);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.borderFaint.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          children: [
            // Premium Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.03),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthName,
                          style: AppTextStyles.h1.copyWith(
                            fontSize: 24,
                            letterSpacing: -0.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ניהול חריגות',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _HeaderAction(
                        icon: Icons.chevron_right_rounded,
                        onTap: onNextMonth,
                      ),
                      const SizedBox(width: 8),
                      _HeaderAction(
                        icon: Icons.chevron_left_rounded,
                        onTap: onPreviousMonth,
                      ),
                      const SizedBox(width: 8),
                      _HeaderAction(
                        icon: Icons.today_rounded,
                        label: 'היום',
                        onTap: onTodayTap,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  // Day Labels with subtle dividers
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _DayLabel(text: 'א׳'),
                      _DayLabel(text: 'ב׳'),
                      _DayLabel(text: 'ג׳'),
                      _DayLabel(text: 'ד׳'),
                      _DayLabel(text: 'ה׳'),
                      _DayLabel(text: 'ו׳'),
                      _DayLabel(text: 'ש׳'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Calendar Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: emptySlots + totalDays,
                    itemBuilder: (context, index) {
                      if (index < emptySlots) return const SizedBox.shrink();

                      final day = index - emptySlots + 1;
                      final date =
                          DateTime(currentMonth.year, currentMonth.month, day);
                      final available = isDateAvailable(date);
                      final isToday = DateTime.now().day == day &&
                          DateTime.now().month == currentMonth.month;

                      return _CalendarDayCell(
                        day: day,
                        isAvailable: available,
                        isToday: isToday,
                        onTap: () => onDateTap(date),
                      );
                    },
                  ),

                  const SizedBox(height: 28),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 20),

                  // Refined Legend
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendItem(
                        color: AppColors.primary,
                        label: 'זמין לעבודה',
                        icon: Icons.check_circle_outline_rounded,
                      ),
                      SizedBox(width: 24),
                      _LegendItem(
                        color: AppColors.textMuted,
                        label: 'יום חסום',
                        icon: Icons.block_rounded,
                        isBlocked: true,
                      ),
                    ],
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

class _CalendarDayCell extends StatelessWidget {
  final int day;
  final bool isAvailable;
  final bool isToday;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.day,
    required this.isAvailable,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          color: isAvailable ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAvailable ? AppColors.primary : AppColors.borderFaint,
            width: isToday ? 2 : 1,
          ),
          boxShadow: isAvailable
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ]
              : (isToday
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                day.toString(),
                style: AppTextStyles.bodyBold.copyWith(
                  color: isAvailable ? Colors.white : AppColors.textPrimary,
                  fontSize: 15,
                  height: 1,
                ),
              ),
              if (isToday)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.white : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: label != null ? 14 : 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderFaint),
          boxShadow: AppShadows.subtle,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(
                label!,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  final String text;
  const _DayLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: AppTextStyles.label.copyWith(
            color: AppColors.textMuted.withOpacity(0.6),
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;
  final bool isBlocked;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.icon,
    this.isBlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.8)),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
