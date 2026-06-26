// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poi_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$POIImpl _$$POIImplFromJson(Map<String, dynamic> json) => _$POIImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$POITypeEnumMap, json['type']),
      isEmergency: json['isEmergency'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String?,
      address: json['address'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      description: json['description'] as String?,
      website: json['website'] as String?,
      email: json['email'] as String?,
      open24h: json['open24h'] as bool? ?? false,
      openingHours: (json['openingHours'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$POIImplToJson(_$POIImpl instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$POITypeEnumMap[instance.type]!,
      'isEmergency': instance.isEmergency,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'rating': instance.rating,
      'reviewCount': instance.reviewCount,
      'imageUrl': instance.imageUrl,
      'address': instance.address,
      'phoneNumber': instance.phoneNumber,
      'tags': instance.tags,
      'description': instance.description,
      'website': instance.website,
      'email': instance.email,
      'open24h': instance.open24h,
      'openingHours': instance.openingHours,
      'services': instance.services,
    };

const _$POITypeEnumMap = {
  POIType.park: 'park',
  POIType.vet: 'vet',
  POIType.store: 'store',
};
