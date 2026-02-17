import 'package:petpal/features/feed/data/datasources/feed_remote_datasource.dart';
import 'package:petpal/features/feed/domain/entities/feed_comment.dart';
import 'package:petpal/features/feed/domain/entities/feed_post.dart';
import 'package:petpal/features/feed/domain/repositories/feed_repository.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FeedRemoteDatasource _datasource;

  FeedRepositoryImpl(this._datasource);

  @override
  Stream<List<FeedPost>> watchPosts() => _datasource.watchPosts();

  @override
  Future<String> createPost(Map<String, dynamic> data) =>
      _datasource.createPost(data);

  @override
  Future<void> toggleLike(String postId, String uid) =>
      _datasource.toggleLike(postId, uid);

  @override
  Future<void> addComment(String postId, Map<String, dynamic> data) =>
      _datasource.addComment(postId, data);

  @override
  Future<void> deletePost(String postId) => _datasource.deletePost(postId);

  @override
  Future<void> deleteAllUserPosts(String uid) =>
      _datasource.deleteAllUserPosts(uid);

  @override
  Stream<List<FeedComment>> watchComments(String postId) =>
      _datasource.watchComments(postId);
}
