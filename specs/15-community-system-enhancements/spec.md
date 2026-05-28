# Feature Specification: Community System Enhancements

**Status**: Draft
**Branch**: `15-community-system-enhancements`
**Feature Name**: community-system-enhancements

## 1. Executive Summary
This feature matures the "Trust Network" from a proof-of-concept into a production-ready community platform. Key enhancements include a fully functional commenting system, real user identity integration (replacing all placeholders), dynamic neighborhood alerts, and marketplace integration for service tagging. We will also optimize the feed with infinite scroll and pull-to-refresh capabilities, while removing the "Neighbor Discount" feature to focus on social trust and karma.

## 2. Actors & Personas
- **Verified Neighbor (User)**: Wants to engage in real conversations via comments, see their own profile accurately reflected, and discover trusted sitters from the marketplace.
- **Community Moderator (Future)**: Needs dynamic alerts to communicate urgent information.

## 3. User Scenarios
- **Scenario 1: Engaging in Conversation**: A user sees a post about a new dog park and taps the comment icon. They can see other neighbors' thoughts and add their own, earning karma for participation.
- **Scenario 2: Accurate Identity**: A user posts an update and sees their actual profile name, neighborhood, and verified status reflected instantly, pulled from their PetPal account.
- **Scenario 3: Sitter Recommendation**: A user wants to recommend a sitter they just used. They search the real marketplace during post creation, tag the sitter, and publish the recommendation without any arbitrary discounts.
- **Scenario 4: High-Performance Feed**: A user scrolls through a long feed of neighborhood updates. New posts load smoothly as they reach the bottom (infinite scroll), and they can pull down at any time to see the latest "Pulse" (refresh).

## 4. Functional Requirements

### A. Commenting System
- **FR-01: View Comments**: A dedicated bottom sheet or screen to view a flat list of comments for a post.
- **FR-02: Post Comment**: Ability to write and submit a text comment.
- **FR-03: Comment Count**: Dynamic update of the comment count on the `LuxuryTrustCard`.

### B. Identity & Data Integrity
- **FR-04: Real User Integration**: Replace all hardcoded `'current_user'` IDs and placeholder images with data from the `authStateChangesProvider`.
- **FR-05: Real Marketplace Tagging**: Replace the hardcoded list in `ServiceLookupField` with a live search of the sitters/marketplace collection.
- **FR-06: Dynamic Neighborhood Alerts**: Fetch alerts from a Firestore `community_alerts` collection instead of using static text.

### C. UI/UX Enhancements
- **FR-07: Remove Neighbor Discounts**: Strip the "Neighbor Discount" field from the `CommunityPost` entity, the `LuxuryUtilityChip`, and the post creation flow.
- **FR-08: Premium Empty States**: Implement a high-design "Call to Action" widget (using `frontend-design` and `delight` skills) when a category has no posts.
- **FR-09: Pull-to-Refresh**: Integrate `RefreshIndicator` with the `communityFeedProvider`.
- **FR-10: Infinite Scroll**: Implement pagination logic (Firestore `limit` and `startAfter`) in the `CommunityRepository`.

## 5. Non-Functional Requirements
- **NFR-01: Performance**: Infinite scroll should maintain 60fps during list builds (`optimize` skill).
- **NFR-02: Robustness**: Handle null/missing profile data gracefully with premium fallbacks (`harden` skill).
- **NFR-03: Delight**: Comments and refresh actions should have subtle, luxury animations (`animate` skill).

## 6. Success Criteria
- [ ] Users can post a comment and see it reflected in under 2 seconds.
- [ ] 100% of posts show real user data instead of placeholders.
- [ ] "Service Tagging" returns real search results from the PetPal database.
- [ ] The feed supports infinite loading without stuttering.
- [ ] The "Neighbor Discount" text is no longer visible anywhere in the app.

## 7. Key Entities
- **CommunityComment**: id, postId, authorId, authorName, authorPhotoUrl, content, createdAt.
- **CommunityAlert**: id, title, content, type (urgent/info), neighborhoodId, createdAt.

## 8. Assumptions & Constraints
- We assume the `users` collection in Firestore contains up-to-date profile information.
- Marketplace search will be limited to top-level sitter names initially.
- Neighbor discounts are being removed because the value proposition is moving towards "Verified Trust" rather than "Couponing."

## 9. Clarifications
### Session 2026-05-08
- **Q: Should we support nested replies (threading) or a flat list of comments?** → **A**: Flat List (Option A).
- **Q: Should alerts be global or filtered strictly by the user's current neighborhood?** → **A**: Neighborhood Specific (Option B).
- **Q: How many posts should be loaded per "page" for infinite scroll?** → **A**: 15 Posts (Option B).
