import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/reviews/domain/entities/review_entity.dart';

class ReviewModel extends ReviewEntity {
  const ReviewModel({
    required super.id,
    required super.bookingId,
    required super.reviewerId,
    required super.revieweeId,
    required super.rating,
    required super.createdAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      bookingId: data['booking_id'] ?? '',
      reviewerId: data['reviewer_id'] ?? '',
      revieweeId: data['reviewee_id'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'booking_id': bookingId,
      'reviewer_id': reviewerId,
      'reviewee_id': revieweeId,
      'rating': rating,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory ReviewModel.fromEntity(ReviewEntity entity) {
    return ReviewModel(
      id: entity.id,
      bookingId: entity.bookingId,
      reviewerId: entity.reviewerId,
      revieweeId: entity.revieweeId,
      rating: entity.rating,
      createdAt: entity.createdAt,
    );
  }
}
