import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:petpal/core/error/failures.dart';
import 'package:petpal/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:petpal/features/auth/data/models/user_model.dart';
import 'package:petpal/features/auth/domain/entities/app_user.dart';
import 'package:petpal/features/auth/domain/enums/user_role.dart';
import 'package:petpal/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;

  AuthRepositoryImpl(this._datasource);

  @override
  Stream<AppUser?> get authStateChanges {
    return _datasource.authStateChanges.asyncMap((user) async {
      if (user == null) return null;
      final userModel = await _datasource.getUserDocument(user.uid);
      return userModel;
    });
  }

  @override
  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential =
          await _datasource.signInWithEmail(email, password);
      final uid = credential.user?.uid;
      if (uid == null) {
        return const Left(AuthFailure('No user returned'));
      }

      final userModel = await _datasource.getUserDocument(uid);
      if (userModel == null) {
        return const Left(AuthFailure('User document not found'));
      }

      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser>> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final credential =
          await _datasource.signUpWithEmail(email, password);
      final uid = credential.user?.uid;
      if (uid == null) {
        return const Left(AuthFailure('No user returned'));
      }

      try {
        await _datasource.updateDisplayName(name);
      } catch (_) {}

      final userModel = UserModel(
        uid: uid,
        name: name,
        email: email,
        role: role,
      );

      await _datasource.createUserDocument(userModel);
      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _datasource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await _datasource.sendPasswordResetEmail(email);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserRole?>> getUserRole(String uid) async {
    try {
      final role = await _datasource.getUserRole(uid);
      return Right(role);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
