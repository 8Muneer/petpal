# Feature Specification: Lost & Found Redesign (Jericho Luxury)

**Status**: Draft
**Branch**: `feature/3-redesign-lost-and-found`
**Feature Name**: redesign-lost-and-found

## 1. Executive Summary
Redesign the "Lost & Found" module to implement the "Jericho Luxury" design system. The core improvement is the logical and visual separation of "Lost" and "Found" entries into two distinct views, managed by a premium segmented control. This ensures a focused user experience, using organic 32px curvatures, high-fidelity pet imagery, and glassmorphic filtering.

## 2. Actors & Personas
- **Distressed Owner**: Searching for their lost pet. They need high-clarity information, urgency indicators, and easy contact options.
- **Good Samaritan (Finder)**: Found a pet and wants to find the owner. They need a simple way to report a pet and browse "Lost" listings.

## 3. User Scenarios
- **Scenario 1: Reporting a Found Pet**: A user finds a cat. They open the app, switch to the "Found" tab, and click the "+" FAB to create a listing with a photo and location.
- **Scenario 2: Searching for a Lost Dog**: An owner switches to the "Lost" tab to see if anyone has seen their Golden Retriever. They use the expanding filter to narrow down by area and breed.
- **Scenario 3: Contacting a Finder**: A user sees a "Found" listing that matches their dog. They tap the card to see the full details and use the "Contact Finder" action.

## 4. Functional Requirements
- **FR-01: Dual-View Navigator**: Implement a top-level segmented control to toggle between "Lost" (אבדות) and "Found" (מציאות).
- **FR-02: Jericho Top Bar**: Minimalist header with a serif italic title ("Lost & Found") and profile avatar.
- **FR-03: Glass Search & Filter**: A rounded-full glass bar with integrated search and a "tune" icon for advanced filtering.
- **FR-04: Specialized Jericho Cards**:
    - 32px organic radius.
    - Status-specific glass pills (Red for "LOST", Bronze for "FOUND").
    - Display: Pet name (or "Unknown"), Breed/Description, Gender/Age, Location icon + text.
- **FR-05: Immersive Feed Grid**: A 2-column grid (staggered or fixed) optimized for high-resolution pet photography.
- **FR-06: Quick-Action FAB**: A floating action button with Jericho styling for creating new reports.

## 5. Non-Functional Requirements
- **NFR-01: Aesthetic Integrity**: Use the Desert Bronze (`#C19A6B`) and Warm Alabaster (`#F9F9F7`) palette. "Lost" status should use a refined red tint (`AppColors.error`).
- **NFR-02: Performance**: Staggered list animations must maintain 60fps.
- **NFR-03: Accessibility**: High-contrast labels for "LOST/FOUND" indicators to ensure readability over varied photo backgrounds.

## 6. Success Criteria
- [ ] Users can switch between "Lost" and "Found" views without page reloads.
- [ ] All pet cards use the `radius-organic (32px)` token.
- [ ] The search bar correctly filters results in real-time.
- [ ] Visual hierarchy clearly distinguishes between "Lost" and "Found" listings via color coding and labels.

## 7. Key Entities
- **LostFoundPost**: ID, Type (Lost/Found), PetName, PetType, Breed, Age, Gender, Description, Location, PhotoUrl, Timestamp, Reward (optional).

## 8. Assumptions & Constraints
- Integration with existing `LostFoundRepository` and Firebase Storage for images.
- RTL (Arabic/Hebrew) support is mandatory.
- The UI must adapt to the new Jericho Bottom Navigation Bar.

## 9. Resolved Clarifications
- **Contact Method**: Internal Chat Only (Privacy-first).
- **Interactive Map View**: Grid + Map Toggle (B). Uses a premium themed map for neighborhood visualization.
- **Post Lifecycle**: Auto-archive after 30 days (B). Keeps the feed fresh and relevant.
