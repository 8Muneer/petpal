import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/community/domain/entities/community_post.dart';
import 'package:petpal/features/community/domain/entities/community_comment.dart';
import 'package:petpal/features/community/domain/entities/community_alert.dart';
import 'package:petpal/features/community/domain/repositories/community_repository.dart';

class FirestoreCommunityRepository implements CommunityRepository {
  final FirebaseFirestore _firestore;

  FirestoreCommunityRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<CommunityPost>> getPosts({String? lastPostId}) async {
    Query query = _firestore
        .collection('community_posts')
        .orderBy('createdAt', descending: true)
        .limit(15);

    if (lastPostId != null) {
      final lastDoc = await _firestore.collection('community_posts').doc(lastPostId).get();
      if (lastDoc.exists) {
        query = query.startAfterDocument(lastDoc);
      }
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => _mapToPost(doc)).toList();
  }

  @override
  Future<void> giveTreat(String postId) async {
    // Basic implementation - real logic with karma ledger is in KarmaRepository
    await _firestore.collection('community_posts').doc(postId).update({
      'likes': FieldValue.increment(1),
    });
  }

  @override
  Future<void> createPost(CommunityPost post) async {
    await _firestore.collection('community_posts').add({
      'authorId': post.authorId,
      'authorName': post.authorName,
      'authorPhotoUrl': post.authorPhotoUrl,
      'authorNeighborhood': post.authorNeighborhood,
      'authorKarma': post.authorKarma,
      'isAuthorVerified': post.isAuthorVerified,
      'content': post.content,
      'imageUrls': post.imageUrls,
      'createdAt': FieldValue.serverTimestamp(),
      'type': post.type.toString().split('.').last,
      'isUrgent': post.isUrgent,
      'likes': post.likes,
      'commentsCount': post.commentsCount,
      'associatedServiceId': post.associatedServiceId,
      'associatedServiceName': post.associatedServiceName,
      'associatedServiceRating': post.associatedServiceRating,
    });
  }

  @override
  Future<List<CommunityComment>> getComments(String postId) async {
    final snapshot = await _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return CommunityComment(
        id: doc.id,
        postId: postId,
        authorId: data['authorId'] ?? '',
        authorName: data['authorName'] ?? '',
        authorPhotoUrl: data['authorPhotoUrl'] ?? '',
        content: data['content'] ?? '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<void> addComment(CommunityComment comment) async {
    final postRef = _firestore.collection('community_posts').doc(comment.postId);
    
    await _firestore.runTransaction((transaction) async {
      // Add comment
      final commentRef = postRef.collection('comments').doc();
      transaction.set(commentRef, {
        'authorId': comment.authorId,
        'authorName': comment.authorName,
        'authorPhotoUrl': comment.authorPhotoUrl,
        'content': comment.content,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Increment comment count
      transaction.update(postRef, {
        'commentsCount': FieldValue.increment(1),
      });
    });
  }

  @override
  Future<List<CommunityAlert>> getAlerts(String neighborhood) async {
    final snapshot = await _firestore
        .collection('community_alerts')
        .where('neighborhood', isEqualTo: neighborhood)
        .orderBy('createdAt', descending: true)
        .limit(3)
        .get();

    return snapshot.docs.map((doc) => CommunityAlert.fromMap(doc.id, doc.data())).toList();
  }

  CommunityPost _mapToPost(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityPost(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'] ?? '',
      authorNeighborhood: data['authorNeighborhood'] ?? '',
      authorKarma: data['authorKarma'] ?? 0,
      isAuthorVerified: data['isAuthorVerified'] ?? false,
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: _mapType(data['type']),
      isUrgent: data['isUrgent'] ?? false,
      likes: data['likes'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      associatedServiceId: data['associatedServiceId'],
      associatedServiceName: data['associatedServiceName'],
      associatedServiceRating: (data['associatedServiceRating'] as num?)?.toDouble(),
      isLikedByMe: data['isLikedByMe'] ?? false,
    );
  }

  TrustPostType _mapType(String? type) {
    switch (type) {
      case 'recommendation':
        return TrustPostType.recommendation;
      case 'tip':
        return TrustPostType.tip;
      case 'update':
      default:
        return TrustPostType.update;
    }
  }
}
