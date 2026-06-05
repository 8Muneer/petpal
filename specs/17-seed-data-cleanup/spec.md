# Feature Specification: Seed Data & Cleanup System

**Status**: Draft
**Branch**: `17-seed-data-cleanup`
**Feature Name**: seed-data-cleanup

## 1. Executive Summary
This feature provides a robust "Demo Mode" for PetPal by populating the application with realistic, high-quality mock data including Service Providers (Metaplem), Pet Owners, Pets, Bookings, and verified Reviews. This allows stakeholders and developers to experience the app's "Organic Modernism" UI and full functional logic (marketplace discovery, booking flows, reputation dynamics) without requiring manual data entry. It also includes a "Reset & Cleanup" utility accessible from the developer/profile settings to purge all generated mock data, returning the app to its pristine state.

## 2. Actors & Personas
- **Developer/Stakeholder**: Wants to demonstrate the app's full capabilities (discovery, chat, booking, reviews) to others without a cold-start problem.
- **Beta Tester**: Wants to see how the app handles large volumes of data and multiple active bookings.
- **Admin**: Needs a way to clear test data quickly before a production deployment or fresh test run.

## 3. User Scenarios
- **Scenario 1: The "Full App" Experience**: A developer logs into a fresh instance of the app. They tap a "Seed Demo Data" button (or it's triggered automatically). Suddenly, the marketplace is populated with 10+ sitters with varying ratings, 50+ pets, and several active/past bookings. The "Explore" screen feels alive and premium.
- **Scenario 2: Data Cleanup**: After a day of testing, the developer wants to test the "Empty State" design of the My Bookings screen. They go to Profile -> Developer Settings -> tap "Clear All Mock Data". All generated users, bookings, and pets are deleted from Firestore, leaving only their own account.
- **Scenario 3: Realistic Reputation Testing**: A tester wants to see the "Neighborhood Favorite" badge in action. The seed system generates a sitter with 15+ high-quality reviews and specific vibe tags, allowing the tester to verify the reputation UI.

## 4. Functional Requirements

### A. Seed Data Generation
- **FR-01: Realistic Provider Profiles**: Generate 10-15 "Metaplem" (Service Providers) with high-quality profile photos (Unsplash), unique bios, services (Walking, Sitting, Grooming), and varying availability.
- **FR-02: Diverse Pet Owner Base**: Generate 10-15 Pet Owners, each with 1-3 pets. Pets must have names, types, breeds, and personality tags.
- **FR-03: Historical & Active Bookings**: Generate 30+ bookings across different states: `Pending`, `Confirmed`, `Ongoing`, and `Completed`.
- **FR-04: Deep Reputation Data**: For `Completed` bookings, generate realistic ratings (1-5 stars) and Hebrew comments with associated "Vibe Tags".
- **FR-05: Consistent Identity & Safety**: All seed data must use a unique email pattern (e.g., `@demo.petpal.com`) and a database flag `isMock: true`. This dual-layer approach ensures that deletion logic is highly targeted and safe.

### B. Cleanup Utility
- **FR-06: Global Delete Button**: A "Clear Mock Data" button in the Profile/Settings screen.
- **FR-07: Targeted Purge**: The cleanup logic must ONLY delete documents marked with the mock metadata (or those created by the seed system), ensuring the current user's actual account and real data remain untouched.
- **FR-08: Progress Feedback**: Show a loading indicator and success snackbar during the seeding/cleanup process.

### C. UI/UX (Organic Modernism)
- **FR-09: Profile Header Entry**: The "Seed" and "Clear" buttons will be placed prominently in the Profile screen header (or top action bar) for quick access during testing/demos.
- **FR-10: Confirmation Dialog**: A premium, Hebrew-localized confirmation dialog before clearing data to prevent accidental loss of test data.

## 5. Non-Functional Requirements
- **NFR-01: Atomicity**: Seeding should happen in a way that doesn't leave partial data if a network error occurs (batch writes where possible).
- **NFR-02: Performance**: Seeding 100+ documents should complete in under 10 seconds.
- **NFR-03: Localization & Quality**: Use a curated, high-quality list of 20+ realistic Hebrew bios and reviews. This ensures the demo data looks professional and contextually accurate for the Israeli market.

## 6. Success Criteria
- [ ] Marketplace shows 10+ active, realistic sitters after seeding.
- [ ] "My Bookings" screen shows a mix of historical and active bookings.
- [ ] Profile Reputation section correctly aggregates mock reviews and displays badges.
- [ ] "Clear Mock Data" button removes all generated documents from Firestore.
- [ ] System successfully distinguishes between "Mock" and "Real" users, never deleting real user accounts.

## 7. Key Entities (Firestore Structure)
- **User**: (existing) `isMock` (bool) flag.
- **Booking**: (existing) `isMock` (bool) flag.
- **Pet**: (existing) `isMock` (bool) flag.
- **Review**: (existing) `isMock` (bool) flag.

## 8. Assumptions & Constraints
- We assume Unsplash is accessible for profile and pet photos.
- We assume the current user is logged in as an "Admin" or it's a "Debug" build for the seeding buttons to be visible.
- Deletion is permanent for the mock data.

## 9. Clarifications
### Session 2026-05-10
- **Q1: Seeding Trigger & Automation** → **A**: Purely Manual (Option A) - Buttons in Profile for explicit control.
- **Q2: Identity Separation (Data Safety)** → **A**: Email Pattern + Flag (Option B) - Dual-layer protection for safe deletion.
- **Q3: UI Location & Visibility** → **A**: Profile Header (Option A) - Prominent action buttons at the top of the Profile.
- **Q4: Data Localization (Hebrew Variety)** → **A**: Curated Fixed List (Option A) - Hand-written, realistic Hebrew content.
- **Q5: Seeding Volume (Fullness)** → **A**: Single Balanced Seed (Option A) - Standard ~10 providers/owners/bookings.
