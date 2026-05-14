# Tasks: Community Trust Dynamics

## Phase 1: Setup & Foundational
- [ ] T001 Initialize `karma_provider.dart` with state notifier for tracking points
- [ ] T002 Update `MockCommunityRepository` to support simulated karma persistence
- [ ] T003 Create `KarmaTransaction` model for history tracking

## Phase 2: [US1] Karma System
- [ ] T004 [P] [US1] Implement `giveTreat` logic in `community_feed_provider.dart` (+1 pt)
- [ ] T005 [P] [US1] Implement recommendation bonus logic (+3 pts)
- [ ] T006 [US1] Add "Karma Info" dialog to `CommunityFeedScreen`

## Phase 3: [US2] Neighbor Profiles
- [ ] T007 [P] [US2] Create `NeighborProfileScreen` layout in `lib/features/community/presentation/screens/`
- [ ] T008 [US2] Implement "Contribution List" (posts by specific user) in profile
- [ ] T009 [US2] Connect feed avatars to `NeighborProfileScreen` via GoRouter

## Phase 4: [US3] Booking & Discounts
- [ ] T010 [P] [US3] Update `LuxuryTrustCard` to pass discount data to `onBookService`
- [ ] T011 [US3] Implement navigation logic in `community_feed_screen.dart` to booking flow with discount
- [ ] T012 [US3] Add "Discount Applied" toast notification on booking initiation

## Phase 5: Polish
- [ ] T013 [P] Add haptic feedback and lottie animation for "Treat" interaction
- [ ] T014 Final design audit for consistency with Luxury theme
