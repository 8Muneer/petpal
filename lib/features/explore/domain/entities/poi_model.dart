import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'poi_model.freezed.dart';
part 'poi_model.g.dart';

enum POIType {
  park,
  vet,
  store,
}

@freezed
class POI with _$POI {
  const factory POI({
    required String id,
    required String name,
    required POIType type,
    @Default(false) bool isEmergency,
    required double latitude,
    required double longitude,
    @Default(0.0) double rating,
    @Default(0) int reviewCount,
    String? imageUrl,
    String? address,
    String? phoneNumber,
    @Default([]) List<String> tags,
    // ── Extended metadata ──
    String? description,
    String? website,
    String? email,

    /// True for places open around the clock (e.g. emergency vets, parks).
    @Default(false) bool open24h,

    /// Weekly opening hours keyed by day (sun..sat). Value is "HH:MM-HH:MM",
    /// or absent/empty when the place is closed that day.
    @Default({}) Map<String, String> openingHours,

    /// Type-specific services / amenities (vet services, store categories,
    /// park amenities).
    @Default([]) List<String> services,
  }) = _POI;

  factory POI.fromJson(Map<String, dynamic> json) => _$POIFromJson(json);

  factory POI.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return POI.fromJson({
      ...data,
      'id': doc.id,
    });
  }
}
