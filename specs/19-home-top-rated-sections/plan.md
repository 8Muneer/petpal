# Implementation Plan: Home Screen — Top Rated Sections

**Feature**: `19-home-top-rated-sections`
**Branch**: `19-home-top-rated-sections`
**Spec**: [spec.md](spec.md)

## Technical Context

- **Framework**: Flutter 3.x + Dart 3.x
- **State Management**: Riverpod 2.x with code generation
- **Architecture**: Clean Architecture (feature-driven)
- **Design System**: Organic Modernism (custom theme tokens in `app_theme.dart`)
- **Localization**: Hebrew RTL (hardcoded, `TextDirection.rtl` wrappers)
- **Data Layer**: Firestore + Riverpod providers
- **Navigation**: GoRouter + Riverpod `StateProvider` for tab index sync

## Constitution Check

- ✅ **Organic Modernism**: All new UI uses existing `AppColors`, `AppTextStyles`, `AppSpacing`, and `AppShadows` tokens
- ✅ **RTL Layout**: Hebrew text direction maintained via `Directionality` wrappers
- ✅ **Riverpod State**: New data access uses existing providers, no raw Firestore queries in widgets
- ✅ **Existing Components**: Reuses `BoutiquePropertyCard`, `DiscoveryCard`, `EmptyStateCard`, `SectionHeader`

## Proposed Changes

### Phase 1: Data Layer — POI Seed Data

#### [MODIFY] [poi_provider.dart](../../lib/features/explore/presentation/providers/poi_provider.dart)

- Add a new `topRatedPOIsProvider(type)` that returns up to 10 POIs sorted by rating descending.
- Reuses existing `nearbyPOIsProvider` data, applies `.toList()..sort((a,b) => b.rating.compareTo(a.rating))` and `.take(10)`.

---

### Phase 2: Home Screen Section Widget

#### [NEW] [home_top_rated_section.dart](../../lib/features/home/presentation/widgets/home_top_rated_section.dart)

A reusable widget `HomeTopRatedSection` encapsulating:
- **Header row**: Section title (Hebrew) + "עוד" (More) `TextButton` aligned RTL
- **Horizontal scroll list**: `SizedBox(height: N) > ListView.builder(scrollDirection: Axis.horizontal)`
- **Empty state**: Falls back to `EmptyStateCard` when items list is empty
- **Entrance animation**: `TweenAnimationBuilder<double>` with fade + vertical slide (800ms, `Curves.easeOutCubic`)

**Props**:
```dart
final String title;
final VoidCallback onMoreTap;
final int itemCount;
final Widget Function(BuildContext, int) itemBuilder;
final double itemHeight; // Configurable per section type
final Widget? emptyState;
```

**Skills applied**:
- **arrange**: Consistent spacing scale (`AppSpacing`), tight grouping within section, generous separation between sections (32-48px). Horizontal scroll with `AppSpacing.marginPage` padding.
- **animate**: Staggered entrance with `TweenAnimationBuilder`, fade+slide (0→1 opacity, 20px→0 translateY). 800ms duration, `easeOutCubic` curve. No bounce/elastic.
- **distill**: Single focused widget with one responsibility. No nested cards. Clean props interface.
- **harden**: Empty state handling, text overflow on section title (`maxLines: 1, overflow: ellipsis`), RTL-safe layout with `CrossAxisAlignment.start`.
- **flutter-expert**: `const` constructors, `SizedBox` constraints, `ListView.builder` for lazy rendering.
- **clean-code**: Intention-revealing name, single responsibility, < 60 lines, zero side effects.
- **ui-ux-designer**: Progressive disclosure (show top 10 → "More" reveals full list), visual hierarchy via spacing.
- **senior-architect**: Reusable, composable widget. No hardcoded data. Props-driven.

---

### Phase 3: Home Screen Refactor

#### [MODIFY] [user_home_screen.dart](../../lib/features/home/presentation/screens/user_home_screen.dart)

**Remove** (lines ~332-510):
- The entire "Top Rated" `SliverToBoxAdapter` block
- The `_FeaturedSittersSection()` sliver
- The "Recently Viewed / Recommended" `SliverToBoxAdapter` block
- The "Community Feed Header" sliver
- The "Community Feed Items" `postsAsync.when(...)` block
- The bottom spacer

**Add** (5 new `SliverToBoxAdapter` blocks in this order):

1. **הבקשות שלי (My Requests)** — Top priority
   - Uses `HomeTopRatedSection` with user's sitting requests from `userSittingRequestsProvider`
   - Item builder uses `BoutiquePropertyCard`
   - "More" taps → `exploreTabIndexProvider = 4`, `onTabChange(1)`

2. **שומרים (Sitters)** — From live Firestore data
   - Uses `HomeTopRatedSection` with `filteredSittingServicesProvider`
   - Item builder uses `LuxuryServiceCard`
   - "More" taps → `exploreTabIndexProvider = 0`, `onTabChange(1)`

3. **גינות כלבים (Dog Parks)** — From `topRatedPOIsProvider(POIType.park)`
   - Uses `HomeTopRatedSection` with `DiscoveryCard`
   - "More" taps → `exploreTabIndexProvider = 1`, `onTabChange(1)`

4. **וטרינרים (Vets)** — From `topRatedPOIsProvider(POIType.vet)`
   - Same pattern, tab index 2

5. **חנויות (Stores)** — From `topRatedPOIsProvider(POIType.store)`
   - Same pattern, tab index 3

**Skills applied**:
- **onboard**: Empty states for each section guide users with contextual CTAs ("אין בקשות פעילות" with action hint)
- **arrange**: Generous 32px vertical gaps between sections. Tight 12-16px gaps within sections. Visual rhythm through alternating card heights (requests=120, sitters=320, POI=200).

**Also remove**:
- Unused `NearbyEssentials` import (already done)
- Unused `feedRepositoryProvider` and `feedProvider` imports (if no longer referenced)
- The `_FeedPostCard` private widget class (if only used in removed community feed)

---

### Phase 4: Cleanup

#### [DELETE] [nearby_essentials.dart](../../lib/features/home/presentation/widgets/nearby_essentials.dart)

No longer used anywhere after the refactor.

## Data Model

No new entities. Reuses:
- `SittingService` → from `filteredSittingServicesProvider`
- `POI` → from `nearbyPOIsProvider` / new `topRatedPOIsProvider`
- `SittingRequest` → from `userSittingRequestsProvider`

## Verification Plan

### Automated
- `dart analyze lib/features/home/` — zero errors
- `dart analyze lib/features/explore/` — zero errors

### Manual
- Launch app on emulator
- Verify Home screen shows 5 sections in order: My Requests → Sitters → Parks → Vets → Stores
- Verify each section header has Hebrew title + "עוד" link
- Tap "עוד" on each section → verify correct Explore tab opens
- Verify horizontal scroll works on each section
- Verify empty state appears when no requests exist
- Verify smooth scroll performance (no jank)
- Verify RTL layout is correct
