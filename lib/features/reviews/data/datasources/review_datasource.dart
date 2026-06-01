import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/reviews/domain/entities/review.dart';

class ReviewDatasource {
  final FirebaseFirestore _db;

  ReviewDatasource(this._db);

  CollectionReference get _reviews => _db.collection('reviews');

  Future<void> submitReview(Review review) async {
    final providerRef = _db.collection('users').doc(review.providerId);
    final reviewRef = _reviews.doc(review.bookingId);

    await _db.runTransaction((transaction) async {
      final providerSnap = await transaction.get(providerRef);
      final reviewSnap = await transaction.get(reviewRef);

      final providerData = providerSnap.data() ?? {};
      final double currentAvg = (providerData['ratingAverage'] as num?)?.toDouble() ?? 0.0;
      final int currentCount = (providerData['reviewCount'] as num?)?.toInt() ?? 0;

      if (reviewSnap.exists) {
        final oldReviewData = reviewSnap.data() as Map<String, dynamic>;
        final double oldRating = (oldReviewData['rating'] as num).toDouble();
        final double newRating = review.rating.toDouble();

        final double newAvg = currentCount > 0
            ? (currentAvg * currentCount - oldRating + newRating) / currentCount
            : newRating;

        transaction.set(reviewRef, {
          ...review.toMap(),
          'createdAt': oldReviewData['createdAt'] ?? FieldValue.serverTimestamp(),
        });

        transaction.update(providerRef, {
          'ratingAverage': newAvg,
        });
      } else {
        final int newCount = currentCount + 1;
        final double newAvg = (currentAvg * currentCount + review.rating) / newCount;

        transaction.set(reviewRef, {
          ...review.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.update(providerRef, {
          'ratingAverage': newAvg,
          'reviewCount': newCount,
        });
      }
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
