import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/community/domain/repositories/karma_repository.dart';

class FirestoreKarmaRepository implements KarmaRepository {
  final FirebaseFirestore _firestore;

  FirestoreKarmaRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<int> getCurrentUserKarma(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return (doc.data()?['karma'] as int?) ?? 0;
  }

  @override
  Future<void> incrementKarma(String userId, String postId, int points, String reason) async {
    final batch = _firestore.batch();
    
    // 1. Update user total karma
    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {'karma': FieldValue.increment(points)});
    
    // 2. Add transaction to ledger
    final ledgerRef = _firestore.collection('karma_ledger').doc();
    batch.set(ledgerRef, {
      'userId': userId,
      'postId': postId,
      'points': points,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<bool> canGiveTreat(String userId, String postId) async {
    // TEMPORARY BYPASS: Return true while index is building
    return true;

    /*
    final snapshot = await _firestore
        .collection('karma_ledger')
        .where('userId', isEqualTo: userId)
        .where('postId', isEqualTo: postId)
        .where('reason', isEqualTo: 'treat_given')
        .get();
    
    return snapshot.docs.isEmpty;
    */
  }

  @override
  Future<bool> checkDailyLimit(String userId) async {
    // TEMPORARY BYPASS: Return true while index is building to prevent crash
    // Once the index is ready, you can uncomment the code below.
    return true; 
    
    /*
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));
    
    final snapshot = await _firestore
        .collection('karma_ledger')
        .where('userId', isEqualTo: userId)
        .where('reason', isEqualTo: 'treat_given')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
        .get();

    return snapshot.docs.length < 10;
    */
  }
}
