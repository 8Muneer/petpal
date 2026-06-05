# Implementation Plan: Explore Filtering System

## Overview
Implement a high-end, boutique filtering system for the Explore Discovery Hub using a premium Modal Bottom Sheet. The system will use Riverpod for state management and feature intentional "Apply" logic with subtle UI indicators.

## Technical Context
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (`marketplaceFiltersProvider`)
- **Design System**: Organic Modernism (AppTheme, Glassmorphism)
- **Localization**: RTL (Hebrew labels)

## Constitution Check
- **Performance**: Use staggered animations for list updates.
- **Accessibility**: Ensure high contrast for sliders and chips.
- **RTL**: All labels and layouts must be RTL.

## Proposed Changes

### 1. State Management
#### [MODIFY] [marketplace_provider.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/features/sitting/presentation/providers/marketplace_provider.dart)
- Extend `MarketplaceFilters` class:
  - `double? minPrice`, `double? maxPrice`
  - `double? minRating`
  - `List<String> selectedPetTypes`
  - `List<String> selectedServiceTypes`
- Update `MarketplaceFiltersNotifier`:
  - `updatePriceRange(double min, double max)`
  - `updateRating(double? rating)`
  - `togglePetType(String type)`
  - `toggleServiceType(String type)`
  - `clearAll()`
- Update `filteredSittingServicesProvider` and `filteredPublicJobsProvider` logic to respect new filter dimensions.

### 2. UI Components
#### [NEW] [filter_bottom_sheet.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/features/explore/presentation/widgets/filter_bottom_sheet.dart)
- Premium Modal Bottom Sheet with 32px top corners.
- **Price Range**: Custom dual-thumb slider with gold accents.
- **Rating**: Multi-select chips for 4+ and 4.5+ stars.
- **Pet Types**: Grid of multi-select chips (Dogs, Cats, etc.).
- **Service Types**: Multi-select chips for Walking and Sitting.
- **Footer**: Large "Apply" button showing result count (e.g., "Show 12 Results").

#### [MODIFY] [explore_screen.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/features/explore/presentation/screens/explore_screen.dart)
- Wire up the Filter icon to open `FilterBottomSheet`.
- Implement the "Active Filter" golden dot indicator on the filter icon.
- Ensure the result count header updates based on the filtered providers.

### 3. Polish & Animations
- Use `flutter_staggered_animations` to re-animate the list when filters are applied.
- Add haptic feedback (`HapticFeedback.lightImpact()`) on interactive elements.

## Verification Plan

### Automated Tests
- Unit tests for `MarketplaceFiltersNotifier` ensuring state updates correctly.
- Widget tests for `FilterBottomSheet` RTL alignment.

### Manual Verification
- Verify that clicking "Apply" correctly filters the list of sitters.
- Confirm the "Active Filter" dot appears only when filters are active.
- Test "Clear All" functionality.
