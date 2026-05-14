# Tasks: Admin Management System

**Feature**: admin-system
**Branch**: `20-admin-system`

## Phase 1: Setup & Security

- [x] T001 Define Admin role and permissions in `lib/features/auth/domain/enums/user_role.dart`
- [x] T002 Implement Admin-gated navigation routes in `lib/core/router/app_router.dart`
- [x] T003 [P] Update Firestore Security Rules to protect admin collections in `firestore.rules`
- [x] T004 Create a specialized `AdminRepository` for administrative data fetching in `lib/features/admin/data/repositories/admin_repository.dart`

## Phase 2: Foundational Admin UI

- [x] T005 Create the base `AdminHubScreen` with a responsive bento-style layout in `lib/features/admin/presentation/screens/admin_hub_screen.dart`
- [x] T006 [P] Implement `AdminNavigationRail` for switching between management views in `lib/features/admin/presentation/widgets/admin_navigation_rail.dart`
- [x] T007 Build common Admin UI components (Metric cards, status badges) in `lib/features/admin/presentation/widgets/admin_ui_components.dart`

## Phase 3: User Story 1 - Sitter Verification (P1)

**Goal**: Admins can review and verify sitter profiles to build trust.

- [x] T008 [US1] Create `VerificationRequest` model and repository in `lib/features/admin/domain/entities/verification_request.dart`
- [x] T009 [US1] Build the `SitterVerificationList` view in `lib/features/admin/presentation/screens/sitter_verification_screen.dart`
- [x] T010 [US1] Implement the Verification Detail view with Approve/Reject actions in `lib/features/admin/presentation/widgets/verification_detail_dialog.dart`
- [x] T011 [US1] Update the sitter profile UI to display the "Verified" badge if status is approved in `lib/features/sitting/presentation/widgets/sitter_card.dart`

## Phase 4: User Story 2 - Managing Local Places (P1)

**Goal**: Admins can manage the Points of Interest shown to all users.

- [x] T012 [US2] Create the `POIManagementScreen` with a list of all existing POIs in `lib/features/admin/presentation/screens/poi_management_screen.dart`
- [x] T013 [US2] Build the `POIEditorForm` with fields for name, type, and details in `lib/features/admin/presentation/widgets/poi_editor_form.dart`
- [x] T014 [US2] [P] Integrate `GoogleMapPicker` for choosing location coordinates in `lib/features/admin/presentation/widgets/map_location_picker.dart`
- [x] T015 [US2] Implement image upload and management for POIs in `lib/features/admin/presentation/services/poi_storage_service.dart`
- [x] T016 [US2] Transition `POIRepositoryImpl` to fetch from live Firestore instead of mock data in `lib/features/explore/data/repositories/poi_repository_impl.dart`

## Phase 5: User Story 3 - Community Moderation (P2)

**Goal**: Admins can moderate user content to maintain platform safety.

- [x] T017 [US3] Create the `ModerationQueue` screen to review reported content in `lib/features/admin/presentation/screens/moderation_queue_screen.dart`
- [x] T018 [US3] Implement "Delete Post" and "Dismiss Report" actions in `lib/features/admin/data/repositories/moderation_repository.dart`
- [x] T019 [US3] [P] Build a "Report Content" dialog for regular users in `lib/core/widgets/report_content_dialog.dart`

## Phase 6: User Story 4 - User Oversight (P2)

**Goal**: Admins can search and manage all user accounts.

- [x] T020 [US4] Build the `UserDirectoryScreen` with search and filter capabilities in `lib/features/admin/presentation/screens/user_directory_screen.dart`
- [x] T021 [US4] Implement "Adjust Karma" and "Update Status" actions for user profiles in `lib/features/admin/presentation/widgets/user_admin_actions.dart`

## Phase 7: Polish & Broadcast Alerts

- [x] T022 [P] Implement the "Global Broadcast Alert" creation tool in `lib/features/admin/presentation/widgets/global_alert_creator.dart`
- [x] T023 Apply `normalize` and `frontend-design` skills to ensure high-fidelity UI across all admin screens
- [x] T024 Perform a final security audit of all admin routes and data access points
