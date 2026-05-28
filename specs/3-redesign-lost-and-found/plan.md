# Implementation Plan: Lost & Found Redesign

**Feature**: redesign-lost-and-found
**Design Aesthetic**: Jericho Luxury (Organic Modernism)

## 1. Technical Context
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Existing Logic**: `LostFoundFeedScreen` and `LostFoundRepository`.
- **Target Files**:
    - `lib/features/feed/presentation/screens/lost_found_feed_screen.dart` (Full overhaul)
    - `lib/core/widgets/jericho_lost_found_card.dart` (NEW)
    - `lib/core/widgets/lost_found_filter_bar.dart` (NEW)

## 2. Architecture & Design
### [NEW] Jericho UI Components
1. **`JerichoLostFoundCard`**:
    - Based on `JerichoServiceCard` but with status-specific indicators.
    - Uses `GlassPill` for "LOST" (Red/White) and "FOUND" (Bronze/White) labels.
    - Displays pet details and location in a high-contrast layout.
2. **`LostFoundToggleBar`**:
    - A luxury segmented control using `AnimatedContainer` for the selection slider.
    - Labels: "אבדות" (Lost) and "מציאות" (Found).
3. **`LostFoundFilterBar`**:
    - Expanding search bar with a backdrop blur (`BackdropFilter`).
    - Integrated filter chips for pet type and date.

### State Separation
- Update `LostFoundController` to maintain two separate streams or a single filtered stream with a `currentType` state.
- Implement `MapController` for the optional map view.

## 3. Implementation Phases
### Phase 1: Foundation & Data
- Refactor `LostFoundPost` model (if needed) to include all fields from the spec.
- Create the unified `LostFoundController`.

### Phase 2: Component Library
- Implement `JerichoLostFoundCard`.
- Implement `LostFoundToggleBar`.
- Implement `LostFoundFilterBar`.

### Phase 3: Screen Assembly
- Overhaul `LostFoundFeedScreen`.
- Implement the `PageView` or `IndexedStack` for tab switching.
- Add staggered entrance animations (`animate` skill).

### Phase 4: Map Integration
- Implement the "Map View" toggle.
- Create custom map markers with Jericho styling.

## 4. Verification Plan
### Automated Tests
- Widget tests for `JerichoLostFoundCard` status colors.
- Unit tests for `LostFoundController` tab filtering logic.

### Manual Verification
- Verify tab switching smoothness on a device.
- Check "Lost" (Red) vs "Found" (Bronze) visual distinction.
- Test search/filter performance with simulated high data volume.
