# Tasks: PetPal User Home Screen Redesign (Jericho Luxury)

**Feature**: redesign-user-home-jericho
**Spec**: `specs/1-redesign-user-home-jericho/spec.md`
**Plan**: `specs/1-redesign-user-home-jericho/plan.md`

---

## Phase 1: Setup & Design System
*Goal: Establish the Jericho foundation in the project theme.*

- [x] T001 Define Jericho Design Tokens (Colors, Typography, Radius) in `lib/core/theme/app_theme.dart`
- [x] T002 Create reusable Jericho UI constants file (if needed for radii/spacing)

---

## Phase 2: Foundational Components
*Goal: Build the individual building blocks required for the home screen.*

- [x] T003 [P] Create `GlassPill` widget with `BackdropFilter` in `lib/core/widgets/glass_pill.dart`
- [x] T004 [P] Implement `JerichoServiceCard` (280px, 32px radius) in `lib/core/widgets/jericho_service_card.dart`
- [x] T005 [P] Implement `JerichoRecentTile` (140px square) in `lib/core/widgets/jericho_recent_tile.dart`

---

## Phase 3: User Story 1 (Home Screen Overhaul)
*Goal: Assemble the new home screen experience with motion and sticky elements.*

- [x] T006 [P] [US1] Build `JerichoHero` with 0.3 ratio parallax effect in `lib/core/widgets/jericho_hero.dart`
- [x] T007 [P] [US1] Create `GlassSearchBar` with focus on 90% alpha glass effect
- [x] T008 [US1] Refactor `lib/features/home/presentation/screens/user_home_screen.dart` to implement the new layout flow
- [x] T009 [US1] Implement Sticky Search Bar logic (transitioning as user scrolls)
- [x] T010 [US1] Implement "Recommended for You" fallback for empty recently viewed history

---

## Phase 4: Polish & Luxury Finish
*Goal: Add the final "WOW" factor with animations and refined typesetting.*

- [x] T011 [P] Apply `typeset` and `arrange` rules to perfect spacing and hierarchy
- [x] T012 Add section reveal animations (fade-in + slide-up) for the scrollers
- [x] T013 Final visual audit against Jericho design specs (Desert Bronze vs Alabaster)

---

## Dependencies & Strategy
1. **MVP First**: Tasks T001-T008 form the core MVP.
2. **Parallelization**: T003, T004, and T005 can be built simultaneously once T001 is done.
3. **Delivery**: Incremental updates starting from the Theme -> Components -> Screen Assembly.
