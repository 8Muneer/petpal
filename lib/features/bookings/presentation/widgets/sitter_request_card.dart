import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/glass_card.dart';

class SitterRequestCard extends StatelessWidget {
  final String ownerName;
  final String petName;
  final String serviceType;
  final String price;
  final String timeLeft;
  final String avatarUrl;
  final List<String> tags;
  final VoidCallback? onAccept;
  final VoidCallback? onRefuse;
  final VoidCallback? onTap;

  const SitterRequestCard({
    super.key,
    required this.ownerName,
    required this.petName,
    required this.serviceType,
    required this.price,
    required this.timeLeft,
    required this.avatarUrl,
    required this.tags,
    this.onAccept,
    this.onRefuse,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.organicRadius,
        boxShadow: AppShadows.subtle,
      ),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(20),
        borderRadius: AppRadius.organicRadius,
        child: Column(
          children: [
            // Top Row: Owner & Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Timer (Left - for RTL)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        timeLeft,
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Owner Info (Right - for RTL)
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(ownerName, style: AppTextStyles.bodyBold),
                        Text('בקשה חדשה', style: AppTextStyles.labelSm),
                      ],
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(avatarUrl),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Middle: Service Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.tileRadius,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(price, style: AppTextStyles.priceTag.copyWith(fontSize: 18)),
                      Row(
                        children: [
                          Text(petName, style: AppTextStyles.bodyBold),
                          const SizedBox(width: 8),
                          const Icon(Icons.pets, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(serviceType, style: AppTextStyles.bodyMd),
                      const SizedBox(width: 8),
                      const Icon(Icons.home_outlined, size: 16, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Tags
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: tags.map((tag) => Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.fullRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(tag, style: AppTextStyles.labelSm.copyWith(fontSize: 10)),
              )).toList(),
            ),
            const SizedBox(height: 20),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRefuse,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape:
                          RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: const Text('סירוב', style: TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape:
                          RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
                    ),
                    child: const Text('אישור מהיר'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
