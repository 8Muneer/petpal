import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/sitting/domain/entities/sitter_review.dart';

class SitterReviewModel extends SitterReview {
  const SitterReviewModel({
    required super.id,
    required super.bookingId,
    required super.sitterId,
    required super.ownerId,
    required super.rating,
    super.comment,
    required super.vibeTags,
    required super.imageUrls,
    required super.createdAt,
  });

  factory SitterReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SitterReviewModel(
      id: doc.id,
      bookingId: data['bookingId'] as String? ?? '',
      sitterId: data['sitterId'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] as String?,
      vibeTags: List<String>.from(data['vibeTags'] as List? ?? []),
      imageUrls: List<String>.from(data['imageUrls'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'sitterId': sitterId,
      'ownerId': ownerId,
      'rating': rating,
      'comment': comment,
      'vibeTags': vibeTags,
      'imageUrls': imageUrls,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
