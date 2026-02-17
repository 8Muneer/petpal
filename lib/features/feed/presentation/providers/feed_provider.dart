import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/feed/data/datasources/feed_image_service.dart';
import 'package:petpal/features/feed/data/datasources/feed_remote_datasource.dart';
import 'package:petpal/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:petpal/features/feed/domain/entities/feed_comment.dart';
import 'package:petpal/features/feed/domain/entities/feed_post.dart';
import 'package:petpal/features/feed/domain/repositories/feed_repository.dart';

final feedDatasourceProvider = Provider<FeedRemoteDatasource>((ref) {
  return FeedRemoteDatasource(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepositoryImpl(ref.watch(feedDatasourceProvider));
});

final feedPostsProvider = StreamProvider<List<FeedPost>>((ref) {
  final datasource = ref.watch(feedDatasourceProvider);
  return datasource.watchPosts();
});

final feedImageServiceProvider = Provider<FeedImageService>((ref) {
  return FeedImageService(storage: FirebaseStorage.instance);
});

final feedCommentsProvider =
    StreamProvider.family<List<FeedComment>, String>((ref, postId) {
  final datasource = ref.watch(feedDatasourceProvider);
  return datasource.watchComments(postId);
});
