import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// User model representing a PetPal user
///
/// Supports two roles:
/// - petOwner: Regular user looking for pet services
/// - serviceProvider: Provider offering pet services
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    /// Unique user ID from Firebase Auth
    required String id,

    /// User email address
    required String email,

    /// User display name
    String? displayName,

    /// User role: 'petOwner' or 'serviceProvider'
    required String role,

    /// Profile photo URL
    String? photoURL,

    /// Phone number
    String? phoneNumber,

    /// Account creation timestamp
    DateTime? createdAt,

    /// Whether user is verified (for service providers)
    @Default(false) bool isVerified,

    /// User bio/description (for service providers)
    String? bio,

    /// User location/address
    String? address,

    /// Rating (for service providers)
    @Default(0.0) double rating,

    /// Number of reviews (for service providers)
    @Default(0) int reviewCount,
  }) = _UserModel;

  /// Create UserModel from JSON (Firestore document)
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Empty user model for initial state
  static const empty = UserModel(
    id: '',
    email: '',
    role: '',
  );
}
