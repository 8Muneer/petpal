import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/feed/domain/entities/feed_comment.dart';

class FeedCommentModel extends FeedComment {
  const FeedCommentModel({
    required super.id,
    required super.authorUid,
    required super.authorName,
    super.authorPhotoUrl,
    required super.content,
    super.createdAt,
  });

  factory FeedCommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FeedCommentModel(
      id: doc.id,
      authorUid: data['authorUid'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      content: data['content'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorUid': authorUid,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
