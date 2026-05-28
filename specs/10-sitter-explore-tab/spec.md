# Specification: Sitter Explore Tab

## Overview
**Feature Name**: Premium Immersive Explore Screen (Sitter)
**Description**: A new "Explore" bottom navigation tab for Service Providers (Sitters). This screen acts as a dual-purpose discovery hub featuring a high-end "Organic Modernism" aesthetic. It allows sitters to browse general public job requests posted by pet owners, as well as view direct booking requests explicitly sent to them.

## Business Value
- Enhances the Service Provider experience by consolidating job discovery and direct booking management into a single, immersive interface.
- Elevates the app's perceived value through a premium, glassmorphic design language.
- Increases engagement by making job browsing visually stimulating and intuitive.

## User Scenarios
1. **Discovering Public Jobs**: A sitter navigates to the Explore tab to find new opportunities. They browse a staggered, animated list of public requests posted by pet owners, using animated filter chips to narrow down the options (e.g., by location or pet type).
2. **Managing Direct Orders**: A sitter receives a push notification about a new booking request. They open the Explore tab and switch to the "My Orders" sub-tab to view requests directed specifically at them.
3. **Filtering**: A sitter wants to find high-paying jobs in a specific area. They tap the filter icon, which opens a glassmorphic bottom sheet containing advanced filtering options.

## Functional Requirements
- **Bottom Navigation**: Add a new "Explore" tab to the Service Provider's main navigation bar.
- **Header Structure**: Implement an immersive parallax header (`CustomScrollView` with `SliverAppBar`) that expands to ~400px, featuring a smooth bottom curve for organic transitions.
- **Greeting & Context**: Display the user's name and dynamic subtext over the header background.
- **Sub-Navigation**: Implement a two-tab system below the header:
  - Tab 1: "Public Requests" (Jobs broadcasted by pet owners).
  - Tab 2: "Direct Orders" (Requests targeted at the current sitter).
- **Search & Filters**:
  - A floating, glassmorphic search bar with rounded corners (radius ~26).
  - A horizontal list of scrollable, animated filter chips.
  - A `ModalBottomSheet` (maintaining the glassmorphic theme) for advanced filters/location selection.
- **Content Display**:
  - Boutique Content Cards for job/order items with high border radius (~32px) and soft shadows.
  - Glass Badges overlaying card images or headers for key details (price, pet type, rating).
  - Staggered "slide-up and fade-in" list entrance animation using `TweenAnimationBuilder`.

## Non-Functional / Quality Attributes
- **Design System**: Strict adherence to "Organic Modernism" (Glassmorphism, backdrop blur sigma 5-10, premium typography like Inter/Outfit, 'Surface' off-white background, 'Primary' accent).
- **Accessibility & Localization**: Full support for RTL (Right-to-Left) layouts. Semantic widgets must be used.
- **Performance**: Ensure animations run at 60fps; use efficient list building (`SliverList`).

## Success Criteria
- The Explore tab is fully accessible via the bottom navigation bar without layout errors.
- Switching between "Public Requests" and "Direct Orders" occurs seamlessly without dropping frames.
- All glassmorphic elements render correctly on both high-end and mid-range devices.

## Assumptions
- The backend data sources for "Public Jobs" and "Direct Orders" already exist or can be mocked.
- The existing bottom navigation allows for the addition of a new tab without overflowing.

[NEEDS CLARIFICATION: Is the parallax header background a static image, or should it pull dynamic content based on the sitter's location/specialty?]
[NEEDS CLARIFICATION: Should the "Direct Orders" tab include actionable buttons (Accept/Decline) directly on the cards, or just link to a detail screen?]
[NEEDS CLARIFICATION: Where exactly should the "Explore" tab be positioned in the bottom navigation order (e.g., next to Home, or replacing an existing tab)?]
