# Tasks: Create Trust Post

## Phase 1: Foundation (Models & Setup)
- [x] Update `CommunityPost` entity to support multiple photos in `lib/features/community/domain/entities/community_post.dart` [priority: high]
- [x] Create `createPostProvider` in `lib/features/community/presentation/providers/create_post_provider.dart` [priority: high]

## Phase 2: Editor Components
- [x] Build `PhotoPickerGrid` in `lib/features/community/presentation/widgets/photo_picker_grid.dart` [priority: high]
- [x] Build `ServiceLookupField` in `lib/features/community/presentation/widgets/service_lookup_field.dart` [priority: medium]
- [x] Build `CategoryChipSelector` in `lib/features/community/presentation/widgets/category_chip_selector.dart` [priority: medium]

## Phase 3: Screen Assembly
- [x] Implement `CreateTrustPostScreen` UI in `lib/features/community/presentation/screens/create_trust_post_screen.dart` [priority: high]
- [x] Implement "Discard Confirmation" dialog logic [priority: medium]
- [x] Implement "Post" submission logic with optimistic feed update [priority: high]

## Phase 4: Integration & Polish
- [x] Connect Community Feed FAB to the new screen [priority: high]
- [x] Final polish pass with `animate` and `delight` skills [priority: medium]
- [x] Verify photo compression and loading states [priority: low]
