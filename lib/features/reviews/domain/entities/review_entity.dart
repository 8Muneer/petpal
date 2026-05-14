import 'package:equatable/equatable.dart';

class ReviewEntity extends Equatable {
  final String id;
  final String bookingId;
  final String reviewerId;
  final String revieweeId;
  final double rating;
  final DateTime createdAt;

  const ReviewEntity({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, bookingId, reviewerId, revieweeId, rating, createdAt];
}
