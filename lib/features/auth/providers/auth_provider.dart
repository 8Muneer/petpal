import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:petpal/features/auth/domain/models/models.dart';

part 'auth_provider.g.dart';

/// Firebase Auth instance provider
@riverpod
FirebaseAuth firebaseAuth(FirebaseAuthRef ref) {
  return FirebaseAuth.instance;
}

/// Firestore instance provider
@riverpod
FirebaseFirestore firestore(FirestoreRef ref) {
  return FirebaseFirestore.instance;
}

/// Auth state changes stream provider
///
/// Listens to Firebase Auth state changes and emits User? objects
@riverpod
Stream<User?> authStateChanges(AuthStateChangesRef ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
}

/// Current Firebase User provider
///
/// Returns the currently authenticated user or null
@riverpod
User? currentFirebaseUser(CurrentFirebaseUserRef ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
}

/// Current UserModel provider
///
/// Fetches full user data from Firestore based on current auth state
@riverpod
Stream<UserModel?> currentUser(CurrentUserRef ref) async* {
  final firebaseUser = ref.watch(currentFirebaseUserProvider);

  if (firebaseUser == null) {
    yield null;
    return;
  }

  // Listen to Firestore user document changes
  final firestore = ref.watch(firestoreProvider);
  yield* firestore
      .collection('users')
      .doc(firebaseUser.uid)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;

    final data = snapshot.data();
    if (data == null) return null;

    // Add the ID from the document
    data['id'] = snapshot.id;

    // Handle Timestamp to DateTime conversion
    if (data['createdAt'] is Timestamp) {
      data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
    }

    return UserModel.fromJson(data);
  });
}

/// Auth Repository provider
///
/// Provides authentication operations like login, signup, logout
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return AuthRepository(auth: auth, firestore: firestore);
}

/// Repository class for authentication operations
class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AuthRepository({
    required this.auth,
    required this.firestore,
  });

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Create user document in Firestore
  Future<void> createUserDocument({
    required String uid,
    required String email,
    required String role,
    String? displayName,
    String? phoneNumber,
  }) async {
    final userDoc = firestore.collection('users').doc(uid);

    await userDoc.set({
      'id': uid,
      'email': email,
      'role': role,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
      'isVerified': false,
      'rating': 0.0,
      'reviewCount': 0,
    });
  }

  /// Update user document in Firestore
  Future<void> updateUserDocument({
    required String uid,
    Map<String, dynamic>? data,
  }) async {
    if (data == null || data.isEmpty) return;

    final userDoc = firestore.collection('users').doc(uid);
    await userDoc.update(data);
  }

  /// Get user document from Firestore
  Future<UserModel?> getUserDocument(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();

    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    // Add the ID from the document
    data['id'] = doc.id;

    // Handle Timestamp to DateTime conversion
    if (data['createdAt'] is Timestamp) {
      data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
    }

    return UserModel.fromJson(data);
  }

  /// Sign out
  Future<void> signOut() async {
    await auth.signOut();
  }

  /// Get current user
  User? get currentUser => auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => auth.currentUser != null;
}
