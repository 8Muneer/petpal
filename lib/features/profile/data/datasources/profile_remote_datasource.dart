import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/core/constants/app_constants.dart';
import 'package:petpal/features/profile/data/models/profile_model.dart';

class ProfileRemoteDatasource {
  final FirebaseFirestore _firestore;

  ProfileRemoteDatasource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  Future<ProfileModel?> getProfile(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return ProfileModel.fromFirestore(doc);
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _usersRef.doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<ProfileModel?> watchProfile(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ProfileModel.fromFirestore(doc);
    });
  }
}
