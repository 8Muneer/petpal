# Task List: POI Integration & Display

**Skills Applied**: `concise-planning` (for clear, actionable tasks), `code-review-excellence` (for ensuring tests and validations are built-in), `impeccable` (for UI polish tasks), `kaizen` (for incremental delivery).

## Phase 1: Foundation (Data & Routing)
- [x] T001 [P] Ensure `watchAllPOIs()` stream exists and is accessible to user interfaces without admin privileges in `lib/features/explore/data/repositories/explore_repository.dart`.
- [x] T002 Update `app_router.dart` to include a new route for `POIDetailScreen` (`/poi/:id`).

## Phase 2: Reusable Components (UI/UX)
- [x] T003 Create `POICard` widget in `lib/features/explore/presentation/widgets/poi_card.dart` ensuring compliance with Organic Modernism (soft corners, clear hierarchy).
- [x] T004 Create a static map placeholder widget with a "Get Directions" button that utilizes `url_launcher` in `lib/features/explore/presentation/widgets/poi_map_placeholder.dart`.

## Phase 3: Screen Integration [US1: Home & Explore]
- [x] T005 [US1] Update `UserHomeScreen` (`lib/features/home/presentation/screens/user_home_screen.dart`) to include a "Nearby Essentials" section displaying a horizontal `ListView.builder` of max 10 POIs.
- [x] T006 [US1] Add a "More" text button next to the "Nearby Essentials" title that routes to `/explore`.
- [x] T007 [US1] Update `ExploreScreen` (`lib/features/explore/presentation/screens/explore_screen.dart`) to consume the POI stream and display all POIs in a vertical scrolling grid or list.

## Phase 4: Detail Screen [US2: View Details]
- [x] T008 [US2] Create `POIDetailScreen` (`lib/features/explore/presentation/screens/poi_detail_screen.dart`) using `CustomScrollView` and `SliverAppBar` for the hero image.
- [x] T009 [US2] Integrate the `poi_map_placeholder` into the detail screen layout.
- [x] T010 [US2] Ensure the detail screen handles null values gracefully (e.g., if phone number or address is missing).

## Phase 5: Polish & Cross-Cutting
- [x] T011 Run `dart analyze` and fix any new deprecation warnings (`withOpacity` -> `withValues`).
- [x] T012 Verify visually that the `POICard` scales gracefully on smaller screens without RenderFlex overflow.
