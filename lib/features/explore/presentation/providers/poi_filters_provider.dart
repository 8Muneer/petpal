import 'package:flutter_riverpod/flutter_riverpod.dart';

class PoiFilters {
  final double? minRating;
  final bool hasReviewsOnly;

  const PoiFilters({this.minRating, this.hasReviewsOnly = false});

  bool get hasActiveFilters => minRating != null || hasReviewsOnly;
  int get activeCount =>
      (minRating != null ? 1 : 0) + (hasReviewsOnly ? 1 : 0);
}

class PoiFiltersNotifier extends Notifier<PoiFilters> {
  @override
  PoiFilters build() => const PoiFilters();

  void updateMinRating(double? rating) =>
      state = PoiFilters(minRating: rating, hasReviewsOnly: state.hasReviewsOnly);

  void updateHasReviewsOnly(bool value) =>
      state = PoiFilters(minRating: state.minRating, hasReviewsOnly: value);

  void clear() => state = const PoiFilters();
}

final poiFiltersProvider =
    NotifierProvider<PoiFiltersNotifier, PoiFilters>(PoiFiltersNotifier.new);
