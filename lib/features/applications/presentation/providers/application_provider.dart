import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/applications/data/datasources/application_remote_datasource.dart';
import 'package:petpal/features/applications/domain/entities/service_application.dart';

final applicationDatasourceProvider =
    Provider<ApplicationRemoteDatasource>((ref) {
  return ApplicationRemoteDatasource(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

/// (requestType, requestId) — all offers on a request, for the owner's view.
typedef RequestRef = ({String type, String id});

final requestApplicationsProvider = StreamProvider.autoDispose
    .family<List<ServiceApplication>, RequestRef>((ref, r) {
  return ref
      .watch(applicationDatasourceProvider)
      .watchApplications(r.type, r.id);
});

/// (requestType, requestId, providerUid) — the current provider's own offer,
/// used to switch the "הגש מועמדות" CTA to an already-applied state.
typedef MyApplicationRef = ({String type, String id, String providerUid});

final myApplicationProvider = StreamProvider.autoDispose
    .family<ServiceApplication?, MyApplicationRef>((ref, r) {
  return ref
      .watch(applicationDatasourceProvider)
      .watchMyApplication(r.type, r.id, r.providerUid);
});
