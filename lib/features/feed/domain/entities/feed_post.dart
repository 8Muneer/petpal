import 'package:equatable/equatable.dart';

enum PostType { post, tip }

class FeedPost extends Equatable {
  final String id;
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final PostType type;
  final String content;
  final List<String> imageUrls;
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
    this.imageUrls = const [],
    this.likes = const [],
    this.commentCount = 0,
    this.createdAt,
  });

  // Backward-compat getter used by post_detail_screen and feed_screen
  String? get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  bool isLikedBy(String uid) => likes.contains(uid);

  @override
  List<Object?> get props => [
        id,
        authorUid,
        authorName,
        authorPhotoUrl,
        type,
        content,
        imageUrls,
        likes,
        commentCount,
        createdAt,
      ];
}
