import 'package:petpal/features/sitting/domain/entities/sitting_request.dart';

abstract class SittingRepository {
  Stream<List<SittingRequest>> watchRequests(String ownerUid);
  Future<String> createRequest(Map<String, dynamic> data);
  Future<void> updateRequest(String requestId, Map<String, dynamic> data);
  Future<void> deleteRequest(String requestId);
}
