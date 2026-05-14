import 'package:petpal/features/sitting/data/datasources/review_remote_datasource.dart';
import 'package:petpal/features/sitting/domain/entities/sitter_review.dart';
import 'package:petpal/features/sitting/domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDatasource _datasource;

  ReviewRepositoryImpl(this._datasource);

  @override
  Future<void> submitReview(SitterReview review) => _datasource.submitReview(review);

  @override
  Stream<List<SitterReview>> getSitterReviews(String sitterId) =>
      _datasource.watchSitterReviews(sitterId);

  @override
  Future<Map<String, int>> getSitterTagFrequencies(String sitterId) async {
    // This could also be fetched from the SittingService directly, 
    // but having a dedicated method in the repository is cleaner for future scaling.
    return {}; // Implementation deferred if data is already in SittingService
  }

  @override
  Future<bool> hasReviewedSitter(String sitterId, String ownerId) =>
      _datasource.hasReviewedSitter(sitterId, ownerId);
}
