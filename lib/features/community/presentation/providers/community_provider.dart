import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/features/community/data/repositories/community_repository_impl.dart';
import 'package:petpal/features/community/data/repositories/karma_repository_impl.dart';
import 'package:petpal/features/community/domain/entities/community_post.dart';
import 'package:petpal/features/community/domain/repositories/community_repository.dart';
import 'package:petpal/features/community/domain/repositories/karma_repository.dart';

// Providers
final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  // Use Firestore implementation for production
  return FirestoreCommunityRepository();
});

final karmaRepositoryProvider = Provider<KarmaRepository>((ref) {
  return FirestoreKarmaRepository();
});

final communityFeedProvider = StateNotifierProvider<CommunityController, AsyncValue<List<CommunityPost>>>((ref) {
  final repository = ref.watch(communityRepositoryProvider);
  final karmaRepository = ref.watch(karmaRepositoryProvider);
  return CommunityController(repository, karmaRepository);
});

final communityFilterProvider = StateProvider<String>((ref) => 'All');

final pictureOfTheDayProvider = Provider<CommunityPost?>((ref) {
  final feedAsync = ref.watch(communityFeedProvider);
  return feedAsync.whenData((posts) {
    if (posts.isEmpty) return null;
    
    // Filter for posts with images and within the last 24 hours
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));
    
    final candidates = posts.where((p) => 
      p.imageUrls != null && 
      p.imageUrls!.isNotEmpty &&
      p.createdAt.isAfter(yesterday)
    ).toList();
    
    if (candidates.isEmpty) {
      // Fallback: Highest treats of all time if no recent image posts
      final allWithImages = posts.where((p) => p.imageUrls != null && p.imageUrls!.isNotEmpty).toList();
      if (allWithImages.isEmpty) return null;
      allWithImages.sort((a, b) => b.treats.compareTo(a.treats));
      return allWithImages.first;
    }
    
    // Sort by treats
    candidates.sort((a, b) => b.treats.compareTo(a.treats));
    
    return candidates.first;
  }).value;
});

class CommunityController extends StateNotifier<AsyncValue<List<CommunityPost>>> {
  final CommunityRepository _repository;
  final KarmaRepository _karmaRepository;

  CommunityController(this._repository, this._karmaRepository) : super(const AsyncValue.loading()) {
    loadPosts();
  }

  Future<void> loadPosts() async {
    state = const AsyncValue.loading();
    try {
      final posts = await _repository.getPosts();
      state = AsyncValue.data(posts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMorePosts() async {
    final currentPosts = state.value;
    if (currentPosts == null || currentPosts.isEmpty) return;

    try {
      final lastId = currentPosts.last.id;
      final morePosts = await _repository.getPosts(lastPostId: lastId);
      
      if (morePosts.isNotEmpty) {
        state = AsyncValue.data([...currentPosts, ...morePosts]);
      }
    } catch (e) {
      // For fetch more, we might just want to ignore errors or log them
    }
  }

  Future<void> refreshPosts() async {
    try {
      final posts = await _repository.getPosts();
      state = AsyncValue.data(posts);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> giveTreat(String postId) async {
    final currentPosts = state.value;
    if (currentPosts == null) return;

    final post = currentPosts.firstWhere((p) => p.id == postId);
    
    final isUnliking = post.isLikedByMe;
    
    const currentUserId = 'current_user'; 
    
    if (!isUnliking) {
      // 1. Security Check: Daily Limit (Option B)
      final underLimit = await _karmaRepository.checkDailyLimit(currentUserId);
      if (!underLimit) return;
    }

    // Optimistic UI Update
    state = AsyncValue.data(
      currentPosts.map((p) {
        if (p.id == postId) {
          return p.copyWith(
            likes: isUnliking ? p.likes - 1 : p.likes + 1,
            treats: isUnliking ? p.treats - 1 : p.treats + 1,
            authorKarma: isUnliking ? p.authorKarma - 1 : p.authorKarma + 1,
            isLikedByMe: !isUnliking,
          );
        }
        return p;
      }).toList(),
    );

    try {
      final increment = isUnliking ? -1 : 1;
      
      // 3. Persistent Update: Atomic Transaction
      if (isUnliking) {
        // Implement unlike logic in repository if needed
      } else {
        await _repository.giveTreat(postId);
      }
      
      await _karmaRepository.incrementKarma(
        post.authorId, 
        postId, 
        increment, 
        isUnliking ? 'treat_removed' : 'treat_received',
      );
      
      // Track transaction for the giver
      await _karmaRepository.incrementKarma(
        currentUserId, 
        postId, 
        0, 
        isUnliking ? 'untreat_given' : 'treat_given',
      );
      
      HapticFeedback.lightImpact();
    } catch (e) {
      // Rollback logic
      loadPosts(); 
    }
  }
}
