import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/features/community/domain/entities/community_comment.dart';
import 'package:petpal/features/community/presentation/providers/community_provider.dart';

final commentsProvider = StateNotifierProvider.family<CommentsNotifier, AsyncValue<List<CommunityComment>>, String>((ref, postId) {
  final repository = ref.watch(communityRepositoryProvider);
  return CommentsNotifier(repository, postId);
});

class CommentsNotifier extends StateNotifier<AsyncValue<List<CommunityComment>>> {
  final dynamic _repository; // Use dynamic if repository provider isn't exported yet, or import it
  final String _postId;

  CommentsNotifier(this._repository, this._postId) : super(const AsyncValue.loading()) {
    fetchComments();
  }

  Future<void> fetchComments() async {
    state = const AsyncValue.loading();
    try {
      final comments = await _repository.getComments(_postId);
      state = AsyncValue.data(comments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addComment({
    required String authorId,
    required String authorName,
    required String authorPhotoUrl,
    required String content,
  }) async {
    final newComment = CommunityComment(
      id: '', // Firestore will generate
      postId: _postId,
      authorId: authorId,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      content: content,
      createdAt: DateTime.now(),
    );

    try {
      await _repository.addComment(newComment);
      // Refresh comments after adding
      await fetchComments();
    } catch (e) {
      // Handle error (could use a separate state for posting)
    }
  }
}
