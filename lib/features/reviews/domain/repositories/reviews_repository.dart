import 'package:petpal/features/reviews/domain/entities/review_entity.dart';

abstract class ReviewsRepository {
  Future<void> submitReview(ReviewEntity review);
  Future<List<ReviewEntity>> getReviewsForUser(String userId);
}
