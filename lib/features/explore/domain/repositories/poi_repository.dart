import '../entities/poi_model.dart';

abstract class POIRepository {
  Future<List<POI>> getNearbyPOIs({
    required double latitude,
    required double longitude,
    POIType? type,
  });

  /// Fetch a single POI by its document ID.
  /// Returns null when the ID does not exist in Firestore (or mock data).
  Future<POI?> getPOIById(String id);

  Stream<List<POI>> watchAllPOIs();
}
