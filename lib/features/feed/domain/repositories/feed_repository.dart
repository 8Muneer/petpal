import 'package:petpal/features/feed/domain/entities/feed_comment.dart';
import 'package:petpal/features/feed/domain/entities/feed_post.dart';

abstract class FeedRepository {
  Stream<List<FeedPost>> watchPosts();
  Future<String> createPost(Map<String, dynamic> data);
  Future<void> toggleLike(String postId, String uid);
  Future<void> addComment(String postId, Map<String, dynamic> data);
  Future<void> deletePost(String postId);
  Future<void> deleteAllUserPosts(String uid);
  Stream<List<FeedComment>> watchComments(String postId);
}
