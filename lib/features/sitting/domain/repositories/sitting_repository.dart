import 'package:petpal/features/sitting/domain/entities/sitting_request.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_service.dart';

abstract class SittingRepository {
  Stream<List<SittingRequest>> watchRequests(String ownerUid);
  Stream<List<SittingRequest>> watchAssignedRequests(String sitterUid);
  Stream<List<SittingRequest>> watchPublicRequests();
  Future<String> createRequest(Map<String, dynamic> data);
  Future<void> updateRequest(String requestId, Map<String, dynamic> data);
  Future<void> deleteRequest(String requestId);
  Future<void> updateRequestStatus(
    String requestId,
    SittingStatus status, {
    String? refusalReason,
  });

  // Services
  Stream<List<SittingService>> watchAllServices();
  Stream<List<SittingService>> watchMyServices(String providerUid);
  Future<String> createService(Map<String, dynamic> data);
  Future<void> updateService(String serviceId, Map<String, dynamic> data);
  Future<void> deleteService(String serviceId);
}
