import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

class CommunityEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onAction;

  const CommunityEmptyState({
    super.key,
    this.title = 'Be the First to Spark a Conversation',
    this.subtitle = 'Share a tip, recommend a local sitter, or just say hello to your neighbors.',
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.forum_outlined, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSm,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_comment_rounded, size: 18),
              label: const Text('Share with Neighbors'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
