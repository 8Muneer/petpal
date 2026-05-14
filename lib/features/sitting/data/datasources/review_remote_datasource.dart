import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/sitting/data/models/sitter_review_model.dart';
import 'package:petpal/features/sitting/domain/entities/sitter_review.dart';

abstract class ReviewRemoteDatasource {
  Future<void> submitReview(SitterReview review);
  Stream<List<SitterReviewModel>> watchSitterReviews(String sitterId);
  Future<bool> hasReviewedSitter(String sitterId, String ownerId);
}

class FirestoreReviewRemoteDatasource implements ReviewRemoteDatasource {
  final FirebaseFirestore _firestore;

  FirestoreReviewRemoteDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> submitReview(SitterReview review) async {
    final reviewModel = SitterReviewModel(
      id: review.id,
      bookingId: review.bookingId,
      sitterId: review.sitterId,
      ownerId: review.ownerId,
      rating: review.rating,
      comment: review.comment,
      vibeTags: review.vibeTags,
      imageUrls: review.imageUrls,
      createdAt: review.createdAt,
    );

    return _firestore.runTransaction((transaction) async {
      // 1. Get Sitter Service document to update aggregates
      DocumentReference serviceRef = _firestore.collection('sitting_services').doc(review.sitterId);
      DocumentSnapshot serviceDoc = await transaction.get(serviceRef);

      if (!serviceDoc.exists) {
        // Fallback: Try to find by providerUid (common for 1:1 services)
        final serviceQuery = await _firestore.collection('sitting_services')
            .where('providerUid', isEqualTo: review.sitterId)
            .limit(1)
            .get();
        
        if (serviceQuery.docs.isEmpty) {
          throw Exception("Sitter service not found for ID: ${review.sitterId}");
        }
        
        serviceRef = serviceQuery.docs.first.reference;
        serviceDoc = serviceQuery.docs.first;
      }

      final data = serviceDoc.data() as Map<String, dynamic>? ?? {};
      final double currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
      final int currentReviewCount = (data['reviewCount'] as int?) ?? 0;
      final Map<String, int> currentTagFrequencies = 
          Map<String, int>.from(data['tagFrequencies'] as Map? ?? {});

      // 2. Calculate new rating and count
      final int newReviewCount = currentReviewCount + 1;
      final double newRating = ((currentRating * currentReviewCount) + review.rating) / newReviewCount;

      // 3. Update Tag Frequencies & Badges
      for (final tag in review.vibeTags) {
        currentTagFrequencies[tag] = (currentTagFrequencies[tag] ?? 0) + 1;
      }

      final List<String> currentBadges = List<String>.from(data['reputationBadges'] as List? ?? []);
      if (newReviewCount >= 5 && !currentBadges.contains('נבחר השכונה')) {
        currentBadges.add('נבחר השכונה');
      }

      // 4. Update Karma for the owner
      final userRef = _firestore.collection('users').doc(review.ownerId);
      transaction.update(userRef, {'karma': FieldValue.increment(10)});

      // 5. Add to Karma Ledger
      final ledgerRef = _firestore.collection('karma_ledger').doc();
      transaction.set(ledgerRef, {
        'userId': review.ownerId,
        'bookingId': review.bookingId,
        'points': 10,
        'reason': 'review_submitted',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 6. Set the review document with the CORRECT service ID (the doc ID, not the UID)
      final reviewRef = _firestore.collection('sitter_reviews').doc();
      final finalReviewData = reviewModel.toFirestore();
      finalReviewData['sitterId'] = serviceRef.id; // Ensure consistency
      
      transaction.set(reviewRef, finalReviewData);

      // 7. Update the service document with new stats
      transaction.update(serviceRef, {
        'rating': newRating,
        'reviewCount': newReviewCount,
        'tagFrequencies': currentTagFrequencies,
        'reputationBadges': currentBadges,
      });
    });
  }

  @override
  Stream<List<SitterReviewModel>> watchSitterReviews(String sitterId) {
    return _firestore
        .collection('sitter_reviews')
        .where('sitterId', isEqualTo: sitterId)
        .snapshots()
        .map((snapshot) {
      final reviews = snapshot.docs
          .map((doc) => SitterReviewModel.fromFirestore(doc))
          .toList();

      // Sort in memory to avoid the need for a composite index (createdAt + sitterId)
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    });
  }

  @override
  Future<bool> hasReviewedSitter(String sitterId, String ownerId) async {
    final snapshot = await _firestore
        .collection('sitter_reviews')
        .where('sitterId', isEqualTo: sitterId)
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
