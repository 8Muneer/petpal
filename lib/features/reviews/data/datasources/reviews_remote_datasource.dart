import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/reviews/data/models/review_model.dart';

abstract class ReviewsRemoteDataSource {
  Future<void> submitReview(ReviewModel review);
  Future<List<ReviewModel>> getReviewsForUser(String userId);
}

class FirestoreReviewsDataSource implements ReviewsRemoteDataSource {
  final FirebaseFirestore _firestore;

  FirestoreReviewsDataSource(this._firestore);

  @override
  Future<void> submitReview(ReviewModel review) async {
    await _firestore.collection('reviews').add(review.toFirestore());
  }

  @override
  Future<List<ReviewModel>> getReviewsForUser(String userId) async {
    final query = await _firestore
        .collection('reviews')
        .where('reviewee_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .get();

    return query.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
  }
}
