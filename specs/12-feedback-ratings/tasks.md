# Tasks: Feedback and Ratings

## Phase 1: Setup
- [ ] T001 Create `lib/features/reviews` directory structure (`data`, `domain`, `presentation`).
- [ ] T002 Create Supabase SQL migration for `reviews` table and `profiles` table extensions.
- [ ] T003 Create Postgres trigger for auto-calculating `aggregate_rating` and `total_reviews`.

## Phase 2: Foundational (Data & Domain)
- [ ] T004 Create `ReviewModel` and `ReviewEntity` in `domain/entities`.
- [ ] T005 Implement `ReviewsRemoteDataSource` for Supabase interactions.
- [ ] T006 Implement `ReviewsRepository`.

## Phase 3: State Management (Riverpod)
- [ ] T007 Create `ReviewController` for submitting ratings.
- [ ] T008 Create `reviewsProvider` to fetch a user's reviews.

## Phase 4: UI Implementation
- [ ] T009 Create `ReviewDialog` widget (star rating UI, 1-5 stars, no text).
- [ ] T010 Wire up `ReviewDialog` to trigger on "Booking Completed" action.
- [ ] T011 Add "Leave Review" button to Past Bookings list for unreviewed bookings.
- [ ] T012 Bind Sitter Profile and Marketplace Provider to use actual `aggregate_rating`.

## Phase 5: Polish & Testing
- [ ] T013 Verify RLS policies block unauthorized review submissions.
- [ ] T014 Manual testing: Create booking, complete it, leave rating, verify sitter's rating updates correctly.
