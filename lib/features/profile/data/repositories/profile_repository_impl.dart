import 'package:fpdart/fpdart.dart';
import 'package:petpal/core/error/failures.dart';
import 'package:petpal/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:petpal/features/profile/domain/entities/user_profile.dart';
import 'package:petpal/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource _datasource;

  ProfileRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, UserProfile>> getProfile(String uid) async {
    try {
      final profile = await _datasource.getProfile(uid);
      if (profile == null) {
        return const Left(DatabaseFailure('Profile not found'));
      }
      return Right(profile);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile(
      String uid, Map<String, dynamic> data) async {
    try {
      await _datasource.updateProfile(uid, data);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _datasource.watchProfile(uid);
  }
}
