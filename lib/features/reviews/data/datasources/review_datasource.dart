import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/reviews/domain/entities/review.dart';

class ReviewDatasource {
  final FirebaseFirestore _db;

  ReviewDatasource(this._db);

  CollectionReference get _reviews => _db.collection('reviews');

  /// Writes only the review document. The provider's rating aggregates
  /// (ratingAverage/reviewCount on /users and on their service listings) are
  /// recomputed server-side by the `onReviewWrite` Cloud Function — the
  /// client is not allowed to write those aggregate fields directly (see
  /// firestore.rules), so this stays a single plain write instead of a
  /// transaction.
  Future<void> submitReview(Review review) async {
    final reviewRef = _reviews.doc(review.bookingId);
    final existing = await reviewRef.get();

    await reviewRef.set({
      ...review.toMap(),
      'createdAt': existing.exists
          ? (existing.data() as Map<String, dynamic>)['createdAt'] ??
              FieldValue.serverTimestamp()
          : FieldValue.serverTimestamp(),
    });
  }

  /// Returns the existing review for a booking, or null if none.
  Future<Review?> getBookingReview(String bookingId) async {
    final doc = await _reviews.doc(bookingId).get();
    if (!doc.exists) return null;
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
    return _db.collection('users').doc(providerId).snapshots().map((snap) {
      if (!snap.exists) return (avg: 0.0, count: 0);
      final data = snap.data() ?? {};
      final avg = (data['ratingAverage'] as num?)?.toDouble() ?? 0.0;
      final count = (data['reviewCount'] as num?)?.toInt() ?? 0;
      return (avg: avg, count: count);
    });
  }
}
