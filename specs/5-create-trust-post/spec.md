# Feature Specification: Create Trust Post

**Status**: Draft
**Branch**: `feature/5-create-trust-post`
**Feature Name**: create-trust-post

## 1. Executive Summary
Provide a high-fidelity interface for pet parents to contribute to the global PetPal community. This feature allows users to share updates, expert tips, and verified recommendations with all users. It focuses on high-quality visual storytelling and professional service-tagging.

## 2. Actors & Personas
- **Pet Parent (Author)**: Wants to share their pet journey, provide tips, or recommend services to the entire PetPal community.
- **Service Provider (Tagged Entity)**: Receives global visibility and "Trust Karma" when tagged.

## 3. User Scenarios
- **Scenario 1: Global Recommendation**: A user shares a high-quality photo of their pet and tags a service provider. The post is visible to all users on the Community feed.
- **Scenario 2: Expert Tip**: A user shares a safety tip (e.g., "Heatwave paw safety"). It's categorized under 'Tips' for everyone to see.
- **Scenario 3: Direct Posting**: A user captures a moment, adds a caption, and posts it immediately. If they cancel, the content is discarded to keep the experience fast and simple.

## 4. Functional Requirements
- **FR-01: Photo-Only Media Upload**: Support for selecting and previewing up to 5 high-quality photos. Videos are excluded to maintain a high-end static aesthetic.
- **FR-02: Topic Selector**: A horizontal chip-based selector for post categories: Update, Recommendation, Tip, and Playdate.
- **FR-03: Service Tagging Engine**: A searchable lookup to link a post to a Service Provider for verified recommendations.
- **FR-04: Post-or-Discard Logic**: A streamlined flow with no draft persistence. Closing the screen prompts a "Discard?" confirmation to prevent accidental loss.
- **FR-05: Global Visibility**: All posts are public and searchable by all users; no geographic or privacy gating.

## 5. Non-Functional Requirements
- **NFR-01: Luxury Authoring UX**: Premium transitions and a clean, focused editor.
- **NFR-02: Instant Preview**: Zero-lag photo previews and editing.
- **NFR-03: Data Optimization**: Automatic image compression to ensure fast global distribution.

## 6. Success Criteria
- [ ] Users can complete a public post in under 30 seconds.
- [ ] 100% of posts are accessible to the global community instantly.
- [ ] Tagged services receive a "Trust Notification" within 5 seconds.

## 7. Key Entities
- **TrustPost**: AuthorID, PhotoList, Content, Category, LinkedServiceID.

## 8. Assumptions & Constraints
- Gallery access is granted by the user.
- No local persistence of drafts; all work is lost if discarded.
- High-resolution photos only (no video).

## 9. Clarifications (Session 2026-04-25)
- **Q1: Media Scope**: Photos only (Phase 1).
- **Q2: Privacy**: 100% Public. No "Neighborhood" or "Private" gating.
- **Q3: Drafts**: No Drafts. "Post or Discard" experience for maximum speed.
