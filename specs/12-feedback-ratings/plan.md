# Implementation Plan: Feedback and Ratings

## Technical Context
- **Tech Stack**: Flutter, Riverpod (State Management), Supabase (Backend/Database).
- **Core Entities**: `SittingService`, `Profile` (from `auth`/`profile` domains), `Review` (new entity).
- **Architecture**: Feature-first architecture. This fits best under a new or existing module. Since it involves both sitters and owners, creating a `reviews` feature module is ideal.

## Proposed Implementation

### 1. Database Schema (Supabase)
- **Table**: `reviews`
  - `id` (uuid, PK)
  - `booking_id` (uuid, FK to bookings/requests)
  - `reviewer_id` (uuid, FK to profiles)
  - `reviewee_id` (uuid, FK to profiles)
  - `rating` (int 1-5 or numeric)
  - `created_at` (timestamp)
- **Table Updates**: `profiles`
  - Add `aggregate_rating` (numeric)
  - Add `total_reviews` (int)
- **Database Logic**: 
  - Create a Postgres Trigger or Supabase Edge Function to automatically update `aggregate_rating` and `total_reviews` on the `profiles` table whenever a new review is inserted.

### 2. Flutter Data Layer
- **Model**: `ReviewModel`
- **Datasource**: `ReviewsRemoteDataSource` for interacting with the `reviews` table.
- **Repository**: `ReviewsRepository`

### 3. Flutter State Management (Riverpod)
- **Provider**: `reviewsProvider(profileId)` to fetch all reviews for a specific user.
- **Controller**: `ReviewController` to handle the logic of submitting a new review and updating the state.

### 4. UI Layer
- **Trigger**: When a booking is marked as "Completed", trigger a bottom sheet or dialog (`ReviewDialog`) to rate the other party.
- **Fallback**: Add a "Leave Review" button in the "My Bookings" list for completed bookings that have not yet been reviewed.
- **Display**: Bind the `aggregate_rating` to the existing Sitter Profile cards and `FilterBottomSheet` we designed earlier.

## Security & Privacy
- **RLS (Row Level Security)**: 
  - `reviews` table: Anyone can read (`SELECT`), but a user can only `INSERT` if `auth.uid() == reviewer_id` and the booking exists and is completed.

## Open Questions / Clarifications
- None. (All clarifications resolved in spec.md).
