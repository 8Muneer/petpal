import 'package:petpal/features/walks/domain/entities/walk_request.dart';

abstract class WalkRepository {
  Stream<List<WalkRequest>> watchRequests(String ownerUid);
  Future<String> createRequest(Map<String, dynamic> data);
  Future<void> updateRequest(String requestId, Map<String, dynamic> data);
  Future<void> deleteRequest(String requestId);
}
