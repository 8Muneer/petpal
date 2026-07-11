import 'package:flutter/material.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';

/// Step-by-step visual of where a booking stands in its lifecycle. Shared
/// between the owner's booking detail sheet and the provider's incoming
/// booking detail screen so both sides see the identical status story.
class BookingStatusTimeline extends StatelessWidget {
  final BookingStatus status;
  const BookingStatusTimeline({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps(status);
    return Column(
      children: [
        for (int i = 0; i < steps.length; i++)
          _TimelineNode(
            step: steps[i],
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }

  List<_Step> _buildSteps(BookingStatus status) {
    const sent = _Step(
      icon: Icons.send_rounded,
      title: 'הבקשה נשלחה',
      subtitle: 'הבקשה הועברה לשומר',
      state: _StepState.done,
    );

    switch (status) {
      case BookingStatus.pending:
        return const [
          sent,
          _Step(
            icon: Icons.hourglass_top_rounded,
            title: 'ממתין לאישור',
            subtitle: 'השומר בודק את הבקשה',
            state: _StepState.current,
            color: AppColors.warning,
          ),
        ];
      case BookingStatus.accepted:
        return const [
          sent,
          _Step(
            icon: Icons.check_circle_rounded,
            title: 'הבקשה אושרה',
            subtitle: 'השומר אישר את ההזמנה',
            state: _StepState.done,
            color: AppColors.success,
          ),
          _Step(
            icon: Icons.pets_rounded,
            title: 'השירות פעיל',
            subtitle: 'אפשר לתאם בצ\'אט. הביקורת תיפתח בסיום',
            state: _StepState.current,
            color: AppColors.primary,
          ),
        ];
      case BookingStatus.awaitingConfirmation:
        return const [
          sent,
          _Step(
            icon: Icons.check_circle_rounded,
            title: 'הבקשה אושרה',
            subtitle: 'השומר אישר את ההזמנה',
            state: _StepState.done,
            color: AppColors.success,
          ),
          _Step(
            icon: Icons.fact_check_outlined,
            title: 'ממתין לאישורך',
            subtitle: 'השומר סימן שסיים. אשר/י כדי לדרג',
            state: _StepState.current,
            color: AppColors.sapphire,
          ),
        ];
      case BookingStatus.completed:
        return const [
          sent,
          _Step(
            icon: Icons.check_circle_rounded,
            title: 'הבקשה אושרה',
            subtitle: 'השומר אישר את ההזמנה',
            state: _StepState.done,
            color: AppColors.success,
          ),
          _Step(
            icon: Icons.fact_check_outlined,
            title: 'השומר ביקש אישור',
            subtitle: 'השומר סימן שהשירות הסתיים',
            state: _StepState.done,
            color: AppColors.sapphire,
          ),
          _Step(
            icon: Icons.task_alt_rounded,
            title: 'השירות הושלם',
            subtitle: 'אישרת את סיום השירות. אפשר לכתוב ביקורת',
            state: _StepState.done,
            color: AppColors.primary,
          ),
        ];
      case BookingStatus.declined:
        return const [
          sent,
          _Step(
            icon: Icons.cancel_rounded,
            title: 'הבקשה נדחתה',
            subtitle: 'השומר אינו זמין לבקשה זו',
            state: _StepState.error,
            color: AppColors.error,
          ),
        ];
      case BookingStatus.cancelled:
        return const [
          sent,
          _Step(
            icon: Icons.do_not_disturb_on_rounded,
            title: 'ההזמנה בוטלה',
            subtitle: 'הבקשה בוטלה',
            state: _StepState.muted,
            color: AppColors.textMuted,
          ),
        ];
      case BookingStatus.expired:
        return const [
          sent,
          _Step(
            icon: Icons.timer_off_rounded,
            title: 'הבקשה פגה',
            subtitle: 'הבקשה לא אושרה עד למועד השירות',
            state: _StepState.muted,
            color: AppColors.textMuted,
          ),
        ];
    }
  }
}

enum _StepState { done, current, error, muted }

class _Step {
  final IconData icon;
  final String title;
  final String subtitle;
  final _StepState state;
  final Color color;
  const _Step({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.state,
    this.color = AppColors.success,
  });
}

class _TimelineNode extends StatelessWidget {
  final _Step step;
  final bool isLast;
  const _TimelineNode({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isMuted = step.state == _StepState.muted;
    final color = step.color;
    final filled =
        step.state == _StepState.done || step.state == _StepState.current;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Node + connector
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: filled
                      ? color.withValues(alpha: 0.14)
                      : (step.state == _StepState.error
                          ? color.withValues(alpha: 0.12)
                          : AppColors.surface),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isMuted
                        ? AppColors.border
                        : color.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Icon(step.icon,
                    size: 16,
                    color: isMuted ? AppColors.textMuted : color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Texts
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isMuted
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.subtitle,
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          if (step.state == _StepState.current)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'עכשיו',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
