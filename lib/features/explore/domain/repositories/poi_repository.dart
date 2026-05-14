import '../entities/poi_model.dart';

abstract class POIRepository {
  Future<List<POI>> getNearbyPOIs({
    required double latitude,
    required double longitude,
    POIType? type,
  });

  Stream<List<POI>> watchAllPOIs();
}
