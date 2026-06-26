import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/providers/location_provider.dart';
import '../../domain/entities/poi_model.dart';
import '../../data/repositories/poi_repository_impl.dart';
import 'poi_filters_provider.dart';

part 'poi_provider.g.dart';

@riverpod
Future<List<POI>> nearbyPOIs(NearbyPOIsRef ref, {POIType? type}) async {
  final repository = ref.watch(poiRepositoryProvider);

  // Watch the single locationProvider so all nearby-POI queries always use
  // the real device position. If location is unavailable the provider falls
  // back to Tel Aviv, so this never throws — it awaits at most 10 seconds.
  final location = await ref.watch(locationProvider.future);

  // Watch the unified filter state so this provider rebuilds automatically
  // when the user adjusts minRating or hasReviewsOnly — no polling needed.
  final filters = ref.watch(poiFiltersProvider);

  final all = await repository.getNearbyPOIs(
    latitude: location.lat,
    longitude: location.lng,
    type: type,
  );

  // Apply rating / reviews filters HERE in the provider layer, not in each
  // individual screen. Previously explore_screen.dart did a client-side
  // .where() pass after receiving the list — meaning the 200-doc Firestore
  // cap was applied first, then the filter shrunk the set further. Any POI
  // beyond position 200 that would have passed the filter was silently lost.
  // Moving the filter here keeps the logic in one place and makes it
  // consistent for every future consumer of nearbyPOIsProvider.
  return all.where((poi) {
    if (filters.minRating != null && poi.rating < filters.minRating!) {
      return false;
    }
    if (filters.hasReviewsOnly && poi.reviewCount == 0) return false;
    return true;
  }).toList();
}

@riverpod
Stream<List<POI>> allPOIs(AllPOIsRef ref) {
  final repository = ref.watch(poiRepositoryProvider);
  return repository.watchAllPOIs();
}

@riverpod
Future<POI?> poiById(PoiByIdRef ref, String id) async {
  final repository = ref.watch(poiRepositoryProvider);

  // Fetch the POI directly by document ID instead of scanning the nearby list.
  // The previous approach called nearbyPOIsProvider() (no type filter), which
  // created a separate uncached Firestore fetch and would return null for any
  // POI not present in that specific result page — causing "place not found"
  // on the detail screen.
  return repository.getPOIById(id);
}

// Deprecated: use poiFiltersProvider.setType() instead.
//
// This code-gen notifier pre-dates the unified PoiFilters model. The explore
// screen uses tab-based type selection (passing type directly as a parameter
// to nearbyPOIsProvider) so this notifier is never read by any current screen.
// It is kept here only to avoid regenerating poi_provider.g.dart, which would
// also regenerate all other providers in this file and risk unrelated diffs.
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
