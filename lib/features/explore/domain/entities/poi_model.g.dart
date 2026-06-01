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
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String?,
      address: json['address'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
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
    };

const _$POITypeEnumMap = {
  POIType.park: 'park',
  POIType.vet: 'vet',
  POIType.store: 'store',
};
