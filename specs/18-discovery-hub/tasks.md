# Tasks: Discovery Hub & Community Alerts

## Phase 1: Foundation & Data Model
- [x] T001: Define `POI` entity (lib/features/explore/domain/entities/poi_model.dart)
- [x] T002: Create `POIRepository` interface and Firestore implementation
- [x] T003: Update `CommunityPost` entity with `treats` and `topic` fields

## Phase 2: State Management & Seeding
- [x] T004: Implement `poiProvider` for nearby discovery
- [x] T005: Create `pictureOfTheDayProvider` logic
- [x] T006: Update `SeedService` with Israeli POI data
- [x] T007: Run `build_runner` for code generation

## Phase 3: UI Development (Discovery Hub)
- [x] T008: Create `DiscoveryCard` widget with mini-map snapshot
- [x] T009: Update `ExploreScreen` TabController and TabBar (5-tab system)

## Phase 4: Home Screen Integration
- [x] T010: Create `NearbyEssentials` widget (Bento cards)
- [x] T011: Inject `NearbyEssentials` into `UserHomeScreen` with programmatic tab switching

## Phase 5: Forums & Engagement
- [x] T012: Implement `HeroPetSection` (Picture of the Day) in Community Feed
- [x] T013: Update `NeighborhoodPulseBar` categories (Gallery, Playdates)
- [x] T014: Implement topic-based gallery filtering in community feed

## Phase 6: Safety System
- [x] T015: Finalize `NeighborhoodAlertBanner` with pulse animation
- [x] T016: Implement safety alert logic in `AlertsProvider`
- [x] T017: Integrate emergency badge in `DiscoveryCard`

## Phase 7: Polish & Verification
- [x] T018: Final design review (RTL alignment, spacing)
- [x] T019: Verification walk-through (using 7 skill integrations)
- [x] T020: **ui-ux-designer**: Micro-animations and premium Bento cards
- [x] T021: **edge-case-analyst**: Robust error states for location/empty data
