# Tasks - Sitter Calendar Redesign

## Phase 1: Infrastructure & State
- [x] T001 Implement `SitterAvailabilityNotifier` and state provider in `lib/features/profile/presentation/providers/sitter_availability_state.dart`
- [x] T002 Implement data persistence logic (Firestore) for `dateOverrides` and `serviceAvailability`.
- [x] T003 [P] Add helper methods to calculate availability by combining weekly patterns and overrides.

## Phase 2: Bento Components
- [x] T004 [P] Create `ServiceTogglesCard` widget in `lib/features/profile/presentation/widgets/service_toggles_card.dart`
- [x] T005 [P] Create `BentoCalendar` widget in `lib/features/profile/presentation/widgets/bento_calendar.dart`
- [x] T006 [P] Implement the interactive grid logic for tapping dates in `BentoCalendar`.

## Phase 3: Screen Assembly & Refactor
- [x] T007 Refactor `AvailabilityScreen` to use the new Bento Grid layout in `lib/features/profile/presentation/screens/availability_screen.dart`
- [x] T008 Integrate the `SitterAvailabilityProvider` with the screen.
- [x] T009 [P] Update the "Save" logic to persist all new fields to Firestore.

## Phase 4: Polish & Feedback
- [x] T010 [P] Add micro-animations (scale/bounce) to calendar date selection.
- [x] T011 Polish the "Service Toggles" with premium glassmorphism and Desert Bronze status colors.
- [x] T012 Conduct final visual QA to match the React prototype.
