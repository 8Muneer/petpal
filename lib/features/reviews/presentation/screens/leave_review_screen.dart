import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/reviews/domain/entities/review.dart';
import 'package:petpal/features/reviews/presentation/providers/review_provider.dart';

class LeaveReviewScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String providerUid;
  final String providerName;
  final String? providerPhotoUrl;

  const LeaveReviewScreen({
    super.key,
    required this.bookingId,
    required this.providerUid,
    required this.providerName,
    this.providerPhotoUrl,
  });

  @override
  ConsumerState<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends ConsumerState<LeaveReviewScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('אנא בחר דירוג')),
      );
      return;
    }

    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      final review = Review(
        id: '',
        bookingId: widget.bookingId,
        reviewerUid: user.uid,
        reviewerName: user.displayName ?? user.email ?? '',
        reviewerPhotoUrl: user.photoURL,
        providerId: widget.providerUid,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        createdAt: DateTime.now(),
      );
      await ref.read(reviewNotifierProvider.notifier).submitReview(review);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('הביקורת נשלחה בהצלחה!')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('שגיאה בשליחת הביקורת')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          title: Text('השאר ביקורת', style: AppTextStyles.headlineSm),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              // Provider avatar + name
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryFaint,
                backgroundImage:
                    (widget.providerPhotoUrl?.isNotEmpty == true)
                        ? CachedNetworkImageProvider(widget.providerPhotoUrl!)
                        : null,
                child: (widget.providerPhotoUrl?.isNotEmpty != true)
                    ? Text(
                        widget.providerName.isNotEmpty
                            ? widget.providerName.characters.first.toUpperCase()
                            : '?',
                        style: AppTextStyles.headlineMd
                            .copyWith(color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(widget.providerName, style: AppTextStyles.headlineSm),
              const SizedBox(height: 4),
              Text(
                'כיצד היה השירות?',
                style: AppTextStyles.bodyMd
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),

              // Star rating row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = star),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        star <= _rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 44,
                        color: star <= _rating
                            ? AppColors.warning
                            : AppColors.textMuted,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                _ratingLabel(_rating),
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28),

              // Comment field
              Container(
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: AppRadius.lgRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _commentController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: 'ספר על החוויה שלך (אופציונלי)...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    counterStyle: TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: AppTextStyles.bodyMd
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('שלח ביקורת'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int r) => switch (r) {
        1 => 'גרוע',
        2 => 'לא טוב',
        3 => 'בסדר',
        4 => 'טוב',
        5 => 'מצוין!',
        _ => 'בחר דירוג',
      };
}
