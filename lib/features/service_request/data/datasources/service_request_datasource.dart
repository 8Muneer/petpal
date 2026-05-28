import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/service_request/data/models/application_model.dart';
import 'package:petpal/features/service_request/data/models/service_request_model.dart';
import 'package:petpal/features/service_request/domain/entities/application.dart';
import 'package:petpal/features/service_request/domain/entities/service_request.dart';

class ServiceRequestDatasource {
  final FirebaseFirestore _db;

  ServiceRequestDatasource(this._db);

  CollectionReference get _col => _db.collection('service_requests');

  CollectionReference _apps(String requestId) =>
      _col.doc(requestId).collection('applications');

  // ── Pet Owner: create / manage own requests ────────────────────────────────

  Future<String> createRequest(ServiceRequestModel model) async {
    final ref = await _col.add(model.toFirestore());
    return ref.id;
  }

  Stream<List<ServiceRequestModel>> watchMyRequests(String ownerUid) {
    return _col
        .where('ownerUid', isEqualTo: ownerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ServiceRequestModel.fromFirestore).toList());
  }

  Future<void> cancelRequest(String id) =>
      _col.doc(id).update({'status': ServiceRequestStatus.cancelled.name});

  // ── Service Provider: browse open requests ─────────────────────────────────

  Stream<List<ServiceRequestModel>> watchOpenRequests({ServiceType? type}) {
    Query q = _col.where('status', isEqualTo: ServiceRequestStatus.open.name);
    if (type != null) q = q.where('serviceType', isEqualTo: type.name);
    return q
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(ServiceRequestModel.fromFirestore).toList());
  }

  // ── Applications ───────────────────────────────────────────────────────────

  /// Stream of all applications for a given request (PO side).
  Stream<List<ApplicationModel>> watchApplications(String requestId) {
    return _apps(requestId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ApplicationModel.fromFirestore(d, requestId))
            .toList());
  }

  /// Stream of all requests a provider has applied to (SP side).
  Stream<List<ApplicationModel>> watchMyApplications(String providerUid) {
    return _db
        .collectionGroup('applications')
        .where('providerUid', isEqualTo: providerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) =>
                ApplicationModel.fromFirestore(d, d.reference.parent.parent!.id))
            .toList());
  }

  /// Check if this provider already applied to a request.
  Future<bool> hasApplied(String requestId, String providerUid) async {
    final snap = await _apps(requestId)
        .where('providerUid', isEqualTo: providerUid)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// SP submits application; increments applicationCount on the request.
  Future<void> submitApplication(ApplicationModel model) async {
    final batch = _db.batch();
    final appRef = _apps(model.requestId).doc();
    batch.set(appRef, model.toFirestore());
    batch.update(_col.doc(model.requestId),
        {'applicationCount': FieldValue.increment(1)});
    await batch.commit();
  }

  /// PO accepts an application:
  ///   1. Mark accepted application as 'accepted'
  ///   2. Mark all other pending applications as 'rejected'
  ///   3. Mark request as 'booked'
  Future<void> acceptApplication({
    required String requestId,
    required String applicationId,
  }) async {
    final batch = _db.batch();

    // Accept the chosen one
    batch.update(_apps(requestId).doc(applicationId),
        {'status': ApplicationStatus.accepted.name});

    // Reject others
    final others = await _apps(requestId)
        .where('status', isEqualTo: ApplicationStatus.pending.name)
        .get();
    for (final doc in others.docs) {
      if (doc.id != applicationId) {
        batch.update(doc.reference, {'status': ApplicationStatus.rejected.name});
      }
    }

    // Mark request as booked
    batch.update(
        _col.doc(requestId), {'status': ServiceRequestStatus.booked.name});

    await batch.commit();
  }

  /// PO rejects a single application.
  Future<void> rejectApplication({
    required String requestId,
    required String applicationId,
  }) =>
      _apps(requestId)
          .doc(applicationId)
          .update({'status': ApplicationStatus.rejected.name});
}
