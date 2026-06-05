# Implementation Plan - Sitter Marketplace & Booking Flow

## Technical Context
- **Architecture**: Clean Architecture with Riverpod for state management.
- **Theme**: Organic Modernism (Desert Bronze palette, Glassmorphism, 32px radius).
- **Localization**: Hebrew (RTL) consistency.
- **Visual Reference**: High-fidelity parallax profile screen based on user's HTML/Tailwind mockup.

## Proposed Changes

### Data & Domain Layer
- [MODIFY] [sitting_service.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/features/sitting/domain/entities/sitting_service.dart): Add `bio`, `experienceYears`, `locationArea`, `verifiedStatus`, and `reviewsCount` fields.
- [MODIFY] [sitting_request.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/features/sitting/domain/entities/sitting_request.dart): Add `rules` list (Strings) and `isPublicJob` flag.
- [MODIFY] [sitting_repository.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/features/sitting/data/repositories/sitting_repository.dart): Add `getAvailableServices()` and `getPublicRequests()` with hard-filtering logic.

### Presentation Layer (Providers)
- [NEW] `lib/features/sitting/presentation/providers/marketplace_provider.dart`: `AsyncNotifier` to handle filtering and searching for sitters and public jobs.
- [NEW] `lib/features/sitting/presentation/providers/sitter_detail_provider.dart`: Manage state for the specific sitter being viewed, including their availability.

### Presentation Layer (Screens & Widgets)
- [NEW] `lib/features/sitting/presentation/screens/sitter_marketplace_screen.dart`: 
    - Dedicated tab view with segmented control (Find Sitters / Browse Jobs).
    - Search bar and filter chips for "Rules".
- [NEW] `lib/features/sitting/presentation/screens/sitter_detail_screen.dart`:
    - **Hero**: `SliverAppBar` with parallax image and transparent-to-solid transition.
    - **Header**: Glassmorphism title card with rating and price.
    - **Quick Stats**: Row of icon-label pairs (Verified, Experience, Area).
    - **Service Tags**: Horizontal wrap of chips.
    - **Calendar**: `SitterCalendarWidget` for availability visualization.
    - **Bottom Bar**: Sticky "Book Now" action.
- [MODIFY] [user_home_screen.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/features/home/presentation/screens/user_home_screen.dart):
    - Connect "שמירה" (Sitting) chip to Marketplace.
    - Add "Featured Sitters" horizontal list.
- [MODIFY] [service_provider_home_screen.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/features/home/presentation/screens/service_provider_home_screen.dart):
    - Add "List Your Service" CTA in the dashboard.

## Verification Plan

### Automated Tests
- [ ] Test `SittingRepository` filter logic ensures sitters without required rules are excluded.
- [ ] Test `MarketplaceProvider` correctly toggles between Jobs and Sitters.

### Manual Verification
- [ ] Verify Parallax scrolling behavior on Sitter Detail screen.
- [ ] Verify RTL layout for the Availability Calendar (Days of week order).
- [ ] Verify "Book Now" flows correctly to the existing booking process.
- [ ] Verify "Public Job" posting appears in the Sitter's "Browse Jobs" view.
