import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/features/admin/domain/entities/verification_request.dart';
import 'package:petpal/features/explore/domain/entities/poi_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository(this._firestore);

  // --- Dashboard Stats ---
  Future<Map<String, int>> getAdminStats() async {
    final usersCount = await _firestore.collection('users').count().get();
    final pendingVerifications = await _firestore
        .collection('verification_requests')
        .where('status', isEqualTo: 'pending')
        .count()
        .get();
    final poisCount = await _firestore.collection('pois').count().get();
    final reportsCount = await _firestore
        .collection('reports')
        .where('status', isEqualTo: 'open')
        .count()
        .get();

    return {
      'totalUsers': usersCount.count ?? 0,
      'pendingVerifications': pendingVerifications.count ?? 0,
      'totalPois': poisCount.count ?? 0,
      'openReports': reportsCount.count ?? 0,
    };
  }

  // --- POI Management ---
  Future<void> savePOI(POI poi) async {
    final docRef =
        _firestore.collection('pois').doc(poi.id.isEmpty ? null : poi.id);
    await docRef.set({
      'name': poi.name,
      'type': poi.type.name,
      'latitude': poi.latitude,
      'longitude': poi.longitude,
      'rating': poi.rating,
      'reviewCount': poi.reviewCount,
      'imageUrl': poi.imageUrl,
      'address': poi.address,
      'phoneNumber': poi.phoneNumber,
      'isEmergency': poi.isEmergency,
      'tags': poi.tags,
      'description': poi.description,
      'website': poi.website,
      'email': poi.email,
      'open24h': poi.open24h,
      'openingHours': poi.openingHours,
      'services': poi.services,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deletePOI(String poiId) async {
    await _firestore.collection('pois').doc(poiId).delete();
  }

  Stream<List<POI>> watchAllPOIs() {
    return _firestore
        .collection('pois')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => POI.fromFirestore(doc)).toList());
  }

  // --- User Oversight ---
  Stream<List<Map<String, dynamic>>> watchAllUsers() {
    return _firestore.collection('users').orderBy('name').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'uid': doc.id})
            .toList());
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': isActive,
    });
  }

  Future<void> adjustUserKarma(String userId, int delta) async {
    await _firestore.collection('users').doc(userId).update({
      'karma': FieldValue.increment(delta),
    });
  }

  // --- Sitter Verification ---
  Stream<List<VerificationRequest>> watchPendingVerifications() {
    return _firestore
        .collection('verification_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VerificationRequest.fromFirestore(doc))
            .toList());
  }

  Future<void> updateVerificationStatus({
    required String requestId,
    required String userId,
    required String status,
    String? notes,
    required String adminId,
  }) async {
    final batch = _firestore.batch();

    // Update the request
    batch
        .update(_firestore.collection('verification_requests').doc(requestId), {
      'status': status,
      'notes': notes,
      'reviewedBy': adminId,
      'resolvedAt': FieldValue.serverTimestamp(),
    });

    // If approved, update the user's verified status
    if (status == 'approved') {
      batch.update(_firestore.collection('users').doc(userId), {
        'isVerified': true,
      });
    }

    await batch.commit();
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(FirebaseFirestore.instance);
});
