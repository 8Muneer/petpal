import 'dart:math' as math;

/// Returns the great-circle distance in kilometres between two geographic
/// coordinates using the Haversine formula.
///
/// This is the single shared implementation — do not duplicate it.
/// Previously this was copy-pasted in poi_repository_impl.dart and
/// poi_detail_screen.dart, which meant fixes to one copy would not
/// propagate to the other.
double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const p = 0.017453292519943295; // π / 180
  final a = 0.5 -
      math.cos((lat2 - lat1) * p) / 2 +
      math.cos(lat1 * p) *
          math.cos(lat2 * p) *
          (1 - math.cos((lon2 - lon1) * p)) /
          2;
  return 12742 * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
}

/// Formats a distance in kilometres into a human-readable Hebrew string.
/// Under 1 km → metres (e.g. "350 מ' ממך").
/// 1 km and above → one decimal (e.g. "2.4 ק\"מ ממך").
String formatDistance(double km) {
  if (km < 1.0) {
    final meters = (km * 1000).round();
    return "$meters מ' ממך";
  }
  return '${km.toStringAsFixed(1)} ק"מ ממך';
}
