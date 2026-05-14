import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart';
import '../providers/sitter_dashboard_state.dart';
import '../../domain/entities/care_task.dart';

class ActiveSittingCard extends ConsumerStatefulWidget {
  final SittingRequest request;
  const ActiveSittingCard({super.key, required this.request});

  @override
  ConsumerState<ActiveSittingCard> createState() => _ActiveSittingCardState();
}

class _ActiveSittingCardState extends ConsumerState<ActiveSittingCard> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sitterDashboardProvider);
    // Removed dependency on state.isLive to allow manual triggering if needed,
    // or just rely on the request presence.
    final startTime =
        state.startTime ?? widget.request.startDate ?? DateTime.now();

    final elapsed = _now.difference(startTime);
    final completedCount = state.activeChecklist.where((t) => t.isDone).length;
    final progress = state.activeChecklist.isEmpty
        ? 0.0
        : completedCount / state.activeChecklist.length;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.organicRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.organicRadius,
        child: Stack(
          children: [
            // Glass Base
            GlassCard(
              padding: EdgeInsets.zero,
              borderRadius: AppRadius.organicRadius,
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timer & Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side: Timer
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDuration(elapsed),
                              style: AppTextStyles.headlineLg.copyWith(
                                color: AppColors.primary,
                                fontFamily: 'monospace',
                                letterSpacing: -1,
                                fontSize: 22,
                              ),
                            ),
                            Text(
                              'זמן שחלף',
                              style: AppTextStyles.labelSm.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Right side: Pet info
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const Text('בשידור חי',
                                            style: TextStyle(fontSize: 10)),
                                        const SizedBox(width: 4),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'שמירה פעילה: ${widget.request.petName}',
                                      style: AppTextStyles.headlineSm.copyWith(
                                        fontSize: 14,
                                        height: 1.2,
                                      ),
                                      textAlign: TextAlign.end,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppColors.primary, width: 1.5),
                                  image: DecorationImage(
                                    image: NetworkImage(widget
                                            .request.petImageUrl ??
                                        'https://images.unsplash.com/photo-1552053831-71594a27632d'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Checklist Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.5),
                        borderRadius: AppRadius.tileRadius,
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'צ׳ק-ליסט טיפול',
                            style: AppTextStyles.labelSm.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: state.activeChecklist.map((task) {
                              return Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: _TaskButton(
                                    task: task,
                                    onTap: () => ref
                                        .read(sitterDashboardProvider.notifier)
                                        .toggleTask(task.id),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('עדכון תמונה'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.fullRadius),
                            ),
                            child: const Icon(Icons.chat_bubble_outline,
                                color: AppColors.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Progress Bar Overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                color: AppColors.divider,
                child: FractionallySizedBox(
                  alignment: Alignment.centerRight,
                  widthFactor: progress,
                  child: Container(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskButton extends StatelessWidget {
  final CareTask task;
  final VoidCallback onTap;

  const _TaskButton({required this.task, required this.onTap});

  IconData _getIcon() {
    switch (task.type) {
      case CareTaskType.food:
        return Icons.restaurant_outlined;
      case CareTaskType.walk:
        return Icons.directions_walk_outlined;
      case CareTaskType.meds:
        return Icons.medical_services_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = task.isDone;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isDone ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(
            color: isDone ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _getIcon(),
              color: isDone ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              task.label,
              style: AppTextStyles.labelSm.copyWith(
                color: isDone ? AppColors.primary : AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
