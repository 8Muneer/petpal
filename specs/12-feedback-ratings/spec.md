# Feature Specification: Sitter Feedback and Ratings

## 1. Context & Goals
**Why:** Pet owners need a way to review and rate sitters after a booking is completed to establish trust in the marketplace. Sitters need these ratings to build their reputation.
**What:** A backend-driven feedback system allowing pet owners to submit a 1-5 star rating and optional text review for a sitter, which then updates the sitter's aggregate rating.
**Who:** Pet Owners (reviewers) and Pet Sitters (reviewees).

## 2. User Scenarios
- **Scenario A (Submitting Feedback):** After a booking status changes to "Completed", the pet owner is prompted to leave a rating and review for the sitter.
- **Scenario B (Viewing Ratings):** When a user browses the marketplace, they see the sitter's aggregate rating (e.g., 4.8) and total review count, calculated from all historical feedback.

## 3. Functional Requirements
- The system must allow a Pet Owner to submit exactly one review per completed booking.
- The review consists ONLY of a star rating (1-5). No text comments are allowed.
- Ratings are mutual: Both the Pet Owner and the Pet Sitter can rate each other after a completed booking.
- Review Triggers: The flow is triggered via a pop-up immediately upon booking completion, with a fallback "Leave Review" button in the Past Bookings list for skipped pop-ups.

## 4. Success Criteria
- 100% of completed bookings have the option to be reviewed.
- Sitter aggregate ratings correctly reflect the average of all submitted reviews.
- Reviews fetch instantly when loading a sitter's detailed profile.

## 5. Key Entities / Data Model
- **Review:** `id`, `booking_id`, `reviewer_id`, `reviewee_id`, `rating`, `created_at`.
- **Sitter & Owner Profile Extensions:** `aggregate_rating` and `total_reviews`.

## 6. Assumptions & Scope
- Scope is limited to the backend logic and wiring up the existing UI stars to this logic.
- We assume standard 1-5 integer or half-step ratings.
