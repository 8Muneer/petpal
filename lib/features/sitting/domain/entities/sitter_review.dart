import 'package:equatable/equatable.dart';

class SitterReview extends Equatable {
  final String id;
  final String bookingId;
  final String sitterId;
  final String ownerId;
  final double rating;
  final String? comment;
  final List<String> vibeTags;
  final List<String> imageUrls;
  final DateTime createdAt;

  const SitterReview({
    required this.id,
    required this.bookingId,
    required this.sitterId,
    required this.ownerId,
    required this.rating,
    this.comment,
    required this.vibeTags,
    required this.imageUrls,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        bookingId,
        sitterId,
        ownerId,
        rating,
        comment,
        vibeTags,
        imageUrls,
        createdAt,
      ];
}
