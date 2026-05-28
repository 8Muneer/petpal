# Tasks: Booking Transaction Logic

## Phase 1: Setup & Data Model
- [x] T001 Define `SittingRequest` entity in `lib/features/sitting/domain/entities/sitting_request.dart`
- [x] T002 Implement `createBooking` method in `lib/features/profile/presentation/providers/bookings_controller.dart`

## Phase 2: UI Implementation - Sitter Detail Screen
- [x] T003 [P] [US1] Add state management for `selectedDateRange` and `selectedPets` in `SitterDetailScreen`
- [x] T004 [P] [US1] Implement `_showDateSelection` using `showDateRangePicker`
- [x] T005 [P] [US1] Update `_FloatingBookingBar` to show price calculation and date status
- [x] T006 [P] [US1] Implement `_showPetSelectionDialog` fetching pets from `petsProvider`
- [x] T007 [US1] Connect "Book Now" button to the submission logic

## Phase 3: Feedback & Navigation
- [x] T008 [US1] Add loading indicator during transaction processing
- [x] T009 [US1] Implement success/error feedback (Snackbars/Modals)
- [x] T010 [US1] Add navigation to the "My Bookings" screen upon successful creation

## Phase 4: Polish & Refinement
- [x] T011 [P] Enhance dialog transitions and UI feedback using `Organic Modernism` styles
- [x] T012 [P] Handle edge cases: unselected dates, no registered pets, Firestore offline

## Dependencies
- [US1] depends on Phase 1 completion.
