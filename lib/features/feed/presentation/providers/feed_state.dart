import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/feed/domain/entities/feed_post.dart';

class FeedState {
  final List<FeedPost> posts;
  final bool hasMore;
  final bool isLoadingMore;
  final DocumentSnapshot? lastDoc;

  const FeedState({
    required this.posts,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.lastDoc,
  });

  FeedState copyWith({
    List<FeedPost>? posts,
    bool? hasMore,
    bool? isLoadingMore,
    DocumentSnapshot? lastDoc,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastDoc: lastDoc ?? this.lastDoc,
    );
  }
}
