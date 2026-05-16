import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/features/lost_and_found/domain/entities/lost_found_post.dart';
import 'package:petpal/features/lost_and_found/presentation/providers/lost_found_provider.dart';

enum LostFoundViewType { grid, map }

class LostFoundState {
  final int selectedTabIndex;
  final String searchQuery;
  final LostFoundViewType viewType;
  final String? selectedPetType;

  const LostFoundState({
    this.selectedTabIndex = 0,
    this.searchQuery = '',
    this.viewType = LostFoundViewType.grid,
    this.selectedPetType,
  });

  LostFoundState copyWith({
    int? selectedTabIndex,
    String? searchQuery,
    LostFoundViewType? viewType,
    String? selectedPetType,
  }) {
    return LostFoundState(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      searchQuery: searchQuery ?? this.searchQuery,
      viewType: viewType ?? this.viewType,
      selectedPetType: selectedPetType ?? this.selectedPetType,
    );
  }
}

class LostFoundController extends StateNotifier<LostFoundState> {
  LostFoundController() : super(const LostFoundState());

  void setTab(int index) => state = state.copyWith(selectedTabIndex: index);

  void setSearch(String query) => state = state.copyWith(searchQuery: query);

  void setViewType(LostFoundViewType type) =>
      state = state.copyWith(viewType: type);

  void setPetType(String? petType) =>
      state = state.copyWith(selectedPetType: petType);

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      selectedPetType: null,
    );
  }
}

final lostFoundControllerProvider =
    StateNotifierProvider<LostFoundController, LostFoundState>((ref) {
  return LostFoundController();
});

final filteredLostFoundPostsProvider =
    Provider<AsyncValue<List<LostFoundPost>>>((ref) {
  final state = ref.watch(lostFoundControllerProvider);

  final postsAsync = state.selectedTabIndex == 0
      ? ref.watch(lostPostsProvider)
      : ref.watch(foundPostsProvider);

  return postsAsync.whenData((posts) {
    var filtered = posts;

    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((post) {
        return post.petName.toLowerCase().contains(query) ||
            post.breed.toLowerCase().contains(query) ||
            post.area.toLowerCase().contains(query) ||
            post.description.toLowerCase().contains(query);
      }).toList();
    }

    if (state.selectedPetType != null) {
      filtered = filtered
          .where((post) => post.species == state.selectedPetType)
          .toList();
    }

    return filtered;
  });
});
