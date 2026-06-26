import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's single source of truth for the user's current coordinates.
///
/// Returns a record `(lat, lng)` so callers don't need to import geolocator's
/// Position type — keeping the UI layer decoupled from the location package.
///
/// Permission flow:
///   1. Check current permission status.
///   2. If not granted, request it once.
///   3. If denied or services disabled → fall back to Tel Aviv center so the
///      app remains fully functional without location access.
///   4. On success → return the real GPS position.
final locationProvider = FutureProvider<({double lat, double lng})>((ref) async {
  // Step 1 — check whether location services are switched on at OS level.
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location service is off (airplane mode, battery saver, etc.).
    // Return the Tel Aviv fallback so POI distances still make sense
    // for the primary target audience.
    return _fallback;
  }

  // Step 2 — check / request runtime permission.
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    // Not yet decided — ask the user once.
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    // User refused or permanently blocked — fall back gracefully.
    return _fallback;
  }

  // Step 3 — fetch the real position.
  // LocationAccuracy.medium balances speed and battery drain.
  // timeLimit ensures we don't block forever if GPS takes too long to acquire.
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 10),
    );
    return (lat: position.latitude, lng: position.longitude);
  } catch (_) {
    // GPS timed out or hardware error — fall back rather than crash.
    return _fallback;
  }
});

/// Tel Aviv city center — used when the device has no GPS fix available.
const _fallback = (lat: 32.0853, lng: 34.7818);
