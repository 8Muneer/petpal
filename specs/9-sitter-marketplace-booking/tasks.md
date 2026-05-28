# Tasks - Sitter Marketplace & Booking Flow

## Feature Overview
Connect the pet owner ordering flow and the sitter posting flow. Includes a premium marketplace for discovery and a high-fidelity sitter profile screen with parallax effects.

## Phase 1: Setup & Data Models
- [x] T001 Update `SittingService` entity with `bio`, `experienceYears`, `locationArea`, `verifiedStatus`, and `reviewsCount` in `lib/features/sitting/domain/entities/sitting_service.dart`
- [x] T002 Update `SittingRequest` entity with `rules` list and `isPublicJob` flag in `lib/features/sitting/domain/entities/sitting_request.dart`
- [x] T003 Update Firestore remote data source and repository to support new fields and marketplace queries in `lib/features/sitting/data/`

## Phase 2: Foundational Logic
- [x] T004 [P] Implement `MarketplaceProvider` for filtering sitters by "Rules" (Hard Filters) in `lib/features/sitting/presentation/providers/marketplace_provider.dart`
- [x] T005 [P] Create `SitterCalendarWidget` for visualizing availability in `lib/features/sitting/presentation/widgets/sitter_calendar_widget.dart`

## Phase 3: [US1] Marketplace Discovery (Owner Side)
- [x] T006 [P] [US1] Create `SitterMarketplaceScreen` with searchable list and filter chips in `lib/features/sitting/presentation/screens/sitter_marketplace_screen.dart`
- [x] T007 [P] [US1] Add "Featured Sitters" horizontal scroller to `UserHomeScreen` in `lib/features/home/presentation/screens/user_home_screen.dart`
- [x] T008 [US1] Connect "שמירה" (Sitting) category chip and Featured cards to the Marketplace navigation

## Phase 4: [US2] Sitter Detail Experience (Owner Side)
- [x] T009 [P] [US2] Implement `SitterDetailScreen` with `SliverAppBar` for parallax hero effect in `lib/features/sitting/presentation/screens/sitter_detail_screen.dart`
- [x] T010 [P] [US2] Build "Quick Stats" and "Service Tags" sections per user design in `lib/features/sitting/presentation/screens/sitter_detail_screen.dart`
- [x] T011 [P] [US2] Integrate `SitterCalendarWidget` into the detail screen
- [x] T012 [US2] Implement sticky "Book Now" bottom bar and booking flow initiation

## Phase 5: [US3] Public Job Board & Sitter Actions
- [x] T013 [P] [US3] Add "Public Job" toggle to `CreateSittingRequestScreen` in `lib/features/sitting/presentation/screens/create_sitting_request_screen.dart`
- [x] T014 [P] [US3] Add "Browse Jobs" tab to `SitterMarketplaceScreen`
- [x] T015 [US3] Add "List Your Service" CTA to `ServiceProviderHomeScreen`
- [ ] T015b [NEW] Create `CreateSittingServiceScreen` for sitters to post their profiles

## Phase 6: Polish & Localization
- [/] T016 [P] Perform full RTL audit and Hebrew translation for all new labels
- [ ] T017 [P] Add staggered entrance animations for marketplace cards and detail sections

## Dependencies
- US1 depends on Phase 1 & 2
- US2 depends on US1
- US3 depends on Phase 1 & 2
