import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/sitting/data/models/sitting_request_model.dart';

class SittingRemoteDatasource {
  final FirebaseFirestore _firestore;

  SittingRemoteDatasource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference get _requestsRef =>
      _firestore.collection('sitting_requests');

  Stream<List<SittingRequestModel>> watchRequests(String ownerUid) {
    return _requestsRef
        .where('ownerUid', isEqualTo: ownerUid)
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

  Future<void> deleteRequest(String requestId) async {
    await _requestsRef.doc(requestId).delete();
  }
}
