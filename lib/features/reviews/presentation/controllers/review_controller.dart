import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/features/reviews/domain/entities/review_entity.dart';
import 'package:petpal/features/reviews/presentation/controllers/reviews_provider.dart';

class ReviewController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ReviewController(this._ref) : super(const AsyncValue.data(null));

  Future<void> submitReview({
    required String bookingId,
    required String reviewerId,
    required String revieweeId,
    required double rating,
  }) async {
    state = const AsyncValue.loading();
    try {
      final review = ReviewEntity(
        id: '', // Firestore will generate the ID
        bookingId: bookingId,
        reviewerId: reviewerId,
        revieweeId: revieweeId,
        rating: rating,
        createdAt: DateTime.now(),
      );

      await _ref.read(reviewsRepositoryProvider).submitReview(review);
      state = const AsyncValue.data(null);
      
      // Refresh the reviews for the reviewee
      _ref.invalidate(reviewsForUserProvider(revieweeId));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final reviewControllerProvider = StateNotifierProvider<ReviewController, AsyncValue<void>>((ref) {
  return ReviewController(ref);
});
