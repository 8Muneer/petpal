# Tasks: Lost & Found Redesign

**Feature**: redesign-lost-and-found

## Phase 1: Setup & Data Foundation
- [ ] T001 Verify `LostFoundPost` model supports new fields (Breed, Age, Gender) in `lib/features/feed/domain/entities/lost_found_post.dart`
- [ ] T002 Create `LostFoundController` to manage tab state (Lost/Found) and search queries in `lib/features/feed/presentation/providers/lost_found_controller.dart`

## Phase 2: Foundational UI Components
- [ ] T003 [P] Create `JerichoLostFoundCard` with 32px organic radius and status-specific glass pills in `lib/core/widgets/jericho_lost_found_card.dart`
- [ ] T004 [P] Create `LostFoundToggleBar` (Segmented Control) for switching between אבדות and מציאות in `lib/core/widgets/lost_found_toggle_bar.dart`
- [ ] T005 [P] Create `LostFoundFilterBar` with glassmorphic search and filter chips in `lib/core/widgets/lost_found_filter_bar.dart`

## Phase 3: Screen Overhaul (User Story 1: Browsing Posts)
- [ ] T006 [US1] Refactor `LostFoundFeedScreen` to use a `SliverScrollView` with the new Jericho Top Bar in `lib/features/feed/presentation/screens/lost_found_feed_screen.dart`
- [ ] T007 [US1] Implement the tab switching logic using `PageView` or `IndexedStack` to isolate Lost and Found feeds
- [ ] T008 [US1] Apply staggered entrance animations to cards using the `animate` skill logic
- [ ] T009 [US1] Integrate the `LostFoundFilterBar` with real-time search functionality

## Phase 4: Map View (User Story 2: Location Visualization)
- [ ] T010 [US2] Implement the Map View toggle in the top bar or filter bar
- [ ] T011 [US2] Create a `LostFoundMapView` widget with custom themed Google Maps pins
- [ ] T012 [US2] Sync map markers with the current tab and search filters

## Phase 5: Polish & Cross-Cutting
- [ ] T013 [P] Handle empty states for both Lost and Found feeds with context-aware illustrations
- [ ] T014 [P] Ensure all internal chat links from cards navigate to the correct conversation
- [ ] T015 Final visual QA pass for organic curvatures and color consistency
