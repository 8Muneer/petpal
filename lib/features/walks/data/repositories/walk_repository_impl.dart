import 'package:petpal/features/walks/data/datasources/walk_remote_datasource.dart';
import 'package:petpal/features/walks/domain/entities/walk_request.dart';
import 'package:petpal/features/walks/domain/repositories/walk_repository.dart';

class WalkRepositoryImpl implements WalkRepository {
  final WalkRemoteDatasource _datasource;

  WalkRepositoryImpl(this._datasource);

  @override
  Stream<List<WalkRequest>> watchRequests(String ownerUid) =>
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
