import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final String id;
  final String bookingId;
  final String reviewerUid;
  final String reviewerName;
  final String? reviewerPhotoUrl;
  final String providerId;
  final int rating; // 1 – 5
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.bookingId,
    required this.reviewerUid,
    required this.reviewerName,
    this.reviewerPhotoUrl,
    required this.providerId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(String id, Map<String, dynamic> map) {
    return Review(
      id: id,
      bookingId: map['bookingId'] as String,
      reviewerUid: map['reviewerUid'] as String,
      reviewerName: map['reviewerName'] as String? ?? '',
      reviewerPhotoUrl: map['reviewerPhotoUrl'] as String?,
      providerId: map['providerId'] as String,
      rating: (map['rating'] as num).toInt(),
      comment: map['comment'] as String?,
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'bookingId': bookingId,
        'reviewerUid': reviewerUid,
        'reviewerName': reviewerName,
        'reviewerPhotoUrl': reviewerPhotoUrl,
        'providerId': providerId,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt,
      };

  @override
  List<Object?> get props => [
        id,
        bookingId,
        reviewerUid,
        providerId,
        rating,
        comment,
        createdAt,
      ];
}
