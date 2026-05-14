import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/features/community/domain/entities/community_post.dart';
import 'package:petpal/features/community/domain/entities/karma_transaction.dart';
import 'package:petpal/features/community/presentation/providers/karma_provider.dart';
import 'package:petpal/features/community/presentation/providers/community_provider.dart';

class CreatePostState {
  final String content;
  final List<String> imagePaths;
  final TrustPostType category;
  final String? linkedServiceId;
  final String? linkedServiceName;
  final bool isSubmitting;

  CreatePostState({
    this.content = '',
    this.imagePaths = const [],
    this.category = TrustPostType.update,
    this.linkedServiceId,
    this.linkedServiceName,
    this.isSubmitting = false,
  });

  CreatePostState copyWith({
    String? content,
    List<String>? imagePaths,
    TrustPostType? category,
    String? linkedServiceId,
    String? linkedServiceName,
    bool? isSubmitting,
  }) {
    return CreatePostState(
      content: content ?? this.content,
      imagePaths: imagePaths ?? this.imagePaths,
      category: category ?? this.category,
      linkedServiceId: linkedServiceId ?? this.linkedServiceId,
      linkedServiceName: linkedServiceName ?? this.linkedServiceName,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  bool get isValid => content.trim().isNotEmpty;
}

class CreatePostNotifier extends StateNotifier<CreatePostState> {
  final Ref _ref;
  CreatePostNotifier(this._ref) : super(CreatePostState());

  void setContent(String content) => state = state.copyWith(content: content);
  void setCategory(TrustPostType category) => state = state.copyWith(category: category);
  
  void addImage(String path) {
    if (state.imagePaths.length < 5) {
      state = state.copyWith(imagePaths: [...state.imagePaths, path]);
    }
  }

  void removeImage(String path) {
    state = state.copyWith(
      imagePaths: state.imagePaths.where((p) => p != path).toList(),
    );
  }

  void setLinkedService(String id, String name) {
    state = state.copyWith(
      linkedServiceId: id, 
      linkedServiceName: name,
    );
  }

  void clearLinkedService() {
    state = CreatePostState(
      content: state.content,
      imagePaths: state.imagePaths,
      category: state.category,
    );
  }

  Future<bool> submit({
    required String authorId,
    required String authorName,
    required String authorPhotoUrl,
    required String authorNeighborhood,
  }) async {
    if (!state.isValid) return false;
    
    state = state.copyWith(isSubmitting: true);
    
    try {
      final repository = _ref.read(communityRepositoryProvider);
      
      final newPost = CommunityPost(
        id: '', // Firestore will generate this
        authorId: authorId,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        authorNeighborhood: authorNeighborhood,
        authorKarma: _ref.read(karmaProvider).totalKarma,
        isAuthorVerified: true, // For demo, assuming verified for now
        content: state.content,
        imageUrls: state.imagePaths, 
        createdAt: DateTime.now(),
        type: state.category,
        likes: 0,
        commentsCount: 0,
        associatedServiceId: state.linkedServiceId,
        associatedServiceName: state.linkedServiceName,
        associatedServiceRating: 4.8, // Mock rating for now
      );

      await repository.createPost(newPost);
      
      // Award 3 Karma points
      await _ref.read(karmaProvider.notifier).addKarma(
        3, 
        KarmaReason.recommendationPosted,
        description: 'פרסום פוסט חדש בקהילה',
      );

      // Refresh the feed
      await _ref.read(communityFeedProvider.notifier).loadPosts();

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      return false;
    }
  }
}

final createPostProvider = StateNotifierProvider<CreatePostNotifier, CreatePostState>((ref) {
  return CreatePostNotifier(ref);
});
