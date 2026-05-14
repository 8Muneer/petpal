import 'package:petpal/features/sitting/domain/entities/sitter_review.dart';

abstract class ReviewRepository {
  Future<void> submitReview(SitterReview review);
  Stream<List<SitterReview>> getSitterReviews(String sitterId);
  Future<Map<String, int>> getSitterTagFrequencies(String sitterId);
  Future<bool> hasReviewedSitter(String sitterId, String ownerId);
}
