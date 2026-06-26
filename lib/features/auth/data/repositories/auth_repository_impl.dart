import 'package:fpdart/fpdart.dart';
import 'package:petpal/core/error/failures.dart';
import 'package:petpal/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:petpal/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;

  AuthRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _datasource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
