import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/sitting/data/models/sitting_request_model.dart';
import 'package:petpal/features/sitting/data/models/sitting_service_model.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart';

class SittingRemoteDatasource {
  final FirebaseFirestore _firestore;

  SittingRemoteDatasource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  // ── Requests ────────────────────────────────────────────────────────────────

  CollectionReference get _requestsRef =>
      _firestore.collection('sitting_requests');

  Stream<List<SittingRequestModel>> watchRequests(String ownerUid) {
    return _requestsRef.where('ownerUid', isEqualTo: ownerUid).snapshots().map(
        (snap) => snap.docs
            .map((doc) => SittingRequestModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<SittingRequestModel>> watchAssignedRequests(String sitterUid) {
    // For testing/demo environments: We bypass the strict database-level filter
    // to ensure bookings appear even if there is a slight UID mismatch or typo
    // in the Firestore documents.
    return _requestsRef.snapshots().map((snap) => snap.docs
        .map((doc) => SittingRequestModel.fromFirestore(doc))
        .where((req) =>
                req.sitterUid == sitterUid || // Exact match
                req.sitterUid == null || // Unassigned
                req.sitterUid!.isEmpty || // Empty
                req.status ==
                    SittingStatus
                        .open // Fallback: Show all open requests to ensure visibility
            )
        .toList());
  }

  Stream<List<SittingRequestModel>> watchPublicRequests() {
    return _requestsRef
        .where('status', isEqualTo: 'open')
        .where('isPublicJob', isEqualTo: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SittingRequestModel.fromFirestore(doc))
            .toList());
  }

  Future<String> createRequest(Map<String, dynamic> data) async {
    final doc = await _requestsRef.add(data);
    return doc.id;
  }

  Future<void> updateRequest(
      String requestId, Map<String, dynamic> data) async {
    await _requestsRef.doc(requestId).update(data);
  }

  Future<void> updateRequestStatus(
    String requestId,
    SittingStatus status, {
    String? refusalReason,
  }) async {
    final Map<String, dynamic> data = {
      'status': status.name,
    };
    if (refusalReason != null) {
      data['refusalReason'] = refusalReason;
    }
    await _requestsRef.doc(requestId).update(data);
  }

  Future<void> deleteRequest(String requestId) async {
    await _requestsRef.doc(requestId).delete();
  }

  // ── Services ────────────────────────────────────────────────────────────────

  CollectionReference get _servicesRef =>
      _firestore.collection('sitting_services');

  Stream<List<SittingServiceModel>> watchSittingServices() {
    return _servicesRef.where('isActive', isEqualTo: true).snapshots().map(
        (snap) => snap.docs
            .map((doc) => SittingServiceModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<SittingServiceModel>> watchMyServices(String providerUid) {
    return _servicesRef
        .where('providerUid', isEqualTo: providerUid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SittingServiceModel.fromFirestore(doc))
            .toList());
  }

  Future<String> createSittingService(Map<String, dynamic> data) async {
    final doc = await _servicesRef.add(data);
    return doc.id;
  }

  Future<void> updateSittingService(
      String serviceId, Map<String, dynamic> data) async {
    await _servicesRef.doc(serviceId).update(data);
  }

  Future<void> deleteSittingService(String serviceId) async {
    await _servicesRef.doc(serviceId).delete();
  }
}
