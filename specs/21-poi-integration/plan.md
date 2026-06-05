# Implementation Plan: POI Integration & Display

**Skills Applied**: `senior-architect` (for scalable Riverpod state management), `flutter-expert` (for optimized widget rendering), `clean-code` (for separation of concerns), `ui-ux-designer` (for bridging the UX requirements to technical constraints).

## 1. Technical Context
The feature integrates the existing `AdminRepository` (which handles POI creation) with the user-facing screens (`UserHomeScreen` and `ExploreScreen`). 
- **State Management**: We will use Riverpod `StreamProvider` to fetch real-time updates of POIs from Firestore.
- **Routing**: `go_router` will handle navigation from the POI card to the `POIDetailScreen`.
- **UI Architecture**: We must adhere to "Organic Modernism". Cards will use `GlassCard` or `Container` with `AppColors.surfaceCard`, soft shadows, and `AppRadius.organic`.

## 2. Component Architecture

### Data Layer
- Ensure `explore_repository.dart` (or similar) has a robust `watchAllPOIs()` stream to feed the user interface without giving them admin write privileges.

### Presentation Layer
1. **`UserHomeScreen`**: Add a horizontally scrolling `ListView.builder` limited to 10 items. Add a "More" button that pushes `/explore` with an active focus.
2. **`ExploreScreen`**: Ensure it consumes the POI stream and implements a category filter chip row (Vets, Parks, Stores).
3. **`POICard`**: A reusable widget. Takes a `POI` object. Uses `CachedNetworkImage` for the hero image, displays title, type, rating, and distance (static text for now).
4. **`POIDetailScreen`**: A new screen. 
   - Uses a `CustomScrollView` with a `SliverAppBar` for the hero image.
   - Body contains detailed text, emergency badges.
   - A static map placeholder (an image asset or a styled container) with a primary `AppButton` saying "Get Directions" (which will trigger `url_launcher` to open native maps using lat/lng).

## 3. Execution Phases (speckit.tasks alignment)

- **Phase 1: Foundation**: Verify POI StreamProviders are accessible to the user scope.
- **Phase 2: Reusable UI**: Build `POICard` and the static map placeholder widget.
- **Phase 3: Integration**: Embed the horizontal list in `UserHomeScreen` and the vertical list in `ExploreScreen`.
- **Phase 4: Details Screen**: Build the `POIDetailScreen` and wire up the routing (`/poi/:id`).

## 4. Risks & Mitigations
- **Image Loading Janks**: Mitigated by using `CachedNetworkImage` with a soft fading placeholder.
- **RenderFlex Overflows**: Mitigated by wrapping text in `Expanded` or `Flexible` within rows on the POICard.
