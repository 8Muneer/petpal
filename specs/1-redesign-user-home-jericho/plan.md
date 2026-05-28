# Implementation Plan: PetPal User Home Screen Redesign (Jericho Luxury)

**Feature**: redesign-user-home-jericho
**Proposed Branch**: `feature/1-redesign-user-home-jericho`

## 1. Technical Context
- **Current State**: The `user_home_screen.dart` uses a basic layout with some existing styling.
- **Goal**: Transition to the Jericho design system with high-fidelity components and motion.
- **Skills to Use**: `frontend-design`, `animate`, `bolder`, `delight`, `overdrive`, `typeset`, `arrange`.

## 2. Proposed Changes

### Phase 1: Foundation (Design Tokens)
- [MODIFY] `lib/core/theme/app_theme.dart`:
  - Integrate `color-primary (#C19A6B)` and `color-surface (#F9F9F7)`.
  - Add `Playfair Display` for headlines and `IBM Plex Sans Arabic` for body text.
  - Define a global `radius-organic` constant (32.0).

### Phase 2: Core Components (Jericho Widgets)
- [NEW] `lib/core/widgets/jericho_hero.dart`:
  - Parallax background image (0.3 intensity).
  - Floating Glass Search Bar (Sticky transition support).
- [NEW] `lib/core/widgets/glass_pill.dart`:
  - Reusable glass-morphism pill with `BackdropFilter`.
- [NEW] `lib/core/widgets/jericho_service_card.dart`:
  - 280px wide card with 32px corners.
  - Glass rating pill overlay.
- [NEW] `lib/core/widgets/jericho_recent_tile.dart`:
  - 140px square tile for recently viewed services.

### Phase 3: Screen Assembly
- [MODIFY] `lib/features/home/presentation/screens/user_home_screen.dart`:
  - Implement the "Jericho Flow": Parallax Hero -> Category Chips -> Top Rated Scroller -> Recently Viewed Scroller -> Community Feed.
  - Integrate the new components.
  - Implement the "Sticky Search" logic.

### Phase 4: Polish & Motion
- Add scroll-driven animations using `animate` and `overdrive` concepts.
- Refine typography with `typeset`.
- Ensure consistent spacing with `arrange`.

## 3. Verification Plan
- **Manual Verification**:
  - Verify parallax effect intensity matches Option B (0.3).
  - Verify search bar sticks to top correctly.
  - Verify "Recommended" suggestions show when history is empty.
  - Verify UI looks premium and follows the Desert Bronze palette.
- **Automated Tests**:
  - Widget tests for `JerichoServiceCard` and `GlassSearchBar`.
