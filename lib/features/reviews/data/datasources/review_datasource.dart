import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/reviews/domain/entities/review.dart';

class ReviewDatasource {
  final FirebaseFirestore _db;

  ReviewDatasource(this._db);

  CollectionReference get _reviews => _db.collection('reviews');

  Future<void> submitReview(Review review) async {
    await _reviews.add({
      ...review.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns the existing review for a booking, or null if none.
  Future<Review?> getBookingReview(String bookingId) async {
    final snap = await _reviews
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return Review.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Stream of all reviews for a provider, newest first.
  Stream<List<Review>> watchProviderReviews(String providerId) {
    return _reviews
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Review.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  /// Stream of (avgRating, reviewCount) for a provider.
  Stream<({double avg, int count})> watchProviderRating(String providerId) {
    return watchProviderReviews(providerId).map((reviews) {
      if (reviews.isEmpty) return (avg: 0.0, count: 0);
      final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) /
          reviews.length;
      return (avg: avg, count: reviews.length);
    });
  }
}
