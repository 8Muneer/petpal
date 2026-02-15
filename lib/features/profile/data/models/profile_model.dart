import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/auth/domain/enums/user_role.dart';
import 'package:petpal/features/profile/domain/entities/user_profile.dart';

class ProfileModel extends UserProfile {
  const ProfileModel({
    required super.uid,
    required super.name,
    required super.email,
    super.phone,
    super.photoUrl,
    super.bio,
    super.location,
    required super.role,
    super.isVerified,
    super.rating,
    super.totalBookings,
    super.totalReviews,
    super.createdAt,
    super.showPhone,
    super.showEmail,
    super.showLocation,
  });

  factory ProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProfileModel(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
      bio: data['bio'] as String?,
      location: data['location'] as String?,
      role: UserRole.fromString(
              data['role'] as String? ?? data['userType'] as String?) ??
          UserRole.petOwner,
      isVerified: data['isVerified'] == true,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      totalBookings: (data['totalBookings'] as num?)?.toInt() ?? 0,
      totalReviews: (data['totalReviews'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      showPhone: data['showPhone'] as bool? ?? true,
      showEmail: data['showEmail'] as bool? ?? true,
      showLocation: data['showLocation'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'bio': bio,
      'location': location,
      'role': role.firestoreValue,
      'isVerified': isVerified,
      'rating': rating,
      'totalBookings': totalBookings,
      'totalReviews': totalReviews,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
