import 'package:petpal/features/reviews/data/datasources/reviews_remote_datasource.dart';
import 'package:petpal/features/reviews/data/models/review_model.dart';
import 'package:petpal/features/reviews/domain/entities/review_entity.dart';
import 'package:petpal/features/reviews/domain/repositories/reviews_repository.dart';

class ReviewsRepositoryImpl implements ReviewsRepository {
  final ReviewsRemoteDataSource _remoteDataSource;

  ReviewsRepositoryImpl(this._remoteDataSource);

  @override
  Future<void> submitReview(ReviewEntity review) async {
    await _remoteDataSource.submitReview(ReviewModel.fromEntity(review));
  }

  @override
  Future<List<ReviewEntity>> getReviewsForUser(String userId) async {
    return await _remoteDataSource.getReviewsForUser(userId);
  }
}
