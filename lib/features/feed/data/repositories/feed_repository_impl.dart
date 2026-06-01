import 'package:petpal/features/feed/data/datasources/feed_image_service.dart';
import 'package:petpal/features/feed/data/datasources/feed_remote_datasource.dart';
import 'package:petpal/features/feed/domain/entities/feed_comment.dart';
import 'package:petpal/features/feed/domain/entities/feed_post.dart';
import 'package:petpal/features/feed/domain/repositories/feed_repository.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FeedRemoteDatasource _datasource;
  final FeedImageService _imageService;

  FeedRepositoryImpl(this._datasource, this._imageService);

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
  Future<void> updatePost(String postId, Map<String, dynamic> data) =>
      _datasource.updatePost(postId, data);

  @override
  Future<void> deletePost(String postId) async {
    try {
      final post = await _datasource.getPost(postId);
      if (post != null) {
        for (final url in post.imageUrls) {
          await _imageService.deleteImageByUrl(url);
        }
      }
    } catch (_) {}
    await _datasource.deletePost(postId);
  }

  @override
  Future<void> deleteAllUserPosts(String uid) async {
    try {
      final posts = await _datasource.getUserPosts(uid);
      for (final post in posts) {
        for (final url in post.imageUrls) {
          await _imageService.deleteImageByUrl(url);
        }
      }
    } catch (_) {}
    await _datasource.deleteAllUserPosts(uid);
  }

  @override
  Stream<List<FeedComment>> watchComments(String postId) =>
      _datasource.watchComments(postId);
}
