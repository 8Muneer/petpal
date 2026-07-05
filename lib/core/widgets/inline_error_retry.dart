import 'package:flutter/material.dart';

import 'package:petpal/core/theme/app_theme.dart';

/// Compact inline error state for sections that load from a provider.
///
/// Use instead of `SizedBox.shrink()` in `AsyncValue.when(error: ...)`
/// branches — a section silently vanishing on a network hiccup looks like a
/// bug; this keeps the section visible and gives the user a retry.
class InlineErrorRetry extends StatelessWidget {
  const InlineErrorRetry({
    super.key,
    this.message = 'שגיאה בטעינת הנתונים',
    required this.onRetry,
  });

  /// Short, user-facing description of what failed to load.
  final String message;

  /// Typically `() => ref.invalidate(someProvider)`.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppColors.textMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 36),
            ),
            child: Text(
              'נסה שוב',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
