# Implementation Plan: Community System Enhancements

## Technical Context
We are maturing the PetPal Community feature from a mocked feed into a production-ready ecosystem. The current system uses Riverpod and Firestore but relies on placeholders for user data and alerts. We need to implement a commenting system, real user identity integration, dynamic alerts, and pagination.

### Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (`StateNotifierProvider`)
- **Backend**: Firebase Firestore
- **Design System**: Luxury "Organic Modernism" (Custom Theme)

## Proposed Changes

### 1. Data Layer Enhancements
- **[NEW] [community_comment.dart](file:///lib/features/community/domain/entities/community_comment.dart)**: Define the comment entity.
- **[MODIFY] [community_post.dart](file:///lib/features/community/domain/entities/community_post.dart)**: Remove `neighborDiscount` field.
- **[MODIFY] [community_repository.dart](file:///lib/features/community/data/repositories/community_repository.dart)**: 
  - Add `getComments(String postId)`
  - Add `addComment(CommunityComment comment)`
  - Implement pagination in `getPosts()` using `limit` and `startAfter`.

### 2. Provider Logic
- **[MODIFY] [community_provider.dart](file:///lib/features/community/presentation/providers/community_provider.dart)**:
  - Update `fetchPosts` to support pagination.
  - Add `CommentController` to manage comment state.
  - Connect to `authStateChangesProvider` for real user identity.

### 3. UI Refinement (Luxury Aesthetic)
- **[MODIFY] [luxury_trust_card.dart](file:///lib/core/widgets/luxury_trust_card.dart)**:
  - Remove discount chip.
  - Implement real user profile fetching.
- **[NEW] [community_comments_sheet.dart](file:///lib/features/community/presentation/widgets/community_comments_sheet.dart)**: A premium bottom sheet for reading/writing comments.
- **[MODIFY] [community_feed_screen.dart](file:///lib/features/community/presentation/screens/community_feed_screen.dart)**:
  - Add `RefreshIndicator`.
  - Add `ScrollController` listener for infinite scroll.
  - Integrate dynamic `NeighborhoodAlertBanner`.

## Skills & Principles
- **[Skills] frontend-design**: Creating high-end Empty State widgets and Comment UI.
- **[Skills] animate**: Adding micro-interactions for "Give Treat" and "Post Comment."
- **[Skills] optimize**: Implementing efficient Firestore pagination to minimize reads and lag.
- **[Skills1] flutter-expert**: Using Riverpod `AutoDispose` and `Family` providers for scoped comment feeds.
- **[Skills1] clean-code**: Refactoring repositories to use a clean `PaginationResult` wrapper.
- **[Skills1] database-architect**: Designing a non-nested comment structure for high scalability.

## Verification Plan
### Automated Tests
- `dart test`: Verify pagination logic in `CommunityRepository`.
- `flutter test`: Verify `CommunityComment` serialization.

### Manual Verification
1. **Comment Flow**: Post a comment, verify it appears in the list and the count on the card increments.
2. **Infinite Scroll**: Scroll to the bottom, verify next 15 posts load seamlessly.
3. **Identity Check**: Verify that your own name and neighborhood appear on your posts.
4. **Marketplace Tagging**: Create a post, search for a sitter, and verify the card links correctly.
