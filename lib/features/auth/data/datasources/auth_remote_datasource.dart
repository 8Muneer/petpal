import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/core/constants/app_constants.dart';
import 'package:petpal/features/auth/data/models/user_model.dart';
import 'package:petpal/features/auth/domain/enums/user_role.dart';

class AuthRemoteDatasource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRemoteDatasource({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  CollectionReference get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  Future<void> createUserDocument(UserModel user) async {
    await _usersRef.doc(user.uid).set(
          user.toCreateFirestore(),
          SetOptions(merge: true),
        );
  }

  Future<UserModel?> getUserDocument(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<UserRole?> getUserRole(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;

    final roleStr = (data['role'] ?? data['userType'])?.toString().trim();
    return UserRole.fromString(roleStr);
  }
}
