import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/poi_model.dart';
import '../../data/repositories/poi_repository_impl.dart';

part 'poi_provider.g.dart';

@riverpod
Future<List<POI>> nearbyPOIs(NearbyPOIsRef ref, {POIType? type}) async {
  final repository = ref.watch(poiRepositoryProvider);
  
  // Default location (Tel Aviv) for demonstration
  // In a real scenario, this would watch a locationProvider
  const double lat = 32.0853;
  const double lng = 34.7818;

  return repository.getNearbyPOIs(
    latitude: lat,
    longitude: lng,
    type: type,
  );
}

@riverpod
Stream<List<POI>> allPOIs(AllPOIsRef ref) {
  final repository = ref.watch(poiRepositoryProvider);
  return repository.watchAllPOIs();
}

@riverpod
Future<POI?> poiById(PoiByIdRef ref, String id) async {
  final all = await ref.watch(nearbyPOIsProvider().future);
  for (final p in all) {
    if (p.id == id) return p;
  }
  return null;
}

@riverpod
class POIFilter extends _$POIFilter {
  @override
  POIType? build() => null;

  void setType(POIType? type) => state = type;
}

@riverpod
Future<List<POI>> topRatedPOIs(TopRatedPOIsRef ref, {required POIType type}) async {
  final allPOIs = await ref.watch(nearbyPOIsProvider(type: type).future);
  final sorted = [...allPOIs]..sort((a, b) => b.rating.compareTo(a.rating));
  return sorted.take(10).toList();
}

final exploreTabIndexProvider = StateProvider<int>((ref) => 0);
