import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/reviews/presentation/controllers/review_controller.dart';

class ReviewDialog extends ConsumerStatefulWidget {
  final String bookingId;
  final String reviewerId;
  final String revieweeId;
  final String revieweeName;

  const ReviewDialog({
    super.key,
    required this.bookingId,
    required this.reviewerId,
    required this.revieweeId,
    required this.revieweeName,
  });

  @override
  ConsumerState<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<ReviewDialog> {
  double _rating = 0;
  static const Color _bronzeColor = Color(0xFFC19A6B);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewControllerProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      backgroundColor: const Color(0xFFF9F9F7),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 48, color: _bronzeColor),
            const SizedBox(height: 16),
            Text(
              'איך היה השירות?',
              style: AppTextStyles.headlineMd.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'IBM Plex Sans Arabic',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'דרג את ${widget.revieweeName} כדי לעזור לאחרים',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _rating = starIndex.toDouble());
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      starIndex <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 44,
                      color: _bronzeColor,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
            if (state.isLoading)
              const CircularProgressIndicator(color: _bronzeColor)
            else
              ElevatedButton(
                onPressed: _rating == 0
                    ? null
                    : () async {
                        await ref.read(reviewControllerProvider.notifier).submitReview(
                               bookingId: widget.bookingId,
                               reviewerId: widget.reviewerId,
                               revieweeId: widget.revieweeId,
                               rating: _rating,
                             );
                        
                        final finalState = ref.read(reviewControllerProvider);
                        if (context.mounted) {
                          if (finalState.hasError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('שגיאה: ${finalState.error}')),
                            );
                          } else {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('תודה על הדירוג!')),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bronzeColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ).copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return _bronzeColor.withValues(alpha: 0.3);
                    }
                    return _bronzeColor;
                  }),
                ),
                child: const Text(
                  'שלח דירוג',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'אולי מאוחר יותר',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
