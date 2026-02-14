import 'package:fpdart/fpdart.dart';
import 'package:petpal/core/error/failures.dart';
import 'package:petpal/features/auth/domain/entities/app_user.dart';
import 'package:petpal/features/auth/domain/enums/user_role.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;

  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, AppUser>> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  });

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  Future<Either<Failure, UserRole?>> getUserRole(String uid);
}
