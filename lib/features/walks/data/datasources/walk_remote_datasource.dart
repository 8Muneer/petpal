import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/walks/data/models/walk_request_model.dart';
import 'package:petpal/features/walks/data/models/walk_service_model.dart';

class WalkRemoteDatasource {
  final FirebaseFirestore _firestore;

  WalkRemoteDatasource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference get _requestsRef =>
      _firestore.collection('walk_requests');

  Stream<List<WalkRequestModel>> watchRequests(String ownerUid) {
    return _requestsRef
        .where('ownerUid', isEqualTo: ownerUid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => WalkRequestModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<WalkRequestModel>> watchAllOpenRequests() {
    return _requestsRef
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => WalkRequestModel.fromFirestore(doc))
            .toList());
  }

  Future<String> createRequest(Map<String, dynamic> data) async {
    final doc = await _requestsRef.add(data);
    return doc.id;
  }

  Future<void> updateRequest(String requestId, Map<String, dynamic> data) async {
    await _requestsRef.doc(requestId).update(data);
  }

  Future<void> deleteRequest(String requestId) async {
    await _requestsRef.doc(requestId).delete();
  }

  CollectionReference get _servicesRef =>
      _firestore.collection('walk_services');

  Stream<List<WalkServiceModel>> watchWalkServices() {
    return _servicesRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => WalkServiceModel.fromFirestore(doc)).toList());
  }

  Stream<List<WalkServiceModel>> watchMyServices(String providerUid) {
    return _servicesRef
        .where('providerUid', isEqualTo: providerUid)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => WalkServiceModel.fromFirestore(doc)).toList());
  }

  Future<String> createWalkService(Map<String, dynamic> data) async {
    final doc = await _servicesRef.add(data);
    return doc.id;
  }

  Future<void> updateWalkService(String serviceId, Map<String, dynamic> data) async {
    await _servicesRef.doc(serviceId).update(data);
  }

  Future<void> deleteWalkService(String serviceId) async {
    await _servicesRef.doc(serviceId).delete();
  }
}
