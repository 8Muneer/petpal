import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:petpal/features/applications/data/models/service_application_model.dart';

/// Firestore access for provider offers ("הגש מועמדות") stored under
/// `{requestType}_requests/{requestId}/applications/{providerUid}`.
///
/// Accepting an offer is intentionally NOT a client write: it has to create an
/// 'accepted' booking (which firestore.rules forbid clients from doing) and
/// atomically close the request + refuse the other offers. That runs in the
/// `acceptServiceApplication` Cloud Function (Admin SDK). Everything else here
/// — submit, watch, refuse — is a plain owner/provider-scoped write.
class ApplicationRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  ApplicationRemoteDatasource({
    required FirebaseFirestore firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore,
        _functions = functions ?? FirebaseFunctions.instance;

  CollectionReference _col(String requestType, String requestId) => _firestore
      .collection('${requestType}_requests')
      .doc(requestId)
      .collection('applications');

  /// Provider submits (or updates) their offer. Doc id == providerUid, so a
  /// second submit overwrites the first instead of stacking duplicates.
  Future<void> submitApplication(ServiceApplicationModel application) async {
    await _col(application.requestType, application.requestId)
        .doc(application.providerUid)
        .set(application.toFirestore());
  }

  /// Owner-facing: all offers on a request, newest first.
  Stream<List<ServiceApplicationModel>> watchApplications(
      String requestType, String requestId) {
    return _col(requestType, requestId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ServiceApplicationModel.fromFirestore(d))
            .toList());
  }

  /// Provider-facing: their own offer on a request (null if they haven't applied).
  Stream<ServiceApplicationModel?> watchMyApplication(
      String requestType, String requestId, String providerUid) {
    return _col(requestType, requestId).doc(providerUid).snapshots().map(
        (d) => d.exists ? ServiceApplicationModel.fromFirestore(d) : null);
  }

  /// Owner refuses a single offer (request stays open for other providers).
  Future<void> refuseApplication({
    required String requestType,
    required String requestId,
    required String providerUid,
    String? reason,
  }) async {
    await _col(requestType, requestId).doc(providerUid).update({
      'status': 'refused',
      'refusalReason': reason,
    });
  }

  /// Owner accepts an offer → server creates the 'accepted' booking, closes the
  /// request, refuses the remaining offers, and notifies the providers.
  Future<void> acceptApplication({
    required String requestType,
    required String requestId,
    required String providerUid,
  }) async {
    final callable = _functions.httpsCallable('acceptServiceApplication');
    await callable.call({
      'requestType': requestType,
      'requestId': requestId,
      'providerUid': providerUid,
    });
  }
}
