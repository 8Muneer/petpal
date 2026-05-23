import 'package:cloud_firestore/cloud_firestore.dart';

class FcmDatasource {
  final FirebaseFirestore _db;

  FcmDatasource(this._db);

  Future<void> saveToken(String uid, String token) async {
    await _db.collection('users').doc(uid).set(
      {'fcmTokens': FieldValue.arrayUnion([token])},
      SetOptions(merge: true),
    );
  }

  Future<void> removeToken(String uid, String token) async {
    try {
      await _db.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') rethrow;
    }
  }
}
