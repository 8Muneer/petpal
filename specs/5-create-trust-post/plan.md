# Implementation Plan: Create Trust Post (Luxury)

**Feature**: create-trust-post
**Branch**: `feature/5-create-trust-post`

## 1. Technical Strategy
We will implement the `CreateTrustPostScreen` as a modal overlay or a full-screen transition from the Community feed. The screen will use a multi-step form or a single-page scrolling layout with a focused, premium UX. We will use the `image_picker` package for media selection.

### Skills to Use:
- `frontend-design`: For the premium editor interface.
- `onboard`: To make the posting flow intuitive and rewarding.
- `harden`: For robust media handling and input validation.
- `animate`: For smooth transitions and image preview entry effects.

## 2. Proposed Changes

### Phase 1: Foundation (Models & Setup)
- [MODIFY] `lib/features/community/domain/entities/community_post.dart`:
  - Ensure the entity supports multi-photo lists.
- [NEW] `lib/features/community/presentation/providers/create_post_provider.dart`:
  - State management for the current post draft (content, category, photos, linked service).
  - Validation logic for the "Post" button.

### Phase 2: Core Components (The Editor)
- [NEW] `lib/features/community/presentation/widgets/photo_picker_grid.dart`:
  - A horizontal scrollable grid for picking and previewing up to 5 photos.
  - Delete/Reorder support for photos.
- [NEW] `lib/features/community/presentation/widgets/service_lookup_field.dart`:
  - A searchable field to find and tag Service Providers.
- [NEW] `lib/features/community/presentation/widgets/category_chip_selector.dart`:
  - Chip-based selector for Update, Recommendation, Tip, Playdate.

### Phase 3: Screen Assembly
- [NEW] `lib/features/community/presentation/screens/create_trust_post_screen.dart`:
  - The main container with a Luxury top bar (Cancel/Post actions).
  - Integration of the editor components.
  - Discard confirmation dialog.

### Phase 4: Integration
- [MODIFY] `lib/features/community/presentation/screens/community_feed_screen.dart`:
  - Connect the Floating Action Button (FAB) to open `CreateTrustPostScreen`.
  - Add logic to refresh the feed after a successful post (optimistic update).

## 3. Verification Plan

### Automated Tests
- Widget tests for `PhotoPickerGrid` to ensure max 5 photos limit.
- Provider tests for `CreatePostController` to verify mandatory fields (content, category).

### Manual Verification
- Verify the discard dialog appears when trying to leave with unsaved content.
- Ensure tagged services correctly appear in the resulting post on the feed.
- Check image compression quality and upload speed.
