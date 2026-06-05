import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/features/reviews/data/datasources/review_datasource.dart';
import 'package:petpal/features/reviews/domain/entities/review.dart';

final reviewDatasourceProvider = Provider<ReviewDatasource>((ref) {
  return ReviewDatasource(FirebaseFirestore.instance);
});

final providerRatingProvider = StreamProvider.autoDispose
    .family<({double avg, int count}), String>((ref, providerId) {
  return ref.watch(reviewDatasourceProvider).watchProviderRating(providerId);
});

final providerReviewsProvider =
    StreamProvider.autoDispose.family<List<Review>, String>((ref, providerId) {
  return ref.watch(reviewDatasourceProvider).watchProviderReviews(providerId);
});

final bookingReviewProvider =
    FutureProvider.autoDispose.family<Review?, String>((ref, bookingId) {
  return ref.watch(reviewDatasourceProvider).getBookingReview(bookingId);
});

class ReviewNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submitReview(Review review) async {
    await ref.read(reviewDatasourceProvider).submitReview(review);
    ref.invalidate(bookingReviewProvider(review.bookingId));
    ref.invalidate(providerRatingProvider(review.providerId));
    ref.invalidate(providerReviewsProvider(review.providerId));
  }
}

final reviewNotifierProvider =
    AsyncNotifierProvider<ReviewNotifier, void>(ReviewNotifier.new);
