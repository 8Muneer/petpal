# Tasks: Explore Discovery Hub

## Phase 1: Setup
- [ ] T001 Initialize feature directory structure for `lib/features/explore`
- [ ] T002 Register `/explore` route in `lib/core/navigation/app_router.dart`

## Phase 2: Foundational Components
- [ ] T003 [P] Create `BoutiquePropertyCard` base component in `lib/core/widgets/boutique_property_card.dart`
- [ ] T004 [P] Implement Pill-shaped Search Bar widget in `lib/features/explore/presentation/widgets/explore_search_bar.dart`
- [ ] T005 [P] Create `FloatingNavBar` container in `lib/core/widgets/floating_nav_bar.dart`

## Phase 3: [US1] Pet Owner - Browse Sitters
- [ ] T006 [US1] Implement `ExploreScreen` scaffold with role detection in `lib/features/explore/presentation/screens/explore_screen.dart`
- [ ] T007 [US1] Create `SitterBrowseView` with `CustomScrollView` and "Browse Sitters" tab logic
- [ ] T008 [P] [US1] Build Results Header (Count & Sort) for Sitters list
- [ ] T009 [US1] Bind `filteredSittingServicesProvider` to the `BoutiquePropertyCard` list
- [ ] T010 [US1] Add staggered entrance animations to the Sitter list cards

## Phase 4: [US2] Pet Owner - My Requests
- [ ] T011 [US2] Create `OwnerRequestsView` sub-tab in `ExploreScreen`
- [ ] T012 [US2] Implement Request List fetching for current user in `lib/features/sitting/presentation/providers/sitting_provider.dart`
- [ ] T013 [US2] Add "New Request" Floating Action Button to `OwnerRequestsView`

## Phase 5: [US3] Sitter - Job Discovery
- [ ] T014 [US3] Create `SitterJobDiscoveryView` specifically for Sitter role
- [ ] T015 [US3] Bind `publicSittingRequestsProvider` to the Job Discovery list
- [ ] T016 [US3] Adapt `BoutiquePropertyCard` to display Pet Details (Breed, Age) in subtitle for jobs

## Phase 6: Navigation Integration & Polish
- [ ] T017 Replace global `BottomNavigationBar` with `FloatingNavBar` in `lib/features/home/presentation/screens/service_provider_home_screen.dart`
- [ ] T018 Implement "Soft colored circular background" active state for `FloatingNavBar`
- [ ] T019 Final visual QA for RTL alignment and Glassmorphic effects across all Explore views
