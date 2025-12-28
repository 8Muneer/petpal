import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:petpal/core/error/failures.dart';
import 'package:petpal/features/auth/data/user_model.dart';
import 'package:petpal/features/auth/domain/auth_repository.dart';
import 'package:petpal/features/auth/domain/user_entity.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userModel = UserModel(
        id: credential.user!.uid,
        email: email,
        name: name,
        isSitter: false,
        isVerified: false,
      );

      await _firestore
          .collection('users')
          .doc(userModel.id)
          .set(userModel.toJson());

      return right(userModel.toEntity());
    } on FirebaseAuthException catch (e) {
      return left(AuthFailure(e.message ?? 'Sign up failed'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userData =
          await _firestore.collection('users').doc(credential.user!.uid).get();

      if (!userData.exists) {
        return left(const AuthFailure('User data not found'));
      }

      final userModel = UserModel.fromJson(userData.data()!);
      return right(userModel.toEntity());
    } on FirebaseAuthException catch (e) {
      return left(AuthFailure(e.message ?? 'Login failed'));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _auth.signOut();
      return right(null);
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return right(null);

      final userData =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!userData.exists) return right(null);

      final userModel = UserModel.fromJson(userData.data()!);
      return right(userModel.toEntity());
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }
}
