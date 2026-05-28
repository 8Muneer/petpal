# Implementation Plan: Explore Discovery Hub

## Overview
Implement a premium, "Organic Modernism" Explore tab with dual-role views (Owner vs. Sitter) and exact pixel-perfect UI specs (Pill search, Floating nav, Villa-style cards).

## Technical Context
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Design System**: Organic Modernism (AppTheme)
- **RTL Support**: Mandatory for all components.

## Proposed Changes

### 1. New Screen Architecture
- **[NEW] [explore_screen.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/features/explore/presentation/screens/explore_screen.dart)**
  - Primary scaffold for the Explore tab.
  - Detects user role via `authProvider`.
  - **Owner View**: `CustomScrollView` with sub-tabs "Browse Sitters" and "My Requests".
  - **Sitter View**: `CustomScrollView` showing job requests.

### 2. Premium Components
- **[NEW] [floating_nav_bar.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/core/widgets/floating_nav_bar.dart)**
  - Custom pill-shaped navigation bar.
  - Absolute positioning at the bottom of the screen.
  - Selected state with a soft golden circular background.
- **[NEW] [boutique_property_card.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/core/widgets/boutique_property_card.dart)**
  - Reusable card component implementing the specific Villa-style design (Image top, Rating overlay, Amenities subtitle, Price/Action row).

### 3. Integration
- **[MODIFY] [app_router.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/core/navigation/app_router.dart)**
  - Add the `/explore` route.
- **[MODIFY] [service_provider_home_screen.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/features/home/presentation/screens/service_provider_home_screen.dart)**
  - Replace the standard `BottomNavigationBar` with the new `FloatingNavBar`.
  - Update the tab switching logic to include the Explore tab.

## Verification Plan

### Automated Tests
- Unit tests for `FloatingNavBar` selection logic.
- Widget tests for `BoutiquePropertyCard` RTL alignment and overlays.

### Manual Verification
- Verify the Explore tab looks correct for both a Pet Owner account and a Sitter account.
- Confirm the floating navigation bar stays above the bottom edge and has the correct shadows/blur.
- Test the "My Requests" list + "New Request" button functionality.
