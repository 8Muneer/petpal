import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/features/sitting/data/datasources/review_remote_datasource.dart';
import 'package:petpal/features/sitting/data/repositories/review_repository_impl.dart';
import 'package:petpal/features/sitting/domain/entities/sitter_review.dart';
import 'package:petpal/features/sitting/domain/repositories/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(FirestoreReviewRemoteDatasource());
});

final sitterReviewsProvider = StreamProvider.family<List<SitterReview>, String>((ref, sitterId) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getSitterReviews(sitterId);
});

final reviewControllerProvider = StateNotifierProvider<ReviewController, AsyncValue<void>>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);
  return ReviewController(repository);
});

class ReviewController extends StateNotifier<AsyncValue<void>> {
  final ReviewRepository _repository;

  ReviewController(this._repository) : super(const AsyncValue.data(null));

  Future<void> submitReview(SitterReview review) async {
    state = const AsyncValue.loading();
    try {
      await _repository.submitReview(review);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> checkHasReviewed(String sitterId, String ownerId) async {
    return await _repository.hasReviewedSitter(sitterId, ownerId);
  }
}
