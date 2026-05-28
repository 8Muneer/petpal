# Tasks: Community System Enhancements

## Phase 1: Setup & Data Integrity
- [ ] T001 Create `CommunityComment` entity in `lib/features/community/domain/entities/community_comment.dart`
- [ ] T002 [MODIFY] Remove `neighborDiscount` from `CommunityPost` in `lib/features/community/domain/entities/community_post.dart`
- [ ] T003 [MODIFY] Update `CommunityRepository` interface in `lib/features/community/domain/repositories/community_repository.dart` to include comments and pagination

## Phase 2: Foundational Logic (Repository & Models)
- [ ] T004 [MODIFY] Implement Firestore pagination logic in `lib/features/community/data/repositories/community_repository_impl.dart`
- [ ] T005 [P] Implement `getComments` and `addComment` in `lib/features/community/data/repositories/community_repository_impl.dart`
- [ ] T006 [MODIFY] Update `CommunityPostModel` serialization to match entity changes in `lib/features/community/data/models/community_post_model.dart`

## Phase 3: [US1] Comment System
- [ ] T007 [P] [US1] Create `CommunityCommentsSheet` widget in `lib/features/community/presentation/widgets/community_comments_sheet.dart`
- [ ] T008 [US1] Implement `CommentsProvider` in `lib/features/community/presentation/providers/comments_provider.dart`
- [ ] T009 [US1] Connect comment icon on `LuxuryTrustCard` to open `CommunityCommentsSheet` in `lib/core/widgets/luxury_trust_card.dart`

## Phase 4: [US2] Real Identity & Marketplace Integration
- [ ] T010 [US2] Refactor `LuxuryTrustCard` to use real user data from `AuthProvider` in `lib/core/widgets/luxury_trust_card.dart`
- [ ] T011 [US2] Implement real marketplace search in `ServiceLookupField` in `lib/features/community/presentation/widgets/service_lookup_field.dart`
- [ ] T012 [US2] Update `CreateTrustPostScreen` to pull active user profile in `lib/features/community/presentation/screens/create_trust_post_screen.dart`

## Phase 5: [US3] Dynamic Alerts & Pulse
- [ ] T013 [US3] Create `CommunityAlert` entity and repository fetch logic in `lib/features/community/domain/entities/community_alert.dart`
- [ ] T014 [US3] Refactor `_NeighborhoodAlertBanner` to use dynamic data in `lib/features/community/presentation/screens/community_feed_screen.dart`

## Phase 6: [US4] Performance & Pagination
- [ ] T015 [US4] Implement `ScrollController` listener for infinite scroll in `lib/features/community/presentation/screens/community_feed_screen.dart`
- [ ] T016 [US4] Add `RefreshIndicator` logic in `lib/features/community/presentation/screens/community_feed_screen.dart`
- [ ] T017 [P] [US4] Implement premium Empty State CTA in `lib/features/community/presentation/widgets/community_empty_state.dart`

## Phase 7: Polish & Cleanup
- [ ] T018 [P] Add animation triggers for comment posting and "Give Treat" in `lib/core/widgets/luxury_trust_card.dart`
- [ ] T019 Final UI/UX audit and performance check across all community widgets

## Dependencies
- US1 (Comments) depends on T001, T003, T005.
- US4 (Pagination) depends on T004.
