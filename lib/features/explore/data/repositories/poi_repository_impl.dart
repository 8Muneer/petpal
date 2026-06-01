import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/poi_model.dart';
import '../../domain/repositories/poi_repository.dart';

class POIRepositoryImpl implements POIRepository {
  final FirebaseFirestore _firestore;

  POIRepositoryImpl(this._firestore);

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) *
        (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a.clamp(0.0, 1.0))); // Distance in km
  }

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

    List<POI> results = [];
    try {
      final snapshot = await query.get();
      results = snapshot.docs.map((doc) => POI.fromFirestore(doc)).toList();
    } catch (_) {
      // If Firestore fails or collection does not exist, results remains empty and falls back to mock
    }
    
    // Fallback to mock data if Firestore is empty
    if (results.isEmpty) {
      final mockData = [
        const POI(id: 'mock1', name: 'גן מאיר (גינת כלבים)', type: POIType.park, latitude: 32.0747, longitude: 34.7733, rating: 4.8, reviewCount: 120, tags: ['מרכזי', 'חולי', 'מוצל'], address: 'המלך ג׳ורג׳, תל אביב', imageUrl: 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&q=80&w=800'),
        const POI(id: 'mock2', name: 'גינת כלבים פארק הירקון', type: POIType.park, latitude: 32.0988, longitude: 34.8094, rating: 4.9, reviewCount: 350, tags: ['ענק', 'דשא', 'על המים'], address: 'גני יהושע, תל אביב', imageUrl: 'https://images.unsplash.com/photo-1601758124510-52d02ddb7cbd?auto=format&fit=crop&q=80&w=800'),
        const POI(id: 'mock3', name: 'בית חולים וטרינרי תורן (חירום)', type: POIType.vet, latitude: 32.0853, longitude: 34.7818, rating: 4.7, reviewCount: 85, tags: ['24/7', 'מומחים', 'כירורגיה'], address: 'אבן גבירול, תל אביב', isEmergency: true, phoneNumber: '03-1234567', imageUrl: 'https://images.unsplash.com/photo-1628033033580-0a14917a02c8?auto=format&fit=crop&q=80&w=800'),
        const POI(id: 'mock4', name: 'מרפאה וטרינרית ד"ר דוליטל', type: POIType.vet, latitude: 32.0625, longitude: 34.7711, rating: 4.5, reviewCount: 42, tags: ['חיסונים', 'יחס אישי'], address: 'רוטשילד, תל אביב', imageUrl: 'https://images.unsplash.com/photo-1537151608828-ea2b11777ee8?auto=format&fit=crop&q=80&w=800'),
        const POI(id: 'mock5', name: 'פט-ביי (חנות חיות)', type: POIType.store, latitude: 32.0722, longitude: 34.7822, rating: 4.6, reviewCount: 156, tags: ['משלוחים', 'מזון רפואי'], address: 'דיזנגוף, תל אביב', imageUrl: 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&q=80&w=800'),
        const POI(id: 'mock6', name: 'אנימל-שופ', type: POIType.store, latitude: 32.0455, longitude: 34.7555, rating: 4.4, reviewCount: 98, tags: ['זול', 'ציוד מקצועי'], address: 'יפו, תל אביב', imageUrl: 'https://images.unsplash.com/photo-1591768793355-74d7ca7fb9c4?auto=format&fit=crop&q=80&w=800'),
      ];
      
      final filtered = type != null
          ? mockData.where((p) => p.type == type).toList()
          : List<POI>.from(mockData);
          
      filtered.sort((a, b) {
        final distA = _calculateDistance(latitude, longitude, a.latitude, a.longitude);
        final distB = _calculateDistance(latitude, longitude, b.latitude, b.longitude);
        return distA.compareTo(distB);
      });
      return filtered;
    }
    
    results.sort((a, b) {
      final distA = _calculateDistance(latitude, longitude, a.latitude, a.longitude);
      final distB = _calculateDistance(latitude, longitude, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });
    return results;
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
