import 'package:equatable/equatable.dart';

enum PostType { post, tip }

class FeedPost extends Equatable {
  final String id;
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final PostType type;
  final String content;
  final String? imageUrl;
  final List<String> likes;
  final int commentCount;
  final DateTime? createdAt;

  const FeedPost({
    required this.id,
    required this.authorUid,
    required this.authorName,
    this.authorPhotoUrl,
    required this.type,
    required this.content,
    this.imageUrl,
    this.likes = const [],
    this.commentCount = 0,
    this.createdAt,
  });

  bool isLikedBy(String uid) => likes.contains(uid);

  @override
  List<Object?> get props => [
        id,
        authorUid,
        authorName,
        authorPhotoUrl,
        type,
        content,
        imageUrl,
        likes,
        commentCount,
        createdAt,
      ];
}
