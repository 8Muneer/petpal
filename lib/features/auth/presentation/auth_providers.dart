import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:petpal/features/auth/data/firebase_auth_repository.dart';
import 'package:petpal/features/auth/domain/auth_repository.dart';

part 'auth_providers.g.dart';

@riverpod
FirebaseAuth firebaseAuth(FirebaseAuthRef ref) => FirebaseAuth.instance;

@riverpod
FirebaseFirestore firestore(FirestoreRef ref) => FirebaseFirestore.instance;

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return FirebaseAuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
}

// Fixed provider names to match generator output if needed or standard naming
@riverpod
FirebaseAuth firebaseAuthSecondary(FirebaseAuthSecondaryRef ref) =>
    FirebaseAuth.instance;
