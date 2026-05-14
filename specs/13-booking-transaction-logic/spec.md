# Booking Transaction Logic

## Goal
Implement the end-to-end booking transaction between a pet owner and a sitter. This ensures that when an owner clicks "Book Now", a formal request is created in Firestore with all necessary details (dates, pet info, pricing), which can then be tracked and managed by both parties.

## User Scenarios
1.  **Booking a Sitter**: A pet owner is on a sitter's detail page. They have reviewed the sitter's profile and decide to book. They select their pet(s), the desired dates, and click "Book Now". A request is created and they are redirected to their "My Bookings" screen.
2.  **Tracking the Request**: After booking, the owner sees the request in the "Upcoming" section of their bookings. The sitter sees the new request in their dashboard/bookings.

## Clarifications
### Session 2026-05-07
- Q: Where should the pet selection happen? → A: Dialog on Click (Option A).
- Q: How should the user select dates for the booking? → A: Standard Modal Picker (Option B).
- Q: How should the total price be calculated? → A: Per Night / Per Day (Option B).

## Functional Requirements
1.  **Date Selection**:
    - The `SitterDetailScreen` must provide a "Select Dates" button.
    - Use `showDateRangePicker` to select the booking period.
    - Validate that end date is after start date.
2.  **Pet Selection**:
    - When "Book Now" is clicked, show a `showDialog` or `showModalBottomSheet` with a list of the owner's pets.
    - The owner must select at least one pet.
3.  **Data Capture & Validation**:
    - Capture `ownerUid`, `ownerName`, `ownerPhotoUrl` from the current user profile.
    - Capture `sitterUid`, `sitterName`, `sitterPhotoUrl` from the sitter service profile.
    - Capture `petName`, `petType`, `petImageUrl` of the selected pet.
    - Calculate total `budget`: `sitter_price_per_day * number_of_days`.
4.  **Firestore Integration**:
    - Create a new document in the `sitting_requests` collection.
    - Status must be set to `open`.
    - Set `isPublicJob` to `false`.
5.  **User Feedback**:
    - Show a loading state while the transaction is processing.
    - Show a success confirmation or error message.
    - Redirect to the "My Bookings" screen upon success.

## Success Criteria
- A new Firestore document is created with all required fields correctly populated.
- The owner is redirected to the "My Bookings" screen upon successful submission.
- The newly created booking is visible in the owner's booking list.
- No duplicate bookings are created if the user clicks the button multiple times (idempotency).

## Assumptions
- The current user is authenticated and has at least one pet registered.
- Sitter profiles have a clear pricing model defined in Firestore.
- The `sitting_requests` and `walk_requests` collections exist and have appropriate security rules.

## Terminology
- **Booking**: The transaction record in Firestore.
- **Sitter (Metapel)**: The service provider being booked.
- **Direct Booking**: A request sent to a specific sitter, rather than a public job post.
