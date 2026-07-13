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
    double? latitude,
    double? longitude,
    @Default(0.0) double rating,
    @Default(0) int reviewCount,
    String? imageUrl,
    // All photo URLs for this POI, in display order. `imageUrl` above is kept
    // for backward compatibility with old documents/consumers and is treated
    // as this list's first entry when both are present.
    @Default([]) List<String> imageUrls,
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
    // doc.data() returns null when a document is deleted between the snapshot
    // emission and the time we iterate — guard against that to avoid CastError.
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    // Legacy documents only have the singular `imageUrl` field. Fall back to
    // wrapping it in a single-element list so old POIs still display via the
    // new `imageUrls`-based gallery UI.
    final rawImageUrls = data['imageUrls'];
    final imageUrls = (rawImageUrls is List && rawImageUrls.isNotEmpty)
        ? rawImageUrls.cast<String>()
        : (data['imageUrl'] is String && (data['imageUrl'] as String).isNotEmpty)
            ? [data['imageUrl'] as String]
            : <String>[];

    return POI.fromJson({
      ...data,
      'id': doc.id,
      'imageUrls': imageUrls,
    });
  }
}

/// Extension instead of an in-class getter so that the Freezed-generated
/// _$POIImpl concrete class does not need to implement this method.
///
/// Placing a getter inside the @freezed class body requires the private
/// `const POI._()` constructor AND a build_runner regeneration to include
/// the getter in _$POIImpl. An extension achieves identical call-site syntax
/// (`poi.effectiveIsEmergency`) without touching the generated file at all.
extension POIBadgeX on POI {
  /// Whether this POI should display the emergency badge.
  ///
  /// `isEmergency` is only semantically valid for vets — this enforces that
  /// invariant at read time so stale Firestore documents with
  /// `isEmergency: true` on a park or store never show the badge.
  bool get effectiveIsEmergency => type == POIType.vet && isEmergency;
}
