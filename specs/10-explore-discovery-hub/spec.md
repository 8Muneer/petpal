# Specification: Explore Discovery Hub

## Overview
**Feature Name**: Explore Discovery Hub
**Description**: A unified "Explore" bottom navigation tab serving both Pet Owners and Service Providers (Sitters) with role-specific views and a premium, RTL-first visual design.

## User Scenarios
### 1. Pet Owner Experience
- **Discovery**: The owner navigates to the Explore tab to find sitters. They see a pill-shaped search bar and a list of sitter "Property-style" cards.
- **Tab Switching**: The owner can switch between two views:
  1. **Browse Sitters**: A list of available service providers with filtering.
  2. **My Requests**: A sub-tab where the owner can post a specific request (dates, details) which will then be visible to sitters.
- **Filtering**: The owner uses the "Filter" icon in the top app bar to narrow down sitters.

### 2. Service Provider (Sitter) Experience
- **Job Discovery**: The sitter navigates to the Explore tab and *only* sees a list of public requests posted by pet owners (people who asked for sitters).
- **Interaction**: The sitter can filter these jobs and view details to apply.

## Functional Requirements
### 1. Top App Bar / Header
- **Title**: "استكشف" (Explore) - Large, bold, RTL-aligned.
- **Actions (Left)**: Two square icon buttons (Filter and Grid/Layout) with 24px radius and light gray background.

### 2. Search & Filtering
- **Search Bar**: Pill-shaped, white background, subtle shadow. Search icon on the right, RTL hint text "חפש...".
- **Results Header**:
  - Right: House icon + Count (e.g., "5 זמינים").
  - Left: Sort dropdown (e.g., "מיון: מומלץ").

### 3. Sitter/Job Card Design (Villa-Style)
- **Container**: White card, 24px radius, soft drop shadow.
- **Image Header**: Top half fills width, rounded top corners.
- **Overlays**:
  - Top-Left: Circular white favorite (heart) button.
  - Top-Right: White pill badge for rating: `(count) rating ★`.
- **Content**:
  - **Title**: Bold dark text (Sitter Name or Job Title).
  - **Subtitle**: Amenities/Services list separated by bullets (e.g., "טיול כלבים • פנסיון • WiFi").
  - **Price Row**:
    - Right: Bold price and currency in golden/brown accent.
    - Left: "פרטים נוספים" (View Details) in light gray with left chevron icon (<).

### 4. Floating Bottom Navigation Bar
- **Container**: Pill-shaped, white, drop shadow, floating above the bottom edge.
- **Items**: 5 items.
- **Selected State**: Icon wrapped in a soft golden/beige circular background.

## Non-Functional / Quality Attributes
- **Layout**: RTL (Right-to-Left) mandatory.
- **Aesthetic**: Modern, clean, off-white/gray background.
- **Performance**: Staggered entrance animations (slide-up and fade-in) for card list.

## Success Criteria
- Pet Owners can successfully toggle between browsing sitters and their own requests.
- Sitters see a filtered view of only public job requests.
- UI elements (Floating Nav, Pill Search) match the provided pixel-perfect description.

## Assumptions
- The "My Requests" tab for Owners will utilize an existing request-creation flow or a simplified version within the tab.

### 5. Clarifications (Session 2026-05-06)
- Q: In the Pet Owner's "My Requests" sub-tab, what should be the primary content? → A: Option B (List of existing requests + "New Request" button).
- Q: When a Sitter is browsing jobs, what specific "amenities" or details should be shown in the subtitle? → A: Option A (Pet details: Breed, Age, Energy level).
- Q: Should this new floating navigation bar design replace the app's current bottom navigation globally, or only appear on the Explore screen? → A: Option A (Replace globally for the whole app).
