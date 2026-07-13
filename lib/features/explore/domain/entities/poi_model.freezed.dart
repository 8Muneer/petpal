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
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  double get rating => throw _privateConstructorUsedError;
  int get reviewCount => throw _privateConstructorUsedError;
  String? get imageUrl =>
      throw _privateConstructorUsedError; // All photo URLs for this POI, in display order. `imageUrl` above is kept
// for backward compatibility with old documents/consumers and is treated
// as this list's first entry when both are present.
  List<String> get imageUrls => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  String? get phoneNumber => throw _privateConstructorUsedError;
  List<String> get tags =>
      throw _privateConstructorUsedError; // ── Extended metadata ──
  String? get description => throw _privateConstructorUsedError;
  String? get website => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;

  /// True for places open around the clock (e.g. emergency vets, parks).
  bool get open24h => throw _privateConstructorUsedError;

  /// Weekly opening hours keyed by day (sun..sat). Value is "HH:MM-HH:MM",
  /// or absent/empty when the place is closed that day.
  Map<String, String> get openingHours => throw _privateConstructorUsedError;

  /// Type-specific services / amenities (vet services, store categories,
  /// park amenities).
  List<String> get services => throw _privateConstructorUsedError;

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
      double? latitude,
      double? longitude,
      double rating,
      int reviewCount,
      String? imageUrl,
      List<String> imageUrls,
      String? address,
      String? phoneNumber,
      List<String> tags,
      String? description,
      String? website,
      String? email,
      bool open24h,
      Map<String, String> openingHours,
      List<String> services});
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
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? rating = null,
    Object? reviewCount = null,
    Object? imageUrl = freezed,
    Object? imageUrls = null,
    Object? address = freezed,
    Object? phoneNumber = freezed,
    Object? tags = null,
    Object? description = freezed,
    Object? website = freezed,
    Object? email = freezed,
    Object? open24h = null,
    Object? openingHours = null,
    Object? services = null,
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
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
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
      imageUrls: null == imageUrls
          ? _value.imageUrls
          : imageUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
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
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      website: freezed == website
          ? _value.website
          : website // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      open24h: null == open24h
          ? _value.open24h
          : open24h // ignore: cast_nullable_to_non_nullable
              as bool,
      openingHours: null == openingHours
          ? _value.openingHours
          : openingHours // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      services: null == services
          ? _value.services
          : services // ignore: cast_nullable_to_non_nullable
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
      double? latitude,
      double? longitude,
      double rating,
      int reviewCount,
      String? imageUrl,
      List<String> imageUrls,
      String? address,
      String? phoneNumber,
      List<String> tags,
      String? description,
      String? website,
      String? email,
      bool open24h,
      Map<String, String> openingHours,
      List<String> services});
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
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? rating = null,
    Object? reviewCount = null,
    Object? imageUrl = freezed,
    Object? imageUrls = null,
    Object? address = freezed,
    Object? phoneNumber = freezed,
    Object? tags = null,
    Object? description = freezed,
    Object? website = freezed,
    Object? email = freezed,
    Object? open24h = null,
    Object? openingHours = null,
    Object? services = null,
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
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
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
      imageUrls: null == imageUrls
          ? _value._imageUrls
          : imageUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
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
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      website: freezed == website
          ? _value.website
          : website // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      open24h: null == open24h
          ? _value.open24h
          : open24h // ignore: cast_nullable_to_non_nullable
              as bool,
      openingHours: null == openingHours
          ? _value._openingHours
          : openingHours // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      services: null == services
          ? _value._services
          : services // ignore: cast_nullable_to_non_nullable
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
      this.latitude,
      this.longitude,
      this.rating = 0.0,
      this.reviewCount = 0,
      this.imageUrl,
      final List<String> imageUrls = const [],
      this.address,
      this.phoneNumber,
      final List<String> tags = const [],
      this.description,
      this.website,
      this.email,
      this.open24h = false,
      final Map<String, String> openingHours = const {},
      final List<String> services = const []})
      : _imageUrls = imageUrls,
        _tags = tags,
        _openingHours = openingHours,
        _services = services;

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
  final double? latitude;
  @override
  final double? longitude;
  @override
  @JsonKey()
  final double rating;
  @override
  @JsonKey()
  final int reviewCount;
  @override
  final String? imageUrl;
// All photo URLs for this POI, in display order. `imageUrl` above is kept
// for backward compatibility with old documents/consumers and is treated
// as this list's first entry when both are present.
  final List<String> _imageUrls;
// All photo URLs for this POI, in display order. `imageUrl` above is kept
// for backward compatibility with old documents/consumers and is treated
// as this list's first entry when both are present.
  @override
  @JsonKey()
  List<String> get imageUrls {
    if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_imageUrls);
  }

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

// ── Extended metadata ──
  @override
  final String? description;
  @override
  final String? website;
  @override
  final String? email;

  /// True for places open around the clock (e.g. emergency vets, parks).
  @override
  @JsonKey()
  final bool open24h;

  /// Weekly opening hours keyed by day (sun..sat). Value is "HH:MM-HH:MM",
  /// or absent/empty when the place is closed that day.
  final Map<String, String> _openingHours;

  /// Weekly opening hours keyed by day (sun..sat). Value is "HH:MM-HH:MM",
  /// or absent/empty when the place is closed that day.
  @override
  @JsonKey()
  Map<String, String> get openingHours {
    if (_openingHours is EqualUnmodifiableMapView) return _openingHours;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_openingHours);
  }

  /// Type-specific services / amenities (vet services, store categories,
  /// park amenities).
  final List<String> _services;

  /// Type-specific services / amenities (vet services, store categories,
  /// park amenities).
  @override
  @JsonKey()
  List<String> get services {
    if (_services is EqualUnmodifiableListView) return _services;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_services);
  }

  @override
  String toString() {
    return 'POI(id: $id, name: $name, type: $type, isEmergency: $isEmergency, latitude: $latitude, longitude: $longitude, rating: $rating, reviewCount: $reviewCount, imageUrl: $imageUrl, imageUrls: $imageUrls, address: $address, phoneNumber: $phoneNumber, tags: $tags, description: $description, website: $website, email: $email, open24h: $open24h, openingHours: $openingHours, services: $services)';
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
            const DeepCollectionEquality()
                .equals(other._imageUrls, _imageUrls) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.website, website) || other.website == website) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.open24h, open24h) || other.open24h == open24h) &&
            const DeepCollectionEquality()
                .equals(other._openingHours, _openingHours) &&
            const DeepCollectionEquality().equals(other._services, _services));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
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
        const DeepCollectionEquality().hash(_imageUrls),
        address,
        phoneNumber,
        const DeepCollectionEquality().hash(_tags),
        description,
        website,
        email,
        open24h,
        const DeepCollectionEquality().hash(_openingHours),
        const DeepCollectionEquality().hash(_services)
      ]);

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
      final double? latitude,
      final double? longitude,
      final double rating,
      final int reviewCount,
      final String? imageUrl,
      final List<String> imageUrls,
      final String? address,
      final String? phoneNumber,
      final List<String> tags,
      final String? description,
      final String? website,
      final String? email,
      final bool open24h,
      final Map<String, String> openingHours,
      final List<String> services}) = _$POIImpl;

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
  double? get latitude;
  @override
  double? get longitude;
  @override
  double get rating;
  @override
  int get reviewCount;
  @override
  String?
      get imageUrl; // All photo URLs for this POI, in display order. `imageUrl` above is kept
// for backward compatibility with old documents/consumers and is treated
// as this list's first entry when both are present.
  @override
  List<String> get imageUrls;
  @override
  String? get address;
  @override
  String? get phoneNumber;
  @override
  List<String> get tags; // ── Extended metadata ──
  @override
  String? get description;
  @override
  String? get website;
  @override
  String? get email;

  /// True for places open around the clock (e.g. emergency vets, parks).
  @override
  bool get open24h;

  /// Weekly opening hours keyed by day (sun..sat). Value is "HH:MM-HH:MM",
  /// or absent/empty when the place is closed that day.
  @override
  Map<String, String> get openingHours;

  /// Type-specific services / amenities (vet services, store categories,
  /// park amenities).
  @override
  List<String> get services;

  /// Create a copy of POI
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$POIImplCopyWith<_$POIImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
