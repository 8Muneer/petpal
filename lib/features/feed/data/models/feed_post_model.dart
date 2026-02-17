import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/feed/domain/entities/feed_post.dart';

class FeedPostModel extends FeedPost {
  const FeedPostModel({
    required super.id,
    required super.authorUid,
    required super.authorName,
    super.authorPhotoUrl,
    required super.type,
    required super.content,
    super.imageUrl,
    super.likes,
    super.commentCount,
    super.createdAt,
  });

  factory FeedPostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FeedPostModel(
      id: doc.id,
      authorUid: data['authorUid'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      type: (data['type'] as String?) == 'tip' ? PostType.tip : PostType.post,
      content: data['content'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorUid': authorUid,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'type': type == PostType.tip ? 'tip' : 'post',
      'content': content,
      'imageUrl': imageUrl,
      'likes': likes,
      'commentCount': commentCount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
