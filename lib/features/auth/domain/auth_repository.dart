import 'package:fpdart/fpdart.dart';
import 'package:petpal/core/error/failures.dart';
import 'package:petpal/features/auth/domain/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String name,
  });

  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, UserEntity?>> getCurrentUser();
}
