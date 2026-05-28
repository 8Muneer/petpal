# Feature Specification: Home Screen — Top Rated Sections

**Status**: Clarified
**Branch**: `19-home-top-rated-sections`
**Feature Name**: home-top-rated-sections

## 1. Executive Summary

The Home screen currently displays hardcoded promotional cards ("Top Rated This Week", "Featured Sitters", "Recommended for You") and a community feed. This feature replaces those static sections with **dynamic, category-based "Top 10" listings** that mirror the Explore screen's 5-tab structure (Sitters, Parks, Vets, Stores, My Requests). Each section displays the 10 highest-rated items in that category, sorted by rating, with a "More" link that navigates the user directly to the corresponding Explore tab. For the three POI categories (Parks, Vets, Stores), placeholder/demo data will be used until admin management tools are built.

## 2. Actors & Personas

- **Pet Owner (Browser)**: The primary user scrolling the Home screen. They want a quick overview of the best-rated services and places near them without needing to navigate deep into the app.
- **Admin (Future)**: Will manage the POI data for Parks, Vets, and Stores. In this phase, dummy data serves as a placeholder for admin-curated content.

## 3. User Scenarios

- **Scenario 1: Quick Discovery**: A pet owner opens the app and immediately sees their active requests at the top, followed by the top-rated sitters, parks, vets, and stores. They spot a 5-star vet and tap to browse more in the Explore tab.
- **Scenario 2: Category Deep Dive**: A pet owner sees a "עוד" (More) link next to the "גינות כלבים" (Dog Parks) section. Tapping it navigates them directly to the Parks tab in the Explore screen to browse the full list.
- **Scenario 3: Sitter Review**: An owner notices a highly-rated sitter in the "שומרים" (Sitters) section on the Home screen. They tap the card to view the sitter's full profile and reviews.
- **Scenario 4: Active Requests Priority**: A pet owner opens the app and immediately sees their active sitting requests at the very top of the content area, giving them quick access to manage bookings.

## 4. Functional Requirements

### A. Section Layout & Structure

- **FR-01: Category Sections**: Replace the current static "Top Rated" / "Featured Sitters" / "Recommended" / "Community Feed" sections with 5 category-based sections ordered as:
  1. הבקשות שלי (My Requests) — positioned first for priority visibility
  2. שומרים (Sitters)
  3. גינות כלבים (Dog Parks)
  4. וטרינרים (Vets)
  5. חנויות (Stores)

- **FR-02: Section Header with "More" Link**: Each section must display a header row containing:
  - The category name (Hebrew) on the right (RTL layout)
  - A "עוד" (More) text button on the left that navigates to the corresponding Explore screen tab

- **FR-03: Top 10 Listing**: Each category section displays up to 10 items, sorted by rating in descending order. If fewer than 10 items exist, display all available items.

- **FR-04: Empty State**: If a category has no items (e.g., no active requests), show a contextual empty state message instead of an empty list.

### B. Data Sources

- **FR-05: Sitters Data**: Populated from the existing sitter marketplace data (Firestore `sitting_services` collection), sorted by the `rating` field.

- **FR-06: POI Dummy Data (Parks, Vets, Stores)**: For the three POI categories, use hardcoded/seeded demo data that represents realistic Israeli locations. This data will later be replaced by admin-managed content.

- **FR-07: My Requests Data**: Populated from the existing sitting requests data (Firestore `sitting_requests` collection), filtered by the current user's ID.

### C. Navigation

- **FR-08: "More" Navigation**: Tapping the "More" link on any section header must:
  1. Switch the root navigation to the Explore tab (tab index 1)
  2. Set the Explore sub-tab to the corresponding category (My Requests=4, Sitters=0, Parks=1, Vets=2, Stores=3)

- **FR-09: POI Card Tap**: Tapping a POI card (Park, Vet, Store) navigates to the corresponding Explore tab (same behavior as "More"), since detail screens are not yet available for POI items.

- **FR-10: Sitter Card Tap**: Tapping a sitter card navigates to the sitter's detail/profile screen.

- **FR-11: Request Card Tap**: Tapping a request card navigates to the request detail screen.

### D. Visual Presentation

- **FR-12: Card Style**: Items must be displayed using the existing card components (e.g., `BoutiquePropertyCard` for sitters/requests, `DiscoveryCard` for POIs) for visual consistency with the Explore screen.

- **FR-13: Horizontal Scroll**: Each section's items are displayed in a horizontally scrollable list to keep the Home screen compact and scannable.

- **FR-14: Animation**: Each section should fade in with a subtle entrance animation as the user scrolls, consistent with the existing Home screen aesthetic.

- **FR-15: Community Feed Removal**: The community feed section is entirely removed from the Home screen. The Community tab serves that purpose.

## 5. Out of Scope

- Admin panel for managing POI data (deferred to a future feature)
- Live geolocation-based distance calculations for POIs
- Push notifications for new top-rated items
- Real-time rating updates on the Home screen
- POI detail screens (tapping a POI navigates to Explore tab instead)

## 6. Success Criteria

- [ ] Home screen displays 5 distinct category sections with appropriate headings
- [ ] My Requests section appears first, above all discovery sections
- [ ] Each section shows up to 10 items sorted by rating (highest first) in a horizontal scroll
- [ ] Each section header includes a "More" link that navigates to the correct Explore tab
- [ ] Sitters section is populated from live Firestore data
- [ ] Parks, Vets, and Stores sections display realistic placeholder data
- [ ] My Requests section shows the current user's active requests
- [ ] Empty states are shown for categories with no data
- [ ] Tapping a POI card navigates to the corresponding Explore tab
- [ ] The overall Home screen scroll experience remains smooth (no jank)

## 7. Key Entities

- **SittingService** (existing): `id`, `providerName`, `rating`, `priceText`, `petTypes`, `area`
- **POI** (existing): `id`, `name`, `type`, `rating`, `reviewCount`, `tags`, `isEmergency`, `imageUrl`
- **SittingRequest** (existing): `id`, `petName`, `petType`, `area`, `status`, `startDate`

## 8. Assumptions & Constraints

- The existing `poiProvider` and `filteredSittingServicesProvider` are available and functional.
- The existing card widgets (`BoutiquePropertyCard`, `DiscoveryCard`) will be reused without modification.
- Hebrew RTL layout is maintained throughout.
- The dummy POI data will be embedded as a static list (not requiring a network call) until admin tooling is built.
- The community feed section is removed from the Home screen entirely.

## 9. Dependencies

- Feature 18 (Discovery Hub) — provides the `DiscoveryCard`, `poiProvider`, `exploreTabIndexProvider`, and POI model.
- Feature 9 (Sitter Marketplace) — provides sitter data and card components.

## 10. Clarifications

### Session 2026-05-12
- Q: Should the community feed section remain on the Home screen? → A: Remove entirely; the Community tab already serves that purpose.
- Q: How should items be laid out within each section? → A: Horizontal scrollable cards (compact, preview-style).
- Q: Where should the My Requests section appear? → A: At the very top, before the discovery sections (highest priority).
- Q: What happens when a user taps a POI card (dummy data)? → A: Navigate to the corresponding Explore tab (same as "More").
