import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/utils/geo.dart';
import '../../domain/entities/poi_model.dart';
import '../../domain/repositories/poi_repository.dart';

// ---------------------------------------------------------------------------
// Dev mock data
// Shown only when Firestore succeeds but the collection is genuinely empty
// (fresh dev environment). Never shown when Firestore returns an error.
// ---------------------------------------------------------------------------
const List<POI> _mockPOIs = [
  POI(id: 'mock1', name: 'גן מאיר (גינת כלבים)', type: POIType.park, latitude: 32.0747, longitude: 34.7733, rating: 4.8, reviewCount: 120, tags: ['מרכזי', 'חולי', 'מוצל'], address: 'המלך ג׳ורג׳, תל אביב', imageUrl: 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&q=80&w=800'),
  POI(id: 'mock2', name: 'גינת כלבים פארק הירקון', type: POIType.park, latitude: 32.0988, longitude: 34.8094, rating: 4.9, reviewCount: 350, tags: ['ענק', 'דשא', 'על המים'], address: 'גני יהושע, תל אביב', imageUrl: 'https://images.unsplash.com/photo-1601758124510-52d02ddb7cbd?auto=format&fit=crop&q=80&w=800'),
  POI(id: 'mock3', name: 'בית חולים וטרינרי תורן (חירום)', type: POIType.vet, latitude: 32.0853, longitude: 34.7818, rating: 4.7, reviewCount: 85, tags: ['24/7', 'מומחים', 'כירורגיה'], address: 'אבן גבירול, תל אביב', isEmergency: true, phoneNumber: '03-1234567', imageUrl: 'https://images.unsplash.com/photo-1628033033580-0a14917a02c8?auto=format&fit=crop&q=80&w=800'),
  POI(id: 'mock4', name: 'מרפאה וטרינרית ד"ר דוליטל', type: POIType.vet, latitude: 32.0625, longitude: 34.7711, rating: 4.5, reviewCount: 42, tags: ['חיסונים', 'יחס אישי'], address: 'רוטשילד, תל אביב', imageUrl: 'https://images.unsplash.com/photo-1537151608828-ea2b11777ee8?auto=format&fit=crop&q=80&w=800'),
  POI(id: 'mock5', name: 'פט-ביי (חנות חיות)', type: POIType.store, latitude: 32.0722, longitude: 34.7822, rating: 4.6, reviewCount: 156, tags: ['משלוחים', 'מזון רפואי'], address: 'דיזנגוף, תל אביב', imageUrl: 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&q=80&w=800'),
  POI(id: 'mock6', name: 'אנימל-שופ', type: POIType.store, latitude: 32.0455, longitude: 34.7555, rating: 4.4, reviewCount: 98, tags: ['זול', 'ציוד מקצועי'], address: 'יפו, תל אביב', imageUrl: 'https://images.unsplash.com/photo-1591768793355-74d7ca7fb9c4?auto=format&fit=crop&q=80&w=800'),
];

// Maximum number of documents fetched per query. Without a geo-bounding box
// Firestore can't filter by radius server-side, so we cap the download and
// sort client-side. TODO(phase3): replace with a proper geo-query (e.g.
// GeoFlutterFire) that uses a geohash bounding box before applying this limit.
const int _kNearbyLimit = 200;

class POIRepositoryImpl implements POIRepository {
  final FirebaseFirestore _firestore;

  POIRepositoryImpl(this._firestore);

  @override
  Future<List<POI>> getNearbyPOIs({
    required double latitude,
    required double longitude,
    POIType? type,
  }) async {
    Query query = _firestore.collection('pois');

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    // Cap the download to _kNearbyLimit documents. Client-side distance sort
    // means we get the N cheapest-to-fetch docs, not the N closest ones — a
    // known limitation until geo-queries are added in Phase 3.
    query = query.limit(_kNearbyLimit);

    List<POI> results = [];
    bool firestoreFailed = false;

    try {
      final snapshot = await query.get();
      results = snapshot.docs.map((doc) => POI.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      // Firestore-specific errors (permission denied, unavailable, quota exceeded)
      // — surface them in the console instead of masking them with mock data.
      // ignore: avoid_print
      print('[POIRepository] Firestore error (${e.code}): ${e.message}');
      firestoreFailed = true;
    } catch (e) {
      // ignore: avoid_print
      print('[POIRepository] Unexpected error fetching POIs: $e');
      firestoreFailed = true;
    }

    // Firestore failed → return empty so the UI shows an error state, not mock data.
    if (firestoreFailed) return [];

    // Firestore succeeded but collection is empty → show mock data for dev.
    if (results.isEmpty) {
      final filtered = type != null
          ? _mockPOIs.where((p) => p.type == type).toList()
          : List<POI>.from(_mockPOIs);

      filtered.sort((a, b) => _compareByDistance(a, b, latitude, longitude));
      return filtered;
    }

    results.sort((a, b) => _compareByDistance(a, b, latitude, longitude));
    return results;
  }

  /// Sorts two POIs by distance from the user, with null-coordinate POIs
  /// always placed at the end — they have no known location so ranking them
  /// by distance is meaningless, but they should still appear in the list.
  int _compareByDistance(POI a, POI b, double userLat, double userLng) {
    final aHasCoords = a.latitude != null && a.longitude != null;
    final bHasCoords = b.latitude != null && b.longitude != null;
    if (!aHasCoords && !bHasCoords) return 0;
    if (!aHasCoords) return 1;  // a has no coords → sort after b
    if (!bHasCoords) return -1; // b has no coords → sort after a
    final distA = distanceKm(userLat, userLng, a.latitude!, a.longitude!);
    final distB = distanceKm(userLat, userLng, b.latitude!, b.longitude!);
    return distA.compareTo(distB);
  }

  @override
  Future<POI?> getPOIById(String id) async {
    // Fast path: fetch the single document directly by ID instead of scanning
    // the entire nearby list. This fixes the "place not found" bug that occurred
    // when the requested POI wasn't included in the current nearby page.
    try {
      final doc = await _firestore.collection('pois').doc(id).get();

      if (doc.exists) {
        return POI.fromFirestore(doc);
      }
    } on FirebaseException catch (e) {
      // ignore: avoid_print
      print('[POIRepository] getPOIById Firestore error (${e.code}): ${e.message}');
    } catch (e) {
      // ignore: avoid_print
      print('[POIRepository] getPOIById unexpected error: $e');
    }

    // Fall back to mock data — allows the detail screen to work in dev
    // environments where the Firestore collection is empty.
    try {
      return _mockPOIs.firstWhere((p) => p.id == id);
    } catch (_) {
      // firstWhere throws StateError when no element matches — return null.
      return null;
    }
  }

  @override
  Stream<List<POI>> watchAllPOIs() {
    return _firestore
        .collection('pois')
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => POI.fromFirestore(doc)).toList());
  }
}

final poiRepositoryProvider = Provider<POIRepository>((ref) {
  return POIRepositoryImpl(FirebaseFirestore.instance);
});
