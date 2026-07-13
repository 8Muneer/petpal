import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

  /// Saves a POI and returns its Firestore document ID.
  /// For new POIs (poi.id is empty) Firestore auto-generates the ID and we
  /// return it so callers can use it immediately — e.g., to upload an image
  /// under the correct Storage path instead of a temporary placeholder.
  Future<String> savePOI(POI poi) async {
    final docRef =
        _firestore.collection('pois').doc(poi.id.isEmpty ? null : poi.id);

    // NOTE: 'rating' and 'reviewCount' are intentionally excluded here.
    // They are owned by the reviews sub-system and updated atomically when
    // users submit reviews. Writing them from the admin editor would overwrite
    // live review data with the stale snapshot from when the editor was opened.
    // Coordinates are optional. Writing `null` to Firestore stores a literal
    // null field, which is fine — the detail screen and distance sort both
    // handle null coords gracefully. We keep them in the map so that an admin
    // who clears the fields can actually remove coordinates from an existing doc.
    await docRef.set({
      'name': poi.name,
      'type': poi.type.name,
      'latitude': poi.latitude,   // null → stored as Firestore null
      'longitude': poi.longitude, // null → map section hidden in detail screen
      'imageUrl': poi.imageUrls.isNotEmpty ? poi.imageUrls.first : poi.imageUrl,
      'imageUrls': poi.imageUrls,
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

    return docRef.id;
  }

  /// Patches the imageUrl(s) fields on an existing POI document.
  /// Called after uploading images for a newly created POI, once we have
  /// the Firestore-assigned document ID.
  Future<void> updatePOIImageUrls(String poiId, List<String> imageUrls) async {
    await _firestore.collection('pois').doc(poiId).update({
      'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : null,
      'imageUrls': imageUrls,
    });
  }

  Future<void> deletePOI(String poiId) async {
    await _firestore.collection('pois').doc(poiId).delete();
  }

  Stream<List<POI>> watchAllPOIs() {
    // We order by 'name' (always present) instead of 'updatedAt'.
    // Firestore excludes documents from an orderBy query when the ordered field
    // is missing — so any POI seeded directly in the Firestore Console without
    // an 'updatedAt' field would silently vanish from the admin list.
    // 'name' is a required field on every POI, making this ordering safe for
    // both admin-created and console-seeded documents.
    return _firestore
        .collection('pois')
        .orderBy('name')
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

  /// Promotes or revokes admin via the setUserRole Cloud Function — never a
  /// direct Firestore write. The function verifies the caller is already an
  /// admin, refuses to demote the last remaining admin, and writes an audit
  /// log entry; firestore.rules excludes `role` from the client-update branch
  /// specifically so this is the only path that can change it.
  Future<void> setUserRole(String targetUid, String newRole) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('setUserRole');
    await callable.call({'targetUid': targetUid, 'newRole': newRole});
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
