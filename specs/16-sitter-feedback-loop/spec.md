# Feature Specification: Advanced Sitter Feedback Loop

**Status**: Draft
**Branch**: `16-sitter-feedback-loop`
**Feature Name**: sitter-feedback-loop

## 1. Executive Summary
This feature implements a comprehensive reputation and feedback ecosystem for the PetPal marketplace. It moves beyond basic star ratings to include detailed text reviews, descriptive "Vibe Tags," and a "Reputation Engine" that rewards sitters for excellence. By integrating with the Karma system, it incentivizes Pet Owners to contribute to the community's trust network, ensuring every sitter has a transparent, verified track record of performance.

## 2. Actors & Personas
- **Pet Owner (Reviewer)**: Wants to share their genuine experience with a sitter and help neighbors make informed decisions. They are motivated by Karma points and community safety.
- **Pet Sitter (Reviewee)**: Wants to build a professional "Boutique" identity. They value verified reviews and reputation badges to stand out in the marketplace.

## 3. User Scenarios
- **Scenario 1: Post-Stay Reflection**: A user's dog "Max" just finished a 3-day stay. The user receives a notification. They open a glassmorphism sheet, select 5 stars, tap "Gentle with Seniors" and "Communicative," and write "Max loved his time! High quality photos sent daily." They earn +10 Karma for this contribution.
- **Scenario 2: Sitter Discovery**: A new user browses the marketplace. They see a sitter with a "Neighborhood Favorite" badge and a 4.9 rating. They tap the profile and see a "Sentiment Bar" showing that "Punctual" is the most common feedback for this sitter.
- **Scenario 3: Repeat Booking Efficiency**: A user who has used the same walker multiple times is prompted to review. To reduce friction, the system presents a "Quick Rate" view (Stars & Tags only), while making the text comment optional. This maintains data accuracy without annoying loyal users.

## 4. Functional Requirements

### A. The Review Submission Flow
- **FR-01: Verified Booking Trigger**: The review flow is ONLY accessible for bookings in the `Completed` state.
- **FR-02: Multi-Factor Feedback**:
    - **Star Rating**: 1-5 integer scale.
    - **Text Review**: Optional text field (max 500 chars).
    - **Vibe Tags**: A selectable list of predefined attributes tailored to the service type (e.g., *Walking* tags: "Good Pacer", "Poop Picked Up"; *Sitting* tags: "Quiet Home", "Sent Photos").
    - **Photo Proof**: Ability to attach up to 3 photos of the pet during the service.
- **FR-03: Karma Integration**: Automatically award Karma points to the reviewer upon successful submission.

### B. Sitter Reputation Engine
- **FR-04: Aggregate Analytics**: Calculate and store the average rating and total review count.
- **FR-05: Sentiment Extraction**: Aggregate the most frequently selected "Vibe Tags" to show a "Top Traits" summary on the sitter's profile.
- **FR-06: Reputation Badges**:
    - **"Neighborhood Favorite"**: Awarded for 10+ reviews with a 4.8+ average.
    - **"New & Trusted"**: Awarded for 3 consecutive 5-star reviews within the first month.
- **FR-07: Verifiable Stay Badge**: Every review in the list is marked with a "Verified Stay" checkmark.

### C. UI/UX (Organic Modernism)
- **FR-08: Review Sheet**: A premium bottom-sheet using `GlassCard` with subtle staggered entrance animations.
- **FR-09: Reputation Gallery**: A horizontal or vertical list on the Sitter Detail screen showing review cards with pet photos and vibe tags.

## 5. Non-Functional Requirements
- **NFR-01: Data Integrity**: Ensure atomic updates when calculating aggregate ratings to prevent race conditions.
- **NFR-02: Performance**: Reputation analytics (vibe tag counts) should be cached or pre-calculated to ensure profile loading in <500ms.
- **NFR-03: Delight**: Use Lottie animations for 5-star ratings and success states.

## 6. Success Criteria
- [ ] Users can complete a review in under 45 seconds.
- [ ] 100% of reviews displayed in the marketplace are linked to real, completed bookings.
- [ ] Sitter profiles accurately reflect the most common "Vibe Tags" within 5 minutes of a new review.
- [ ] Karma points are credited to the owner's account instantly upon review submission.

## 7. Key Entities
- **SitterReview**: `id`, `bookingId`, `sitterId`, `ownerId`, `rating` (int), `comment` (String?), `vibeTags` (List<String>), `imageUrls` (List<String>), `createdAt`.
- **SitterStats**: `sitterId`, `averageRating`, `reviewCount`, `tagFrequencies` (Map<String, int>).

## 8. Assumptions & Constraints
- We assume that "One review per booking" is the standard, even for repeat clients.
- Ratings for Pet Owners (Mutual Rating) is out of scope for this initial version.
- Sentiment analysis will be based on explicit "Vibe Tag" selections rather than AI text analysis of the comment field.

## 9. Clarifications
### Session 2026-05-09
- **Q: How should the system handle feedback for repeat clients?** → **A**: Quick Rate (Option B) - Simplified stars/tags view for repeat bookings.
- **Q: Should reviews be published instantly or have a delay?** → **A**: Instant Publish (Option A) - Immediate transparency in the trust network.
- **Q: Should Vibe Tags be universal or service-specific?** → **A**: Service-Specific (Option B) - Tailored tags based on the service category.
