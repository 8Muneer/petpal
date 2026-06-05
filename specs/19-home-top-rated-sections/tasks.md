# Tasks: Home Screen — Top Rated Sections

**Feature**: `19-home-top-rated-sections`
**Branch**: `19-home-top-rated-sections`
**Total Tasks**: 14
**Estimated Phases**: 5

---

## Phase 1: Setup & Data Layer

- [x] T001 Add `topRatedPOIsProvider` to `lib/features/explore/presentation/providers/poi_provider.dart` — returns up to 10 POIs of a given type sorted by rating descending, reusing `nearbyPOIsProvider`
- [x] T002 [P] Verify existing `userSittingRequestsProvider` filters by current user in `lib/features/sitting/presentation/providers/sitting_provider.dart` — confirm it returns requests for the logged-in user only

---

## Phase 2: Foundational — Reusable Section Widget

- [x] T003 Create `HomeTopRatedSection` widget in `lib/features/home/presentation/widgets/home_top_rated_section.dart` — accepts `title`, `onMoreTap`, `itemCount`, `itemBuilder`, `itemHeight`, optional `emptyState`. Renders: RTL header row (title + "עוד" button), horizontal `ListView.builder`, empty state fallback, and `TweenAnimationBuilder` entrance animation (fade+slide, 800ms, easeOutCubic)

---

## Phase 3: Home Screen Refactor — User Stories

### US1: My Requests Section (Priority — appears first)

- [x] T004 [US1] Add My Requests `SliverToBoxAdapter` using `HomeTopRatedSection` in `lib/features/home/presentation/screens/user_home_screen.dart` — watches `userSittingRequestsProvider`, renders each request as a compact horizontal card, "עוד" navigates to Explore tab index 4
- [x] T005 [US1] Create empty state widget for My Requests: "אין בקשות פעילות" with hint text and icon in `lib/features/home/presentation/screens/user_home_screen.dart`

### US2: Sitters Section

- [x] T006 [US2] Add Sitters `SliverToBoxAdapter` using `HomeTopRatedSection` in `lib/features/home/presentation/screens/user_home_screen.dart` — watches `filteredSittingServicesProvider`, takes top 10 by rating, renders each as `LuxuryServiceCard`, "עוד" navigates to Explore tab index 0

### US3: Dog Parks Section

- [x] T007 [US3] Add Dog Parks `SliverToBoxAdapter` using `HomeTopRatedSection` in `lib/features/home/presentation/screens/user_home_screen.dart` — watches `topRatedPOIsProvider(type: POIType.park)`, renders each as `DiscoveryCard` with green theme, "עוד" navigates to Explore tab index 1, card tap also navigates to tab index 1

### US4: Vets Section

- [x] T008 [US4] Add Vets `SliverToBoxAdapter` using `HomeTopRatedSection` in `lib/features/home/presentation/screens/user_home_screen.dart` — watches `topRatedPOIsProvider(type: POIType.vet)`, renders each as `DiscoveryCard` with red theme, "עוד" navigates to Explore tab index 2, card tap also navigates to tab index 2

### US5: Stores Section

- [x] T009 [US5] Add Stores `SliverToBoxAdapter` using `HomeTopRatedSection` in `lib/features/home/presentation/screens/user_home_screen.dart` — watches `topRatedPOIsProvider(type: POIType.store)`, renders each as `DiscoveryCard` with orange theme, "עוד" navigates to Explore tab index 3, card tap also navigates to tab index 3

---

## Phase 4: Cleanup — Remove Old Sections

- [x] T010 Remove the old "Top Rated This Week" `SliverToBoxAdapter` section (lines ~332-391) from `lib/features/home/presentation/screens/user_home_screen.dart`
- [x] T011 Remove `_FeaturedSittersSection` sliver + widget class, "Recently Viewed" section, "Community Feed Header", and `postsAsync.when(...)` community feed block from `lib/features/home/presentation/screens/user_home_screen.dart`
- [x] T012 [P] Remove unused imports (`feedRepositoryProvider`, `feedProvider`, `NearbyEssentials`, `LuxuryRecentTile` if unused) from `lib/features/home/presentation/screens/user_home_screen.dart`
- [x] T013 [P] Delete `lib/features/home/presentation/widgets/nearby_essentials.dart` — no longer referenced

---

## Phase 5: Verification & Polish

- [x] T014 Run `dart analyze lib/features/home/ lib/features/explore/` and fix all errors. Verify app launches on emulator, Home screen shows 5 sections in order (My Requests → Sitters → Parks → Vets → Stores), horizontal scroll works, "עוד" links navigate correctly, empty states display, and scroll performance is smooth

---

## Dependencies

```
T001 → T007, T008, T009 (topRatedPOIsProvider needed by POI sections)
T002 → T004 (request provider verification needed before building UI)
T003 → T004, T006, T007, T008, T009 (widget must exist before use)
T010, T011 → T012 (remove sections before cleaning imports)
T004-T009 can run in parallel after T001-T003 complete
T010-T013 can run after T004-T009 complete
T014 runs last
```

## Parallel Execution Opportunities

| Group | Tasks | Constraint |
|-------|-------|------------|
| Data Layer | T001, T002 | Independent, different files |
| US Sections | T004-T009 | All depend on T003, but are independent of each other |
| Cleanup | T012, T013 | Independent, different files |

## Implementation Strategy

**MVP**: T001 → T003 → T006 (Sitters section only) → verify
**Increment 2**: T004-T005 (My Requests) + T007-T009 (POI sections)
**Increment 3**: T010-T013 (cleanup) → T014 (verification)
