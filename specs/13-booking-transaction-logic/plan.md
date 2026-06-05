# Implementation Plan: Booking Transaction Logic

## Goal
Implement a robust, Firestore-backed booking transaction flow in the `SitterDetailScreen`. This will allow Pet Owners to select dates and pets, calculate the total cost, and create a formal request in Firestore.

## User Review Required
> [!IMPORTANT]
> The total price calculation will be: `sitter_price_per_day * number_of_days`. We should confirm if "per day" or "per night" is the correct terminology for the UI.

## Technical Context
- **Firestore**: Collections: `sitting_requests`.
- **State Management**: Riverpod (`bookingsControllerProvider`).
- **UI**: Flutter standard date pickers and custom modal sheets for pet selection.

## Proposed Changes

### [Sitting Feature]

#### [MODIFY] [sitter_detail_screen.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/features/sitting/presentation/screens/sitter_detail_screen.dart)
- Add local state or use a local provider to track `selectedDateRange` and `selectedPets`.
- Update `_FloatingBookingBar` to:
    - Display a "Select Dates" button if no dates are selected.
    - Display the calculated total price if dates are selected.
    - Change "Book Now" to trigger the pet selection and then the final submission.
- Implement `_showDateSelection()` and `_showPetSelectionDialog()`.

#### [MODIFY] [bookings_controller.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/features/profile/presentation/providers/bookings_controller.dart)
- Add a `createBooking` method that takes `SittingRequest` data and writes to Firestore.
- Add error handling and loading states.

#### [NEW] [sitting_request.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college%20projects/petpal/project/petpal/lib/features/sitting/domain/entities/sitting_request.dart)
- Define the data model for a booking request.

## Verification Plan

### Automated Tests
- N/A (Unit tests for price calculation logic if requested).

### Manual Verification
1.  Navigate to a sitter's profile.
2.  Click "Select Dates" and choose a range.
3.  Verify the price update in the bottom bar.
4.  Click "Book Now" and select a pet from the list.
5.  Confirm the booking and verify redirection to "My Bookings".
6.  Check Firestore to ensure the document exists with correct fields.
