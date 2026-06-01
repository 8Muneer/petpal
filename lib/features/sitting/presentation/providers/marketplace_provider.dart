import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_service.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart';
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';

class MarketplaceFilters {
  final String searchQuery;
  final List<String> selectedRules;
  final bool showSitters; // true for sitters, false for jobs
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final List<String> selectedPetTypes;
  final List<String> selectedServiceTypes;
  final DateTime? startDate;
  final DateTime? endDate;
  final int petCount;

  const MarketplaceFilters({
    this.searchQuery = '',
    this.selectedRules = const [],
    this.showSitters = true,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.selectedPetTypes = const [],
    this.selectedServiceTypes = const [],
    this.startDate,
    this.endDate,
    this.petCount = 1,
  });

  MarketplaceFilters copyWith({
    String? searchQuery,
    List<String>? selectedRules,
    bool? showSitters,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    List<String>? selectedPetTypes,
    List<String>? selectedServiceTypes,
    DateTime? startDate,
    DateTime? endDate,
    int? petCount,
  }) {
    return MarketplaceFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRules: selectedRules ?? this.selectedRules,
      showSitters: showSitters ?? this.showSitters,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      selectedPetTypes: selectedPetTypes ?? this.selectedPetTypes,
      selectedServiceTypes: selectedServiceTypes ?? this.selectedServiceTypes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      petCount: petCount ?? this.petCount,
    );
  }

  bool get hasActiveFilters =>
      selectedRules.isNotEmpty ||
      minPrice != null ||
      maxPrice != null ||
      minRating != null ||
      selectedPetTypes.isNotEmpty ||
      selectedServiceTypes.isNotEmpty ||
      startDate != null ||
      endDate != null ||
      petCount > 1;
}

class MarketplaceFiltersNotifier extends Notifier<MarketplaceFilters> {
  @override
  MarketplaceFilters build() => const MarketplaceFilters();

  void updateSearch(String query) => state = state.copyWith(searchQuery: query);

  void updatePriceRange(double min, double max) {
    state = state.copyWith(minPrice: min, maxPrice: max);
  }

  void updateRating(double? rating) {
    state = state.copyWith(minRating: rating);
  }

  void togglePetType(String type) {
    final types = [...state.selectedPetTypes];
    if (types.contains(type)) {
      types.remove(type);
    } else {
      types.add(type);
    }
    state = state.copyWith(selectedPetTypes: types);
  }

  void toggleServiceType(String type) {
    final types = [...state.selectedServiceTypes];
    if (types.contains(type)) {
      types.remove(type);
    } else {
      types.add(type);
    }
    state = state.copyWith(selectedServiceTypes: types);
  }

  void toggleRule(String rule) {
    final rules = [...state.selectedRules];
    if (rules.contains(rule)) {
      rules.remove(rule);
    } else {
      rules.add(rule);
    }
    state = state.copyWith(selectedRules: rules);
  }

  void setTab(bool showSitters) =>
      state = state.copyWith(showSitters: showSitters);

  void updateFilters({
    double? minPrice,
    double? maxPrice,
    double? minRating,
    List<String>? selectedPetTypes,
    List<String>? selectedServiceTypes,
    DateTime? startDate,
    DateTime? endDate,
    int? petCount,
  }) {
    state = state.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
      minRating: minRating,
      selectedPetTypes: selectedPetTypes,
      selectedServiceTypes: selectedServiceTypes,
      startDate: startDate,
      endDate: endDate,
      petCount: petCount ?? state.petCount,
    );
  }

  void clearAll() {
    state = MarketplaceFilters(
      searchQuery: state.searchQuery,
      showSitters: state.showSitters,
    );
  }
}

final marketplaceFiltersProvider =
    NotifierProvider<MarketplaceFiltersNotifier, MarketplaceFilters>(
        MarketplaceFiltersNotifier.new);

final filteredSittingServicesProvider =
    Provider<AsyncValue<List<SittingService>>>((ref) {
  final servicesAsync = ref.watch(sittingServicesProvider);
  final filters = ref.watch(marketplaceFiltersProvider);

  return servicesAsync.whenData((services) {
    return services.where((s) {
      // 1. Search Query
      final matchesSearch = s.providerName
              .toLowerCase()
              .contains(filters.searchQuery.toLowerCase()) ||
          s.area.toLowerCase().contains(filters.searchQuery.toLowerCase()) ||
          (s.bio ?? '').toLowerCase().contains(filters.searchQuery.toLowerCase());

      // 2. Rating Filter
      final matchesRating = filters.minRating == null ||
          (s.rating != null && s.rating! >= filters.minRating!);

      // 3. Price Filter (Parsing priceText like "₪50")
      bool matchesPrice = true;
      if (filters.minPrice != null || filters.maxPrice != null) {
        final price = double.tryParse(s.priceText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        if (filters.minPrice != null && price < filters.minPrice!) {
          matchesPrice = false;
        }
        if (filters.maxPrice != null && price > filters.maxPrice!) {
          matchesPrice = false;
        }
      }

      // 4. Pet Types Filter
      final matchesPetTypes = filters.selectedPetTypes.isEmpty ||
          filters.selectedPetTypes.any((type) => s.petTypes.contains(type));

      // 5. Service Types Filter (Mapping text to SittingLocation or similar)
      final matchesServiceTypes = filters.selectedServiceTypes.isEmpty ||
          filters.selectedServiceTypes.any((type) {
            if (type == 'טיול כלבים') return true; // Placeholder for walking
            if (type == 'פנסיון') return true; // Placeholder for sitting
            return false;
          });

      // 6. Rules/Tags (Existing)
      final matchesRules = filters.selectedRules.every((rule) {
        return (s.bio ?? '').contains(rule);
      });

      return matchesSearch &&
          matchesRating &&
          matchesPrice &&
          matchesPetTypes &&
          matchesServiceTypes &&
          matchesRules;
    }).toList();
  });
});

final publicSittingRequestsProvider =
    StreamProvider<List<SittingRequest>>((ref) {
  final repository = ref.watch(sittingRepositoryProvider);
  return repository.watchPublicRequests();
});

final filteredPublicJobsProvider =
    Provider<AsyncValue<List<SittingRequest>>>((ref) {
  final jobsAsync = ref.watch(publicSittingRequestsProvider);
  final filters = ref.watch(marketplaceFiltersProvider);

  return jobsAsync.whenData((jobs) {
    return jobs.where((j) {
      // 1. Search Query
      final matchesSearch =
          j.petName.toLowerCase().contains(filters.searchQuery.toLowerCase()) ||
              j.area.toLowerCase().contains(filters.searchQuery.toLowerCase());

      // 2. Price/Budget Filter
      bool matchesPrice = true;
      if (filters.minPrice != null || filters.maxPrice != null) {
        final price = double.tryParse(j.budget?.replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0;
        if (filters.minPrice != null && price < filters.minPrice!) {
          matchesPrice = false;
        }
        if (filters.maxPrice != null && price > filters.maxPrice!) {
          matchesPrice = false;
        }
      }

      // 3. Pet Type Filter
      final matchesPetType = filters.selectedPetTypes.isEmpty ||
          filters.selectedPetTypes.any((type) {
            final petTypeStr = j.petType.name.toLowerCase();
            if (type == 'כלב' && petTypeStr.contains('dog')) return true;
            if (type == 'חתול' && petTypeStr.contains('cat')) return true;
            return false;
          });

      // 4. Rules
      final matchesRules = filters.selectedRules.every((rule) {
        return j.rules.contains(rule);
      });

      return matchesSearch && matchesPrice && matchesPetType && matchesRules;
    }).toList();
  });
});
