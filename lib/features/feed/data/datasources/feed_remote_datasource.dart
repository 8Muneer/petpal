import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/feed/data/models/feed_comment_model.dart';
import 'package:petpal/features/feed/data/models/feed_post_model.dart';

class FeedRemoteDatasource {
  final FirebaseFirestore _firestore;

  FeedRemoteDatasource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference get _postsRef => _firestore.collection('posts');

  Stream<List<FeedPostModel>> watchPosts() {
    return _postsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => FeedPostModel.fromFirestore(doc)).toList());
  }

  Future<String> createPost(Map<String, dynamic> data) async {
    final doc = await _postsRef.add(data);
    return doc.id;
  }

  Future<void> toggleLike(String postId, String uid) async {
    final doc = _postsRef.doc(postId);
    final snap = await doc.get();
    final likes = List<String>.from(
        (snap.data() as Map<String, dynamic>?)?['likes'] ?? []);

    if (likes.contains(uid)) {
      await doc.update({
        'likes': FieldValue.arrayRemove([uid]),
      });
    } else {
      await doc.update({
        'likes': FieldValue.arrayUnion([uid]),
      });
    }
  }

  Future<void> addComment(String postId, Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    await _postsRef.doc(postId).collection('comments').add(data);
    await _postsRef.doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  Future<void> deleteAllUserPosts(String uid) async {
    final snap = await _postsRef.where('authorUid', isEqualTo: uid).get();
    for (final doc in snap.docs) {
      // Delete comments subcollection
      final comments = await doc.reference.collection('comments').get();
      for (final comment in comments.docs) {
        await comment.reference.delete();
      }
      await doc.reference.delete();
    }
  }

  Future<void> deletePost(String postId) async {
    // Delete all comments in the subcollection first
    final comments = await _postsRef.doc(postId).collection('comments').get();
    for (final doc in comments.docs) {
      await doc.reference.delete();
    }
    // Delete the post itself
    await _postsRef.doc(postId).delete();
  }

  Stream<List<FeedCommentModel>> watchComments(String postId) {
    return _postsRef
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FeedCommentModel.fromFirestore(doc))
            .toList());
  }
}
