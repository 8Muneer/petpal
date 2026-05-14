import 'package:petpal/features/community/domain/entities/community_post.dart';
import 'package:petpal/features/community/domain/entities/community_comment.dart';
import 'package:petpal/features/community/domain/entities/community_alert.dart';

abstract class CommunityRepository {
  /// Fetches a paginated list of posts.
  /// If [lastPostId] is provided, it fetches posts after that ID.
  Future<List<CommunityPost>> getPosts({String? lastPostId});
  
  Future<void> giveTreat(String postId);
  Future<void> createPost(CommunityPost post);

  // Comments
  Future<List<CommunityComment>> getComments(String postId);
  Future<void> addComment(CommunityComment comment);

  // Alerts
  Future<List<CommunityAlert>> getAlerts(String neighborhood);
}
