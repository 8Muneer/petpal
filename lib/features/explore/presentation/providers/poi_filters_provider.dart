import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/features/explore/domain/entities/poi_model.dart';

/// Immutable snapshot of all active POI filters.
///
/// Holding all dimensions in one object means a single [clearAll] call resets
/// every filter at once, and the active-filter count badge is always accurate.
class PoiFilters {
  /// Optional type override for non-tab contexts (e.g. a search view that
  /// shows all types and lets the user narrow down with a chip).
  /// The tab-based explore screen passes type directly to nearbyPOIsProvider
  /// and ignores this field — both patterns are valid.
  final POIType? type;

  final double? minRating;
  final bool hasReviewsOnly;

  const PoiFilters({
    this.type,
    this.minRating,
    this.hasReviewsOnly = false,
  });

  bool get hasActiveFilters => type != null || minRating != null || hasReviewsOnly;

  /// Count of active filter dimensions — drives the badge on the filter button.
  int get activeCount =>
      (type != null ? 1 : 0) +
      (minRating != null ? 1 : 0) +
      (hasReviewsOnly ? 1 : 0);
}

class PoiFiltersNotifier extends Notifier<PoiFilters> {
  @override
  PoiFilters build() => const PoiFilters();

  void setType(POIType? t) => state = PoiFilters(
        type: t,
        minRating: state.minRating,
        hasReviewsOnly: state.hasReviewsOnly,
      );

  void updateMinRating(double? rating) => state = PoiFilters(
        type: state.type,
        minRating: rating,
        hasReviewsOnly: state.hasReviewsOnly,
      );

  void updateHasReviewsOnly(bool value) => state = PoiFilters(
        type: state.type,
        minRating: state.minRating,
        hasReviewsOnly: value,
      );

  /// Resets ALL filter dimensions at once.
  ///
  /// Previously only [updateMinRating] and [updateHasReviewsOnly] were
  /// available, so callers had to make two separate state mutations to "clear."
  /// This single method is the canonical way to wipe all active filters.
  void clearAll() => state = const PoiFilters();
}

final poiFiltersProvider =
    NotifierProvider<PoiFiltersNotifier, PoiFilters>(PoiFiltersNotifier.new);
