import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/feed/data/datasources/feed_image_service.dart';
import 'package:petpal/features/feed/data/datasources/feed_remote_datasource.dart';
import 'package:petpal/features/feed/data/models/feed_post_model.dart';
import 'package:petpal/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:petpal/features/feed/domain/entities/feed_comment.dart';
import 'package:petpal/features/feed/domain/entities/feed_post.dart';
import 'package:petpal/features/feed/domain/repositories/feed_repository.dart';
import 'package:petpal/features/feed/presentation/providers/feed_state.dart';

final feedDatasourceProvider = Provider<FeedRemoteDatasource>((ref) {
  return FeedRemoteDatasource(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepositoryImpl(
    ref.watch(feedDatasourceProvider),
    ref.watch(feedImageServiceProvider),
  );
});

final feedPostsProvider = StreamProvider<List<FeedPost>>((ref) {
  final datasource = ref.watch(feedDatasourceProvider);
  return datasource.watchPosts();
});

final paginatedFeedProvider =
    StateNotifierProvider<PaginatedFeedNotifier, AsyncValue<FeedState>>((ref) {
  return PaginatedFeedNotifier(ref.watch(feedDatasourceProvider));
});

class PaginatedFeedNotifier extends StateNotifier<AsyncValue<FeedState>> {
  final FeedRemoteDatasource _datasource;
  static const int pageSize = 10;

  PaginatedFeedNotifier(this._datasource) : super(const AsyncLoading()) {
    fetchFirstPage();
  }

  Future<void> fetchFirstPage() async {
    state = const AsyncLoading();
    try {
      final query = _datasource.getPostsQuery().limit(pageSize);
      final snap = await query.get();
      final posts = snap.docs.map((doc) => FeedPostModel.fromFirestore(doc)).toList();
      state = AsyncValue.data(FeedState(
        posts: posts,
        hasMore: snap.docs.length == pageSize,
        lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void localToggleLike(String postId, String uid) {
    final current = state.asData?.value;
    if (current == null) return;
    final updatedPosts = current.posts.map((post) {
      if (post.id != postId) return post;
      final likes = List<String>.from(post.likes);
      if (likes.contains(uid)) {
        likes.remove(uid);
      } else {
        likes.add(uid);
      }
      return post.copyWith(likes: likes);
    }).toList();
    state = AsyncValue.data(current.copyWith(posts: updatedPosts));
  }

  Future<void> fetchNextPage() async {
    final currentVal = state.asData?.value;
    if (currentVal == null || !currentVal.hasMore || currentVal.isLoadingMore) return;

    state = AsyncValue.data(currentVal.copyWith(isLoadingMore: true));
    try {
      final query = _datasource.getPostsQuery()
          .startAfterDocument(currentVal.lastDoc!)
          .limit(pageSize);
      final snap = await query.get();
      final newPosts = snap.docs.map((doc) => FeedPostModel.fromFirestore(doc)).toList();
      
      state = AsyncValue.data(FeedState(
        posts: [...currentVal.posts, ...newPosts],
        hasMore: snap.docs.length == pageSize,
        lastDoc: snap.docs.isNotEmpty ? snap.docs.last : currentVal.lastDoc,
      ));
    } catch (_) {
      state = AsyncValue.data(currentVal.copyWith(isLoadingMore: false));
    }
  }
}

final feedImageServiceProvider = Provider<FeedImageService>((ref) {
  return FeedImageService(storage: FirebaseStorage.instance);
});

final feedCommentsProvider =
    StreamProvider.family<List<FeedComment>, String>((ref, postId) {
  final datasource = ref.watch(feedDatasourceProvider);
  return datasource.watchComments(postId);
});
