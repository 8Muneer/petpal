import 'package:equatable/equatable.dart';
import 'package:petpal/features/auth/domain/enums/user_role.dart';

class UserProfile extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final String? bio;
  final String? location;
  final UserRole role;
  final bool isVerified;
  final double rating;
  final int totalBookings;
  final int totalReviews;
  final DateTime? createdAt;
  final bool showPhone;
  final bool showEmail;
  final bool showLocation;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.bio,
    this.location,
    required this.role,
    this.isVerified = false,
    this.rating = 0.0,
    this.totalBookings = 0,
    this.totalReviews = 0,
    this.createdAt,
    this.showPhone = true,
    this.showEmail = true,
    this.showLocation = true,
  });

  @override
  List<Object?> get props => [
        uid,
        name,
        email,
        phone,
        photoUrl,
        bio,
        location,
        role,
        isVerified,
        rating,
        totalBookings,
        totalReviews,
        createdAt,
        showPhone,
        showEmail,
        showLocation,
      ];
}
