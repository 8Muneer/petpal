# Tasks: Explore Filtering System

## Phase 1: State Management (Setup)
- [x] T001 Extend `MarketplaceFilters` class with price, rating, petTypes, and serviceTypes in lib/features/sitting/presentation/providers/marketplace_provider.dart
- [x] T002 Update `MarketplaceFiltersNotifier` with update/toggle/clear methods in lib/features/sitting/presentation/providers/marketplace_provider.dart

## Phase 2: Filtering Logic (Foundational)
- [x] T003 [P] Update `filteredSittingServicesProvider` to handle price, rating, petTypes, and serviceTypes in lib/features/sitting/presentation/providers/marketplace_provider.dart
- [x] T004 [P] Update `filteredPublicJobsProvider` to handle new filter dimensions in lib/features/sitting/presentation/providers/marketplace_provider.dart

## Phase 3: Filter UI (US1 & US2)
- [x] T005 [P] [US1] Create `FilterBottomSheet` scaffold with 32px radius and RTL title in lib/features/explore/presentation/widgets/filter_bottom_sheet.dart
- [x] T006 [US1] Implement dual-thumb Price Range slider with golden accents in lib/features/explore/presentation/widgets/filter_bottom_sheet.dart
- [x] T007 [US1] Implement Multi-select chips for Rating and Pet Types in lib/features/explore/presentation/widgets/filter_bottom_sheet.dart
- [x] T008 [US1] Implement "Show [X] Results" Apply button and "Clear All" logic in lib/features/explore/presentation/widgets/filter_bottom_sheet.dart

## Phase 4: Integration & Polish
- [x] T009 [P] Wire Filter icon in `ExploreScreen` to show `FilterBottomSheet` in lib/features/explore/presentation/screens/explore_screen.dart
- [x] T010 [P] Implement golden dot "Active Filter" indicator in lib/features/explore/presentation/screens/explore_screen.dart
- [x] T011 Add haptic feedback and staggered animations to filter application in lib/features/explore/presentation/screens/explore_screen.dart

## Dependency Graph
- T001 -> T002 -> T003, T004
- T002 -> T005 -> T006, T007 -> T008
- T008 -> T009 -> T010 -> T011

## Implementation Strategy
1. **Model First**: Extend the state and provider logic to support the new dimensions.
2. **UI Second**: Build the bottom sheet piece by piece (Price -> Rating -> Chips).
3. **Integration Third**: Connect the UI to the provider and handle the "Apply" logic.
4. **Polish Final**: Add the subtle indicators and animations for the "Boutique" feel.
