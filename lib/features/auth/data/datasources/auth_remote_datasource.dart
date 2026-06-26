import 'package:firebase_auth/firebase_auth.dart';

class AuthRemoteDatasource {
  final FirebaseAuth _auth;

  AuthRemoteDatasource({required FirebaseAuth auth}) : _auth = auth;

  Future<void> signOut() => _auth.signOut();
}
