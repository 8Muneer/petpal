# Implementation Plan: Community Trust Network (Luxury)

**Feature**: community-trust-network
**Branch**: `feature/4-community-trust-network`

## 1. Technical Strategy
We will implement the Community screen as a high-fidelity Flutter screen using a `CustomScrollView` with staggered animations. Since the backend for Karma and Treats is not yet ready, we will implement a **Repository Pattern** with a `MockCommunityRepository` that can be easily swapped for a `FirebaseCommunityRepository` later.

### Skills to Use:
- `frontend-design`: For the high-fidelity feed and utility chips.
- `animate`: For the "Treat" float-up animations and list entry effects.
- `arrange`: For the 32px organic spacing and visual rhythm.
- `colorize`: For the Alabaster/Bronze palette.

## 2. Proposed Changes

### Phase 1: Foundation (Models & Providers)
- [NEW] `lib/features/community/domain/entities/community_post.dart`:
  - `CommunityPost` entity with `trustKarma`, `associatedService`, and `isUrgent` flags.
- [NEW] `lib/features/community/presentation/providers/community_provider.dart`:
  - `StateNotifier` for the feed (Filtering logic for Pulse Bar).
  - `KarmaController` for managing treat interactions.

### Phase 2: Core Components (Luxury Widgets)
- [NEW] `lib/core/widgets/luxury_trust_card.dart`:
  - 32px organic radius.
  - Custom header with Karma badge.
  - Animated "Give Treat" interaction.
- [NEW] `lib/core/widgets/luxury_utility_chip.dart`:
  - Glass-morphism card embedded in posts for service recommendations.
  - "Book Now" CTA.
- [NEW] `lib/core/widgets/neighborhood_pulse_bar.dart`:
  - Horizontal filter chips with Luxury styling.

### Phase 3: Screen Assembly
- [NEW] `lib/features/community/presentation/screens/community_feed_screen.dart`:
  - `SliverAppBar` for the "Trust Network" header.
  - `NeighborhoodAlertBanner` integration.
  - `SliverList` for the community feed with `AnimatedList` support.

### Phase 4: Integration
- [MODIFY] `lib/features/home/presentation/screens/user_home_screen.dart`:
  - Replace the current empty community tab with `CommunityFeedScreen`.

## 3. Verification Plan

### Automated Tests
- Widget tests for `LuxuryTrustCard` to ensure 32px radius and visibility of Karma badges.
- Provider tests for filtering logic (e.g., filtering by 'Recommendations').

### Manual Verification
- Verify the "Give Treat" animation triggers correctly.
- Ensure the "Book Now" button on utility chips correctly initiates the booking flow.
- Check responsive layout on small vs large viewports.
