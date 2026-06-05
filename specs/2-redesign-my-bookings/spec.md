# Feature Specification: My Bookings Screen Redesign (Jericho Luxury)

**Status**: Draft
**Branch**: `feature/2-redesign-my-bookings`
**Feature Name**: redesign-my-bookings

## 1. Executive Summary
Redesign the "My Bookings" screen to implement the "Jericho Luxury" design system. The goal is to provide a premium, organized experience for users managing their pet's schedule, utilizing architectural spacing, organic curvatures (32px), and refined typography (Playfair Display & IBM Plex Sans Arabic).

## 2. Actors & Personas
- **Pet Owner (User)**: Needs to track and manage their pet's professional care appointments. They value clarity, organization, and a sense of "boutique" quality in service management.

## 3. User Scenarios
- **Scenario 1: Checking Upcoming Care**: A user opens "My Bookings" to confirm the time for their dog's "Morning Stroll". They see a beautifully organized card with a clear status indicator and high-quality pet photo.
- **Scenario 2: History Review**: A user switches the status filter to "Completed" to check how much they spent on last month's grooming. The transition is smooth and the information hierarchy makes it easy to find specific dates.
- **Scenario 3: Deep Dive**: A user taps "View Details" on a booking to see full provider info, notes, and exact location.

## 4. Functional Requirements
- **FR-01: Jericho Header**: Implement a minimalist top app bar with "PetPal" branding in Playfair Display and a profile avatar.
- **FR-02: Luxury Segmented Control**: Create a status filter (Upcoming, Completed, Cancelled) using a glass-morphic container (90% alpha, backdrop blur) and active-state highlighting in Desert Bronze.
- **FR-03: Architectural Booking Cards**: 
    - 32px organic corners.
    - Subtle 1.5px architectural border.
    - Signature accent bar (Desert Bronze for active, Warm Alabaster for history).
    - Circular pet avatar with 2px white border.
- **FR-04: Service Type Chips**: Category-specific chips (e.g., "Dog Walking", "Pet Sitting") using secondary surface colors and material icons.
- **FR-05: High-Contrast Pricing**: Display booking costs in bold Desert Bronze using Playfair Display or IBM Plex Sans Arabic (Bold).
- **FR-06: Detail CTA**: Minimalist "View Details" button with 12px radius and subtle hover/tap states.

## 5. Non-Functional Requirements
- **NFR-01: Jericho Aesthetic**: Consistent use of Desert Bronze (`#C19A6B`) and Warm Alabaster (`#F9F9F7`).
- **NFR-02: Accessibility**: High contrast ratio for text on surfaces. Minimum tap targets of 44px for filters and buttons.
- **NFR-03: Performance**: Smooth switching between booking tabs with sub-200ms latency.

## 6. Success Criteria
- [ ] All booking cards use the `radius-organic (32px)` token.
- [ ] The status filter uses the `BackdropFilter` glass effect correctly.
- [ ] Text hierarchy clearly distinguishes between section titles (Playfair) and metadata (IBM Plex Sans).
- [ ] UI remains stable and responsive during tab transitions.

## 7. Key Entities
- **Booking**: ID, ServiceType, ProviderName, PetName, PetPhoto, DateRange, TimeSlot, Price, Status (Upcoming/Completed/Cancelled).

## 8. Assumptions & Constraints
- The screen will be integrated into the existing `UserHomeScreen` navigation.
- Right-to-Left (RTL) support is required for the Arabic market.
- Bookings data will be provided via the `SittingProvider` or `WalkProvider`.

## 9. [NEEDS CLARIFICATION]
- **Q1: Empty States**: Should we show a "Book Now" CTA when no bookings exist in a category?
- **Q2: Cancellation Flow**: Can users cancel directly from this screen, or must they enter "View Details"?
- **Q3: Search/Filter**: Is search functionality required within the bookings list?
