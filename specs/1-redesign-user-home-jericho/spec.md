# Feature Specification: PetPal User Home Screen Redesign (Jericho Luxury)

**Status**: Draft
**Branch**: `feature/1-redesign-user-home-jericho`
**Feature Name**: redesign-user-home-jericho

## 1. Executive Summary
Redesign the PetPal User Home Screen to implement the "Jericho Luxury" design system. This involves a complete visual overhaul using the Desert Bronze and Warm Alabaster palette, organic 32px curvatures, and advanced interactive elements like parallax scrolling and glassmorphism.

## 2. Actors & Personas
- **Pet Owner (User)**: Seeking high-quality care for their pets. They value trust, aesthetics, and ease of use. They want to feel like they are using a premium, boutique service.

## 3. User Scenarios
- **Scenario 1: Discovery**: A user opens the app and is immediately greeted by a stunning parallax hero image of a happy pet. They use the floating glass search bar to find a dog walker.
- **Scenario 2: Browsing Top Rated**: The user scrolls horizontally through a list of "Top Rated" walkers, seeing high-quality photos and clear price/rating information on premium glass-style cards.
- **Scenario 3: Community Connection**: The user scrolls down to see "Community Highlights," viewing a large photo of a pet at the beach, making them feel part of a high-end pet community.

## 4. Functional Requirements
- **FR-01: Parallax Hero Section**: Implement a hero section with a high-resolution pet image that responds to scroll with a parallax effect.
- **FR-02: Floating Glass Search Bar**: Create a search bar with a `BackdropFilter` (blur: 10) and 90% alpha white background, containing a search input and a "Tune" icon.
- **FR-03: Category Navigation**: Horizontal scrollable row of minimalist chips for service categories (Walks, Sitting, Training, Vet).
- **FR-04: Premium Service Cards (Top Rated)**: 280px wide cards with 32px organic corners, featuring a glass rating pill, favorite button, and Desert Bronze price labels.
- **FR-05: Recently Viewed Tiles**: Compact 140px square tiles with 24px corners for quick access to previously viewed services.
- **FR-06: Community Highlight Post**: Large 32px radius cards featuring user avatars, large media areas, and interaction bars (likes/comments).

## 5. Non-Functional Requirements
- **NFR-01: Aesthetic Integrity**: Strictly adhere to the Jericho design tokens (Desert Bronze `#C19A6B`, Warm Alabaster `#F9F9F7`).
- **NFR-02: Performance**: Animations (parallax, scroll transitions) must maintain 60fps on modern mobile devices.
- **NFR-03: Responsiveness**: Layout must adapt gracefully between small and large mobile viewports.

## 6. Success Criteria
- [ ] User can browse all sections of the home page without visual lag.
- [ ] All components use the `radius-organic (32px)` token where applicable.
- [ ] The "Glass Rating Pill" correctly blurs the background image.
- [ ] Parallax effect is visually distinct during vertical scroll.

## 7. Key Entities
- **ServiceListing**: Name, Rating, Price, Location, Category, Image.
- **CommunityPost**: Author, Timestamp, Media, Content, LikesCount, CommentsCount.

## 8. Assumptions & Constraints
- High-resolution pet images will be available via CDN.
- The app uses Flutter (based on project files).
- Right-to-Left (RTL) support is required (Arabic).

---
## 9. [NEEDS CLARIFICATION]
- **Q1: Parallax Intensity**: Balanced (0.3 ratio) for a professional depth effect.
- **Q2: Search Behavior**: Sticky Header - The search bar transitions to a compact sticky top bar when scrolling past the hero.
- **Q3: Empty States**: Curated Suggestions - Replace "Recently Viewed" with "Recommended for You" using high-quality curated listings when no history exists.
