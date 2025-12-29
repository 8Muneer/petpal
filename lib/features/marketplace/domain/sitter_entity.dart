import 'package:equatable/equatable.dart';

class SitterEntity extends Equatable {
  final String id;
  final String name;
  final String bio;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final double pricePerHour;
  final List<String> services;
  final bool isVerified;
  final double? distance; // Optional distance from user

  const SitterEntity({
    required this.id,
    required this.name,
    required this.bio,
    this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.pricePerHour,
    required this.services,
    required this.isVerified,
    this.distance,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        bio,
        imageUrl,
        rating,
        reviewCount,
        pricePerHour,
        services,
        isVerified,
        distance,
      ];
}
