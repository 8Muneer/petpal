// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poi_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

POI _$POIFromJson(Map<String, dynamic> json) {
  return _POI.fromJson(json);
}

/// @nodoc
mixin _$POI {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  POIType get type => throw _privateConstructorUsedError;
  bool get isEmergency => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  double get rating => throw _privateConstructorUsedError;
  int get reviewCount => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  String? get phoneNumber => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;

  /// Serializes this POI to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of POI
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $POICopyWith<POI> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $POICopyWith<$Res> {
  factory $POICopyWith(POI value, $Res Function(POI) then) =
      _$POICopyWithImpl<$Res, POI>;
  @useResult
  $Res call(
      {String id,
      String name,
      POIType type,
      bool isEmergency,
      double latitude,
      double longitude,
      double rating,
      int reviewCount,
      String? imageUrl,
      String? address,
      String? phoneNumber,
      List<String> tags});
}

/// @nodoc
class _$POICopyWithImpl<$Res, $Val extends POI> implements $POICopyWith<$Res> {
  _$POICopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of POI
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? isEmergency = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? rating = null,
    Object? reviewCount = null,
    Object? imageUrl = freezed,
    Object? address = freezed,
    Object? phoneNumber = freezed,
    Object? tags = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as POIType,
      isEmergency: null == isEmergency
          ? _value.isEmergency
          : isEmergency // ignore: cast_nullable_to_non_nullable
              as bool,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double,
      reviewCount: null == reviewCount
          ? _value.reviewCount
          : reviewCount // ignore: cast_nullable_to_non_nullable
              as int,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      phoneNumber: freezed == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$POIImplCopyWith<$Res> implements $POICopyWith<$Res> {
  factory _$$POIImplCopyWith(_$POIImpl value, $Res Function(_$POIImpl) then) =
      __$$POIImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      POIType type,
      bool isEmergency,
      double latitude,
      double longitude,
      double rating,
      int reviewCount,
      String? imageUrl,
      String? address,
      String? phoneNumber,
      List<String> tags});
}

/// @nodoc
class __$$POIImplCopyWithImpl<$Res> extends _$POICopyWithImpl<$Res, _$POIImpl>
    implements _$$POIImplCopyWith<$Res> {
  __$$POIImplCopyWithImpl(_$POIImpl _value, $Res Function(_$POIImpl) _then)
      : super(_value, _then);

  /// Create a copy of POI
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? isEmergency = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? rating = null,
    Object? reviewCount = null,
    Object? imageUrl = freezed,
    Object? address = freezed,
    Object? phoneNumber = freezed,
    Object? tags = null,
  }) {
    return _then(_$POIImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as POIType,
      isEmergency: null == isEmergency
          ? _value.isEmergency
          : isEmergency // ignore: cast_nullable_to_non_nullable
              as bool,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double,
      reviewCount: null == reviewCount
          ? _value.reviewCount
          : reviewCount // ignore: cast_nullable_to_non_nullable
              as int,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      phoneNumber: freezed == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$POIImpl implements _POI {
  const _$POIImpl(
      {required this.id,
      required this.name,
      required this.type,
      this.isEmergency = false,
      required this.latitude,
      required this.longitude,
      this.rating = 0.0,
      this.reviewCount = 0,
      this.imageUrl,
      this.address,
      this.phoneNumber,
      final List<String> tags = const []})
      : _tags = tags;

  factory _$POIImpl.fromJson(Map<String, dynamic> json) =>
      _$$POIImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final POIType type;
  @override
  @JsonKey()
  final bool isEmergency;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  @JsonKey()
  final double rating;
  @override
  @JsonKey()
  final int reviewCount;
  @override
  final String? imageUrl;
  @override
  final String? address;
  @override
  final String? phoneNumber;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'POI(id: $id, name: $name, type: $type, isEmergency: $isEmergency, latitude: $latitude, longitude: $longitude, rating: $rating, reviewCount: $reviewCount, imageUrl: $imageUrl, address: $address, phoneNumber: $phoneNumber, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$POIImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.isEmergency, isEmergency) ||
                other.isEmergency == isEmergency) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.reviewCount, reviewCount) ||
                other.reviewCount == reviewCount) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      type,
      isEmergency,
      latitude,
      longitude,
      rating,
      reviewCount,
      imageUrl,
      address,
      phoneNumber,
      const DeepCollectionEquality().hash(_tags));

  /// Create a copy of POI
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$POIImplCopyWith<_$POIImpl> get copyWith =>
      __$$POIImplCopyWithImpl<_$POIImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$POIImplToJson(
      this,
    );
  }
}

abstract class _POI implements POI {
  const factory _POI(
      {required final String id,
      required final String name,
      required final POIType type,
      final bool isEmergency,
      required final double latitude,
      required final double longitude,
      final double rating,
      final int reviewCount,
      final String? imageUrl,
      final String? address,
      final String? phoneNumber,
      final List<String> tags}) = _$POIImpl;

  factory _POI.fromJson(Map<String, dynamic> json) = _$POIImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  POIType get type;
  @override
  bool get isEmergency;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  double get rating;
  @override
  int get reviewCount;
  @override
  String? get imageUrl;
  @override
  String? get address;
  @override
  String? get phoneNumber;
  @override
  List<String> get tags;

  /// Create a copy of POI
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$POIImplCopyWith<_$POIImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
