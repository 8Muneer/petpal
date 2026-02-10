// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserModel _$UserModelFromJson(Map<String, dynamic> json) {
  return _UserModel.fromJson(json);
}

/// @nodoc
mixin _$UserModel {
  /// Unique user ID from Firebase Auth
  String get id => throw _privateConstructorUsedError;

  /// User email address
  String get email => throw _privateConstructorUsedError;

  /// User display name
  String? get displayName => throw _privateConstructorUsedError;

  /// User role: 'petOwner' or 'serviceProvider'
  String get role => throw _privateConstructorUsedError;

  /// Profile photo URL
  String? get photoURL => throw _privateConstructorUsedError;

  /// Phone number
  String? get phoneNumber => throw _privateConstructorUsedError;

  /// Account creation timestamp
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Whether user is verified (for service providers)
  bool get isVerified => throw _privateConstructorUsedError;

  /// User bio/description (for service providers)
  String? get bio => throw _privateConstructorUsedError;

  /// User location/address
  String? get address => throw _privateConstructorUsedError;

  /// Rating (for service providers)
  double get rating => throw _privateConstructorUsedError;

  /// Number of reviews (for service providers)
  int get reviewCount => throw _privateConstructorUsedError;

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call(
      {String id,
      String email,
      String? displayName,
      String role,
      String? photoURL,
      String? phoneNumber,
      DateTime? createdAt,
      bool isVerified,
      String? bio,
      String? address,
      double rating,
      int reviewCount});
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? displayName = freezed,
    Object? role = null,
    Object? photoURL = freezed,
    Object? phoneNumber = freezed,
    Object? createdAt = freezed,
    Object? isVerified = null,
    Object? bio = freezed,
    Object? address = freezed,
    Object? rating = null,
    Object? reviewCount = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      photoURL: freezed == photoURL
          ? _value.photoURL
          : photoURL // ignore: cast_nullable_to_non_nullable
              as String?,
      phoneNumber: freezed == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isVerified: null == isVerified
          ? _value.isVerified
          : isVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double,
      reviewCount: null == reviewCount
          ? _value.reviewCount
          : reviewCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserModelImplCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$$UserModelImplCopyWith(
          _$UserModelImpl value, $Res Function(_$UserModelImpl) then) =
      __$$UserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String email,
      String? displayName,
      String role,
      String? photoURL,
      String? phoneNumber,
      DateTime? createdAt,
      bool isVerified,
      String? bio,
      String? address,
      double rating,
      int reviewCount});
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
      _$UserModelImpl _value, $Res Function(_$UserModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? displayName = freezed,
    Object? role = null,
    Object? photoURL = freezed,
    Object? phoneNumber = freezed,
    Object? createdAt = freezed,
    Object? isVerified = null,
    Object? bio = freezed,
    Object? address = freezed,
    Object? rating = null,
    Object? reviewCount = null,
  }) {
    return _then(_$UserModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      photoURL: freezed == photoURL
          ? _value.photoURL
          : photoURL // ignore: cast_nullable_to_non_nullable
              as String?,
      phoneNumber: freezed == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isVerified: null == isVerified
          ? _value.isVerified
          : isVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double,
      reviewCount: null == reviewCount
          ? _value.reviewCount
          : reviewCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserModelImpl implements _UserModel {
  const _$UserModelImpl(
      {required this.id,
      required this.email,
      this.displayName,
      required this.role,
      this.photoURL,
      this.phoneNumber,
      this.createdAt,
      this.isVerified = false,
      this.bio,
      this.address,
      this.rating = 0.0,
      this.reviewCount = 0});

  factory _$UserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserModelImplFromJson(json);

  /// Unique user ID from Firebase Auth
  @override
  final String id;

  /// User email address
  @override
  final String email;

  /// User display name
  @override
  final String? displayName;

  /// User role: 'petOwner' or 'serviceProvider'
  @override
  final String role;

  /// Profile photo URL
  @override
  final String? photoURL;

  /// Phone number
  @override
  final String? phoneNumber;

  /// Account creation timestamp
  @override
  final DateTime? createdAt;

  /// Whether user is verified (for service providers)
  @override
  @JsonKey()
  final bool isVerified;

  /// User bio/description (for service providers)
  @override
  final String? bio;

  /// User location/address
  @override
  final String? address;

  /// Rating (for service providers)
  @override
  @JsonKey()
  final double rating;

  /// Number of reviews (for service providers)
  @override
  @JsonKey()
  final int reviewCount;

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, role: $role, photoURL: $photoURL, phoneNumber: $phoneNumber, createdAt: $createdAt, isVerified: $isVerified, bio: $bio, address: $address, rating: $rating, reviewCount: $reviewCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.photoURL, photoURL) ||
                other.photoURL == photoURL) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.isVerified, isVerified) ||
                other.isVerified == isVerified) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.reviewCount, reviewCount) ||
                other.reviewCount == reviewCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      email,
      displayName,
      role,
      photoURL,
      phoneNumber,
      createdAt,
      isVerified,
      bio,
      address,
      rating,
      reviewCount);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      __$$UserModelImplCopyWithImpl<_$UserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserModelImplToJson(
      this,
    );
  }
}

abstract class _UserModel implements UserModel {
  const factory _UserModel(
      {required final String id,
      required final String email,
      final String? displayName,
      required final String role,
      final String? photoURL,
      final String? phoneNumber,
      final DateTime? createdAt,
      final bool isVerified,
      final String? bio,
      final String? address,
      final double rating,
      final int reviewCount}) = _$UserModelImpl;

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  /// Unique user ID from Firebase Auth
  @override
  String get id;

  /// User email address
  @override
  String get email;

  /// User display name
  @override
  String? get displayName;

  /// User role: 'petOwner' or 'serviceProvider'
  @override
  String get role;

  /// Profile photo URL
  @override
  String? get photoURL;

  /// Phone number
  @override
  String? get phoneNumber;

  /// Account creation timestamp
  @override
  DateTime? get createdAt;

  /// Whether user is verified (for service providers)
  @override
  bool get isVerified;

  /// User bio/description (for service providers)
  @override
  String? get bio;

  /// User location/address
  @override
  String? get address;

  /// Rating (for service providers)
  @override
  double get rating;

  /// Number of reviews (for service providers)
  @override
  int get reviewCount;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
