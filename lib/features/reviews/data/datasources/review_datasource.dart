import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/notifications/data/datasources/notification_writer.dart';
import 'package:petpal/features/reviews/domain/entities/review.dart';

class ReviewDatasource {
  final FirebaseFirestore _db;

  ReviewDatasource(this._db);

  CollectionReference get _reviews => _db.collection('reviews');

  Future<void> submitReview(Review review) async {
    final providerRef = _db.collection('users').doc(review.providerId);
    final reviewRef = _reviews.doc(review.bookingId);

    // Query for any service listings of the provider before entering the transaction
    final sittingServicesQuery = await _db
        .collection('sitting_services')
        .where('providerUid', isEqualTo: review.providerId)
        .get();
    final walkServicesQuery = await _db
        .collection('walk_services')
        .where('providerUid', isEqualTo: review.providerId)
        .get();

    bool isNew = false;
    await _db.runTransaction((transaction) async {
      final providerSnap = await transaction.get(providerRef);
      final reviewSnap = await transaction.get(reviewRef);

      final providerData = providerSnap.data() ?? {};
      final double currentAvg = (providerData['ratingAverage'] as num?)?.toDouble() ?? 0.0;
      final int currentCount = (providerData['reviewCount'] as num?)?.toInt() ?? 0;

      double newAvg;
      int newCount;

      if (reviewSnap.exists) {
        final oldReviewData = reviewSnap.data() as Map<String, dynamic>;
        final double oldRating = (oldReviewData['rating'] as num).toDouble();
        final double newRating = review.rating.toDouble();

        newCount = currentCount;
        newAvg = currentCount > 0
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
        isNew = true;
        newCount = currentCount + 1;
        newAvg = (currentAvg * currentCount + review.rating) / newCount;

        transaction.set(reviewRef, {
          ...review.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.update(providerRef, {
          'ratingAverage': newAvg,
          'reviewCount': newCount,
        });
      }

      // Update sitting_services listings
      for (final doc in sittingServicesQuery.docs) {
        transaction.update(doc.reference, {
          'rating': newAvg,
          'reviewCount': newCount,
        });
      }

      // Update walk_services listings
      for (final doc in walkServicesQuery.docs) {
        transaction.update(doc.reference, {
          'rating': newAvg,
          'reviewCount': newCount,
        });
      }
    });

    // Only notify on the first review submission, not edits
    if (isNew) {
      writeClientNotification(
        _db,
        userId: review.providerId,
        title: 'חוות דעת חדשה',
        body: 'קיבלת חוות דעת עם דירוג ${review.rating} כוכבים',
        type: 'newReview',
        data: {'reviewId': review.bookingId},
      ).ignore();
    }
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
