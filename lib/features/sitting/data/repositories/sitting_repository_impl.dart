import 'package:petpal/features/sitting/data/datasources/sitting_remote_datasource.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_service.dart';
import 'package:petpal/features/sitting/domain/repositories/sitting_repository.dart';

class SittingRepositoryImpl implements SittingRepository {
  final SittingRemoteDatasource _datasource;

  SittingRepositoryImpl(this._datasource);

  @override
  Stream<List<SittingRequest>> watchRequests(String ownerUid) =>
      _datasource.watchRequests(ownerUid);

  @override
  Stream<List<SittingRequest>> watchAssignedRequests(String sitterUid) =>
      _datasource.watchAssignedRequests(sitterUid);

  @override
  Stream<List<SittingRequest>> watchPublicRequests() =>
      _datasource.watchPublicRequests();

  @override
  Future<String> createRequest(Map<String, dynamic> data) =>
      _datasource.createRequest(data);

  @override
  Future<void> updateRequest(String requestId, Map<String, dynamic> data) =>
      _datasource.updateRequest(requestId, data);

  @override
  Future<void> deleteRequest(String requestId) =>
      _datasource.deleteRequest(requestId);

  @override
  Future<void> updateRequestStatus(
    String requestId,
    SittingStatus status, {
    String? refusalReason,
  }) =>
      _datasource.updateRequestStatus(requestId, status,
          refusalReason: refusalReason);

  // Services
  @override
  Stream<List<SittingService>> watchAllServices() =>
      _datasource.watchSittingServices();

  @override
  Stream<List<SittingService>> watchMyServices(String providerUid) =>
      _datasource.watchMyServices(providerUid);

  @override
  Future<String> createService(Map<String, dynamic> data) =>
      _datasource.createSittingService(data);

  @override
  Future<void> updateService(String serviceId, Map<String, dynamic> data) =>
      _datasource.updateSittingService(serviceId, data);

  @override
  Future<void> deleteService(String serviceId) =>
      _datasource.deleteSittingService(serviceId);
}
