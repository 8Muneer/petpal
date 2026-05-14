# Feature Specification: Sitter Booking Actions

## Overview
The "Sitter Booking Actions" feature empowers sitters to manage incoming booking requests directly from their dashboard. This includes accepting a request, refusing it with a mandatory reason, and viewing full booking details.

## User Scenarios
1. **Accepting a Request**: A sitter views a new booking request and clicks "Accept" (אישור מהיר). The status updates to `taken` in Firestore.
2. **Refusing a Request**: A sitter clicks the "Refuse" button (which replaces the old Details button). A dialog appears prompting for a free-form text reason. Upon submission, the status updates to `declined` with the reason stored.
3. **Viewing Details**: A sitter clicks anywhere on the request card. They are navigated to the `SittingRequestDetailScreen` showing all booking details.

## Functional Requirements
- [ ] **Connect Accept Button**: Clicking the accept button updates the `SittingRequest` status in Firestore to `taken`.
- [ ] **Implement Refuse Button**: Replace the "Details" button with a "Refuse" button.
- [ ] **Free-form Refusal Dialog**: Clicking "Refuse" shows a luxury-themed dialog to input a free-form text reason.
- [ ] **Update Refusal in Firestore**: Submitting the refusal updates the `SittingRequest` status to `declined` and saves the `refusalReason`.
- [ ] **Card Click Navigation**: Make the `SitterRequestCard` clickable to navigate to `SittingRequestDetailScreen`.
- [ ] **Update Enum**: Add `declined` to the `SittingStatus` enum.

## Success Criteria
- [ ] Sitters can successfully accept a booking and see it move to the Active tab.
- [ ] Sitters can refuse a booking with a reason, and the data is persisted in Firestore.
- [ ] The "Details" button correctly navigates to the relevant details page.

## Assumptions
- The `SittingRequest` model can be extended with a `refusalReason` field.
- The `SittingStatus` enum includes or can be extended with `taken` and `declined`.
