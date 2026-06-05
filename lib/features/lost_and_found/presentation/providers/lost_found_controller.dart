import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/features/lost_and_found/domain/entities/lost_found_post.dart';
import 'package:petpal/features/lost_and_found/presentation/providers/lost_found_provider.dart';

enum LostFoundViewType { grid, map }

class LostFoundState {
  final int selectedTabIndex;
  final String searchQuery;
  final LostFoundViewType viewType;
  final String? selectedPetType;
  final String? selectedArea;
  final String? selectedColor;
  final String? selectedSize;
  final String? selectedGender;
  final String? selectedDateRange; // '24h' | 'week' | 'month'
  final bool showActiveOnly;
  final bool hasImageOnly;
  final bool showMyReportsOnly;

  const LostFoundState({
    this.selectedTabIndex = 0,
    this.searchQuery = '',
    this.viewType = LostFoundViewType.grid,
    this.selectedPetType,
    this.selectedArea,
    this.selectedColor,
    this.selectedSize,
    this.selectedGender,
    this.selectedDateRange,
    this.showActiveOnly = false,
    this.hasImageOnly = false,
    this.showMyReportsOnly = false,
  });

  bool get hasActiveFilters =>
      selectedPetType != null ||
      selectedArea != null ||
      selectedColor != null ||
      selectedSize != null ||
      selectedGender != null ||
      selectedDateRange != null ||
      showActiveOnly ||
      hasImageOnly ||
      showMyReportsOnly;

  LostFoundState copyWith({
    int? selectedTabIndex,
    String? searchQuery,
    LostFoundViewType? viewType,
    String? selectedPetType,
    String? selectedArea,
    String? selectedColor,
    String? selectedSize,
    String? selectedGender,
    String? selectedDateRange,
    bool? showActiveOnly,
    bool? hasImageOnly,
    bool? showMyReportsOnly,
    bool clearPetType = false,
    bool clearArea = false,
    bool clearColor = false,
    bool clearSize = false,
    bool clearGender = false,
    bool clearDateRange = false,
  }) {
    return LostFoundState(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      searchQuery: searchQuery ?? this.searchQuery,
      viewType: viewType ?? this.viewType,
      selectedPetType: clearPetType ? null : (selectedPetType ?? this.selectedPetType),
      selectedArea: clearArea ? null : (selectedArea ?? this.selectedArea),
      selectedColor: clearColor ? null : (selectedColor ?? this.selectedColor),
      selectedSize: clearSize ? null : (selectedSize ?? this.selectedSize),
      selectedGender: clearGender ? null : (selectedGender ?? this.selectedGender),
      selectedDateRange: clearDateRange ? null : (selectedDateRange ?? this.selectedDateRange),
      showActiveOnly: showActiveOnly ?? this.showActiveOnly,
      hasImageOnly: hasImageOnly ?? this.hasImageOnly,
      showMyReportsOnly: showMyReportsOnly ?? this.showMyReportsOnly,
    );
  }
}

class LostFoundController extends StateNotifier<LostFoundState> {
  LostFoundController() : super(const LostFoundState());

  void setTab(int index) => state = state.copyWith(selectedTabIndex: index);
  void setSearch(String query) => state = state.copyWith(searchQuery: query);
  void setViewType(LostFoundViewType type) => state = state.copyWith(viewType: type);

  void setPetType(String? v) => state = v == null
      ? state.copyWith(clearPetType: true)
      : state.copyWith(selectedPetType: v);

  void setArea(String? v) => state = (v == null || v.isEmpty)
      ? state.copyWith(clearArea: true)
      : state.copyWith(selectedArea: v);

  void setColor(String? v) => state = v == null
      ? state.copyWith(clearColor: true)
      : state.copyWith(selectedColor: v);

  void setSize(String? v) => state = v == null
      ? state.copyWith(clearSize: true)
      : state.copyWith(selectedSize: v);

  void setGender(String? v) => state = v == null
      ? state.copyWith(clearGender: true)
      : state.copyWith(selectedGender: v);

  void setDateRange(String? v) => state = v == null
      ? state.copyWith(clearDateRange: true)
      : state.copyWith(selectedDateRange: v);

  void setActiveOnly(bool v) => state = state.copyWith(showActiveOnly: v);
  void setHasImageOnly(bool v) => state = state.copyWith(hasImageOnly: v);
  void toggleMyReportsOnly() => state = state.copyWith(showMyReportsOnly: !state.showMyReportsOnly);

  void clearFilters() => state = LostFoundState(
        selectedTabIndex: state.selectedTabIndex,
        viewType: state.viewType,
      );
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
          .where((p) => p.species == state.selectedPetType)
          .toList();
    }

    if (state.selectedArea != null && state.selectedArea!.isNotEmpty) {
      final area = state.selectedArea!.toLowerCase();
      filtered = filtered
          .where((p) => p.area.toLowerCase().contains(area))
          .toList();
    }

    if (state.selectedColor != null) {
      final color = state.selectedColor!.toLowerCase();
      filtered = filtered
          .where((p) => p.color.toLowerCase().contains(color))
          .toList();
    }

    if (state.selectedSize != null) {
      filtered = filtered
          .where((p) => p.size == state.selectedSize)
          .toList();
    }

    if (state.selectedGender != null) {
      filtered = filtered
          .where((p) => p.gender == state.selectedGender)
          .toList();
    }

    if (state.selectedDateRange != null) {
      final now = DateTime.now();
      final cutoff = state.selectedDateRange == '24h'
          ? now.subtract(const Duration(hours: 24))
          : state.selectedDateRange == 'week'
              ? now.subtract(const Duration(days: 7))
              : now.subtract(const Duration(days: 30));
      filtered = filtered
          .where((p) => p.createdAt != null && p.createdAt!.isAfter(cutoff))
          .toList();
    }

    if (state.showActiveOnly) {
      filtered = filtered
          .where((p) => p.status == LostFoundStatus.active)
          .toList();
    }

    if (state.hasImageOnly) {
      filtered = filtered.where((p) => p.imageUrl.isNotEmpty).toList();
    }

    if (state.showMyReportsOnly) {
      filtered = filtered.where((p) => p.reporterUid == currentUserUid).toList();
    }

    return filtered;
  });
});
