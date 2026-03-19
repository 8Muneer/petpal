import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/walks/data/models/walk_request_model.dart';

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
}
