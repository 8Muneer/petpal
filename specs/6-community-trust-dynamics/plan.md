# Implementation Plan: Community Trust Dynamics

Implement the functional layers of the Trust Network: Karma, Discounts, and Reputation.

## User Review Required
> [!IMPORTANT]
> **Karma Balance**: 1 pt per Treat, 3 pts per Recommendation. We will implement a "Karma History" list in the profile to track these.
> **Booking Link**: Clicking "Book Now" will pass the service ID and discount percentage to the existing booking controller.

## Proposed Changes

### 1. [Feature] Karma Engine
#### [MODIFY] [community_post.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/features/community/domain/entities/community_post.dart)
- Ensure the entity supports the fields needed for the engine (already mostly there).

#### [MODIFY] [community_repository.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/features/community/data/repositories/community_repository.dart)
- Update `MockCommunityRepository` to simulate karma updates in the mock user profiles.

#### [NEW] [karma_provider.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/features/community/presentation/providers/karma_provider.dart)
- A specialized provider to manage the user's total karma and history.

### 2. [Feature] Neighbor Profile
#### [NEW] [neighbor_profile_screen.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/features/community/presentation/screens/neighbor_profile_screen.dart)
- Layout: Header with Karma total -> "About" section -> "Trust Contributions" (List of their posts).
- Design: Luxury aesthetic matching the Home screen.

### 3. [Integration] Booking & Discounts
#### [MODIFY] [community_feed_screen.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/features/community/presentation/screens/community_feed_screen.dart)
- Logic for the `onBookService` callback in the feed cards.
- Navigation to `/sitting/detail` or `/walks/detail` with discount metadata.

## Technical Context
- **Architecture**: Riverpod for state management.
- **Routing**: GoRouter for deep links to profiles and bookings.

## Verification Plan
### Manual Verification
- Treat a post -> check karma increase in profile.
- Book from recommendation -> verify discount appears in the booking summary.
- Click avatar -> verify correct neighbor profile loads.
