import 'package:petpal/features/sitting/data/datasources/sitting_remote_datasource.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart';
import 'package:petpal/features/sitting/domain/repositories/sitting_repository.dart';

class SittingRepositoryImpl implements SittingRepository {
  final SittingRemoteDatasource _datasource;

  SittingRepositoryImpl(this._datasource);

  @override
  Stream<List<SittingRequest>> watchRequests(String ownerUid) =>
      _datasource.watchRequests(ownerUid);

  @override
  Future<String> createRequest(Map<String, dynamic> data) =>
      _datasource.createRequest(data);

  @override
  Future<void> updateRequest(String requestId, Map<String, dynamic> data) =>
      _datasource.updateRequest(requestId, data);

  @override
  Future<void> deleteRequest(String requestId) =>
      _datasource.deleteRequest(requestId);
}
