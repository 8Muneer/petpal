import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/glass_pill.dart';

enum LuxuryBookingStatus { upcoming, completed, cancelled }

enum LuxuryServiceCategory { walks, sitting }

class LuxuryBookingCard extends StatelessWidget {
  final String petName;
  final String petPhotoUrl;
  final String title;
  final LuxuryServiceCategory category;
  final String date;
  final String time;
  final String price;
  final LuxuryBookingStatus status;
  final bool isAccepted;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onRate;

  const LuxuryBookingCard({
    super.key,
    required this.petName,
    required this.petPhotoUrl,
    required this.title,
    required this.category,
    required this.date,
    required this.time,
    required this.price,
    required this.status,
    required this.isAccepted,
    this.onTap,
    this.onCancel,
    this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUpcoming = status == LuxuryBookingStatus.upcoming;
    final bool isCompleted = status == LuxuryBookingStatus.completed;
    final bool isCancelled = status == LuxuryBookingStatus.cancelled;

    // Architectural accent color
    final Color accentColor = isCancelled
        ? AppColors.textMuted
        : (category == LuxuryServiceCategory.walks
            ? AppColors.primary
            : const Color(0xFFB4A08B));
    const Color bronzeColor = Color(0xFFC19A6B);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Dismissible(
        key: Key(title + date),
        direction:
            isUpcoming ? DismissDirection.endToStart : DismissDirection.none,
        confirmDismiss: (direction) async {
          if (onCancel != null) {
            // Logic for confirmation dialog should be handled by the caller or here
            return await _showCancelConfirmation(context);
          }
          return false;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: AppRadius.organicRadius,
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.close_rounded, color: Colors.white, size: 28),
              SizedBox(height: 4),
              Text(
                'ביטול',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ],
          ),
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: AppRadius.organicRadius,
              border:
                  Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              boxShadow: AppShadows.subtle,
            ),
            child: Row(
              children: [
                // Architectural Accent Bar
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),

                // Pet Photo
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: petPhotoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: AppColors.surface),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.pets),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Booking Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Chip
                      Row(
                        children: [
                          _buildCategoryChip(),
                          const SizedBox(width: 8),
                          if (isUpcoming) ...[
                            Text(
                              isAccepted ? 'אושר' : 'ממתין',
                              style: TextStyle(
                                color: isAccepted
                                    ? AppColors.success
                                    : AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                          if (isCancelled) ...[
                            const Text(
                              'מבוטל',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: AppTextStyles.headlineSm.copyWith(
                          color: isCancelled
                              ? AppColors.textMuted
                              : AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(date, style: AppTextStyles.labelMd),
                          const SizedBox(width: 12),
                          const Icon(Icons.schedule_rounded,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(time, style: AppTextStyles.labelMd),
                        ],
                      ),
                    ],
                  ),
                ),

                // Price and Rating
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: AppTextStyles.headlineSm.copyWith(
                        color: isCancelled
                            ? AppColors.textMuted
                            : AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isCompleted && onRate != null)
                      TextButton.icon(
                        onPressed: onRate,
                        icon: const Icon(Icons.star_rounded, size: 16, color: bronzeColor),
                        label: const Text(
                          'דרג',
                          style: TextStyle(
                            color: bronzeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          backgroundColor: bronzeColor.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      )
                    else
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.border,
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

  Widget _buildCategoryChip() {
    final bool isWalk = category == LuxuryServiceCategory.walks;
    return GlassPill(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWalk ? Icons.directions_walk_rounded : Icons.home_rounded,
            size: 12,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            isWalk ? 'טיול' : 'שמירה',
            style: AppTextStyles.labelMd
                .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Future<bool> _showCancelConfirmation(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: AppRadius.organicRadius),
            backgroundColor: AppColors.surface,
            title: Text('ביטול הזמנה', style: AppTextStyles.headlineSm),
            content: Text('האם אתה בטוח שברצונך לבטל את ההזמנה עבור $petName?',
                style: AppTextStyles.bodyMd),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('לא, חזור', style: AppTextStyles.labelMd),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('כן, בטל'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
