# Feature Specification: Community Trust Dynamics

**Status**: Draft
**Branch**: `6-community-trust-dynamics`
**Feature Name**: community-trust-dynamics

## 1. Executive Summary
Transform the Community Trust Network from a static feed into an interactive trust ecosystem. This feature implements the Karma system to reward helpful contributors, integrates trust posts with the booking system to drive commerce, applies neighbor discounts automatically, and introduces neighbor profiles to establish reputation.

## 2. Actors & Personas
- **Contributor (Pet Parent)**: Shares content and recommendation to earn Karma and build trust.
- **Consumer (Pet Parent)**: Discovers services, asks for help, and books services with trusted discounts.
- **Service Provider**: Receives bookings from the community and offers exclusive "Neighbor Discounts".

## 3. User Scenarios
- **Scenario 1: Earning Karma**: A user posts a verified recommendation for a dog walker. Other users "give treats" (like). The author receives 1 point per treat and 3 points for the initial recommendation.
- **Scenario 2: Booking with Trust**: A user sees a recommendation for "Muni's Dog Walking" with a "5% Neighbor Discount". They click "Book Now" and are taken to the booking flow with the discount automatically applied.
- **Scenario 3: Reputation Research**: A user clicks on a neighbor's avatar to see their profile. They see the neighbor's total karma (e.g., 450) and their history of helpful tips, confirming they are a trusted source.

## 4. Functional Requirements
- **FR-01: Karma Accumulation Engine**: Logic to calculate and update karma based on community engagement (Treats = 1pt, Recommendations = 3pts).
- **FR-02: Neighbor Discount Logic**: System to recognize and apply service-specific discounts mentioned in trust posts during the booking checkout.
- **FR-03: Community-to-Booking Bridge**: Deep-linking from the `LuxuryUtilityChip` in a trust post to the corresponding service's booking screen.
- **FR-04: Neighbor Trust Profile**: A dedicated screen showing a user's karma history, contribution count, and expertise badges.
- **FR-05: Treat Interaction**: Interactive haptic/visual feedback when a user gives a "Treat" to a post.

## 5. Non-Functional Requirements
- **NFR-01: Real-time Trust Feedback**: Karma updates should feel instant and rewarding.
- **NFR-02: Seamless Commerce Integration**: Transition from post to booking must be frictionless (< 2 taps).
- **NFR-03: Transparent Reputation**: Karma scoring rules should be clear to all users via an info dialog.

## 6. Success Criteria
- [ ] Users can navigate from a trust post to a booking in under 2 seconds.
- [ ] Average neighbor karma increases by 20% in the first month.
- [ ] 90% of users understand how to earn karma (verified via info dialog views).
- [ ] Neighbor discounts are correctly applied in 100% of trust-originating bookings.

## 7. Key Entities
- **KarmaTransaction**: UserID, PostID, PointsAdded, Timestamp, Reason.
- **NeighborProfile**: UserID, TotalKarma, BadgeList, ActivityHistory.

## 9. Edge Cases & Security
- **SEC-01: Fraud Prevention (Karma Gaming)**: To prevent users from artificially inflating karma, a **Daily Cap (Option B)** is implemented.
  - Max 10 Treats can be given by a single user per 24 hours.
  - Max 50 Karma points can be earned by a single user per 24 hours.
  - "One Treat per Post" rule still applies (users cannot treat the same post twice).

## 10. Clarifications
### Session 2026-04-25
- **Q: How should we prevent users from "gaming" the system?**
- **A: Option B (Daily Cap)**: Limit the total amount of Karma a single user can give or receive in a 24-hour period.
