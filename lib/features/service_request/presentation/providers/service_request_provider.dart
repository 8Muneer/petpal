import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/features/service_request/data/datasources/service_request_datasource.dart';
import 'package:petpal/features/service_request/data/models/application_model.dart';
import 'package:petpal/features/service_request/data/models/service_request_model.dart';
import 'package:petpal/features/service_request/domain/entities/service_request.dart';

// ── Datasource ────────────────────────────────────────────────────────────────

final serviceRequestDatasourceProvider = Provider<ServiceRequestDatasource>(
  (ref) => ServiceRequestDatasource(FirebaseFirestore.instance),
);

// ── Streams ───────────────────────────────────────────────────────────────────

/// All open requests (SP browse feed). Pass null for all types.
final openRequestsProvider =
    StreamProvider.family<List<ServiceRequestModel>, ServiceType?>(
  (ref, type) => ref
      .watch(serviceRequestDatasourceProvider)
      .watchOpenRequests(type: type),
);

/// Requests posted by a specific pet owner.
final myRequestsProvider =
    StreamProvider.family<List<ServiceRequestModel>, String>(
  (ref, ownerUid) =>
      ref.watch(serviceRequestDatasourceProvider).watchMyRequests(ownerUid),
);

/// Applications on a specific request (PO sees who applied).
final requestApplicationsProvider =
    StreamProvider.family<List<ApplicationModel>, String>(
  (ref, requestId) =>
      ref.watch(serviceRequestDatasourceProvider).watchApplications(requestId),
);

/// All applications submitted by a specific provider (SP tracks their applies).
final myApplicationsProvider =
    StreamProvider.family<List<ApplicationModel>, String>(
  (ref, providerUid) =>
      ref.watch(serviceRequestDatasourceProvider).watchMyApplications(providerUid),
);

// ── Notifiers ─────────────────────────────────────────────────────────────────

final serviceRequestNotifierProvider =
    AsyncNotifierProvider<ServiceRequestNotifier, void>(
  ServiceRequestNotifier.new,
);

class ServiceRequestNotifier extends AsyncNotifier<void> {
  ServiceRequestDatasource get _ds =>
      ref.read(serviceRequestDatasourceProvider);

  @override
  Future<void> build() async {}

  Future<String> createRequest(ServiceRequestModel model) async {
    state = const AsyncLoading();
    try {
      final id = await _ds.createRequest(model);
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> cancelRequest(String id) async {
    state = const AsyncLoading();
    try {
      await _ds.cancelRequest(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> submitApplication({
    required String requestId,
    required String providerUid,
    required String providerName,
    String? providerPhotoUrl,
    String? message,
    double? proposedPrice,
  }) async {
    state = const AsyncLoading();
    try {
      final model = ApplicationModel(
        id: '',
        requestId: requestId,
        providerUid: providerUid,
        providerName: providerName,
        providerPhotoUrl: providerPhotoUrl,
        message: message,
        proposedPrice: proposedPrice,
      );
      await _ds.submitApplication(model);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> acceptApplication({
    required String requestId,
    required String applicationId,
  }) async {
    state = const AsyncLoading();
    try {
      await _ds.acceptApplication(
        requestId: requestId,
        applicationId: applicationId,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> rejectApplication({
    required String requestId,
    required String applicationId,
  }) async {
    state = const AsyncLoading();
    try {
      await _ds.rejectApplication(
        requestId: requestId,
        applicationId: applicationId,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<bool> hasApplied(String requestId, String providerUid) =>
      _ds.hasApplied(requestId, providerUid);
}
