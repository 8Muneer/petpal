import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/features/sitting/data/models/sitting_request_model.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_service.dart';
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';
import 'package:petpal/features/walks/domain/entities/walk_request.dart';
import 'package:petpal/features/walks/presentation/providers/walk_provider.dart';
import 'package:petpal/core/widgets/luxury_booking_card.dart';
import 'package:petpal/core/providers/firebase_providers.dart';

class UnifiedBooking {
  final String id;
  final String petName;
  final String petPhotoUrl;
  final String title;
  final LuxuryServiceCategory category;
  final String date;
  final String time;
  final String price;
  final LuxuryBookingStatus status;
  final String reviewerId;
  final String? revieweeId;
  final String? revieweeName;
  final bool isAccepted;
  final dynamic originalRequest; // To pass to details screen

  UnifiedBooking({
    required this.id,
    required this.petName,
    required this.petPhotoUrl,
    required this.title,
    required this.category,
    required this.date,
    required this.time,
    required this.price,
    required this.status,
    required this.reviewerId,
    this.revieweeId,
    this.revieweeName,
    required this.isAccepted,
    required this.originalRequest,
  });
}

class BookingsState {
  final int selectedStatusIndex; // 0: Upcoming, 1: Completed, 2: Cancelled
  final String selectedCategory; // 'All', 'Walks', 'Sitting'
  final String searchQuery;

  BookingsState({
    this.selectedStatusIndex = 0,
    this.selectedCategory = 'All',
    this.searchQuery = '',
  });

  BookingsState copyWith({
    int? selectedStatusIndex,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return BookingsState(
      selectedStatusIndex: selectedStatusIndex ?? this.selectedStatusIndex,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class BookingsController extends StateNotifier<BookingsState> {
  BookingsController() : super(BookingsState());

  void setStatus(int index) =>
      state = state.copyWith(selectedStatusIndex: index);
  void setCategory(String category) =>
      state = state.copyWith(selectedCategory: category);
  void setSearch(String query) => state = state.copyWith(searchQuery: query);

  Future<void> createBooking(SittingRequest request) async {
    final firestore = FirebaseFirestore.instance;

    // Convert entity to model for Firestore serialization
    final model = SittingRequestModel(
      id: request.id,
      ownerUid: request.ownerUid,
      ownerName: request.ownerName,
      ownerPhotoUrl: request.ownerPhotoUrl,
      petName: request.petName,
      petType: request.petType,
      petGender: request.petGender,
      petImageUrl: request.petImageUrl,
      startDate: request.startDate,
      endDate: request.endDate,
      sittingType: request.sittingType,
      area: request.area,
      specialInstructions: request.specialInstructions,
      budget: request.budget,
      status: request.status,
      rules: request.rules,
      isPublicJob: request.isPublicJob,
      sitterUid: request.sitterUid,
      sitterName: request.sitterName,
      createdAt: request.createdAt,
    );

    await firestore.collection('sitting_requests').add(model.toFirestore());
  }
}

final bookingsControllerProvider =
    StateNotifierProvider<BookingsController, BookingsState>((ref) {
  return BookingsController();
});

final unifiedBookingsProvider =
    Provider<AsyncValue<List<UnifiedBooking>>>((ref) {
  final walksAsync = ref.watch(combinedWalkBookingsProvider);
  final sittingAsync = ref.watch(combinedSittingBookingsProvider);
  final bookingsState = ref.watch(bookingsControllerProvider);
  final currentUid = ref.watch(authStateChangesProvider).asData?.value?.uid;

  return walksAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (walks) {
      return sittingAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
        data: (sitting) {
          final services =
              ref.watch(sittingServicesProvider).asData?.value ?? [];

          // 1. Map to Unified Model
          List<UnifiedBooking> unified = [];

          for (var walk in walks) {
            final isOwner = walk.ownerUid == currentUid;
            final counterpartyName =
                isOwner ? (walk.sitterName ?? 'מטפל טרם נקבע') : walk.ownerName;
            final titlePrefix = isOwner ? 'מטפל: ' : 'לקוח: ';

            unified.add(UnifiedBooking(
              id: walk.id,
              petName: walk.petName,
              petPhotoUrl: walk.petImageUrl ??
                  'https://images.unsplash.com/photo-1543466835-00a7907e9de1?q=80&w=1000',
              title: '$titlePrefix$counterpartyName',
              category: LuxuryServiceCategory.walks,
              date: walk.preferredDate != null
                  ? '${walk.preferredDate!.day}/${walk.preferredDate!.month}/${walk.preferredDate!.year}'
                  : 'תאריך גמיש',
              time: walk.preferredTime,
              price: walk.budget != null ? '₪${walk.budget}' : '₪35',
              status: _mapWalkStatus(walk.status),
              isAccepted: walk.status == WalkStatus.taken,
              reviewerId: walk.ownerUid,
              revieweeId: walk.sitterUid,
              revieweeName: walk.sitterName,
              originalRequest: walk,
            ));
          }

          for (var sit in sitting) {
            final isOwner = sit.ownerUid == currentUid;
            final counterpartyName =
                isOwner ? (sit.sitterName ?? 'מטפל טרם נקבע') : sit.ownerName;
            final titlePrefix = isOwner ? 'מטפל: ' : 'לקוח: ';

            unified.add(UnifiedBooking(
              id: sit.id,
              petName: sit.petName,
              petPhotoUrl: sit.petImageUrl ??
                  'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?q=80&w=1000',
              title: '$titlePrefix$counterpartyName',
              category: LuxuryServiceCategory.sitting,
              date: sit.startDate != null
                  ? '${sit.startDate!.day}/${sit.startDate!.month}'
                  : 'גמיש',
              time: '${sit.numberOfNights} לילות',
              price: sit.budget != null ? '₪${sit.budget}' : '₪120',
              status: _mapSittingStatus(sit.status),
              isAccepted: sit.status == SittingStatus.taken,
              reviewerId: sit.ownerUid,
              revieweeId: services
                      .cast<SittingService?>()
                      .firstWhere((s) => s?.providerUid == sit.sitterUid,
                          orElse: () => null)
                      ?.id ??
                  sit.sitterUid,
              revieweeName: sit.sitterName,
              originalRequest: sit,
            ));
          }

          // 2. Filter by Status
          unified = unified.where((b) {
            if (bookingsState.selectedStatusIndex == 0) {
              return b.status == LuxuryBookingStatus.upcoming;
            }
            if (bookingsState.selectedStatusIndex == 1) {
              return b.status == LuxuryBookingStatus.completed;
            }
            return b.status == LuxuryBookingStatus.cancelled;
          }).toList();

          // 3. Filter by Category
          if (bookingsState.selectedCategory != 'All') {
            final cat = bookingsState.selectedCategory == 'Walks'
                ? LuxuryServiceCategory.walks
                : LuxuryServiceCategory.sitting;
            unified = unified.where((b) => b.category == cat).toList();
          }

          // 4. Filter by Search
          if (bookingsState.searchQuery.isNotEmpty) {
            final query = bookingsState.searchQuery.toLowerCase();
            unified = unified
                .where((b) =>
                    b.petName.toLowerCase().contains(query) ||
                    b.title.toLowerCase().contains(query))
                .toList();
          }

          return AsyncValue.data(unified);
        },
      );
    },
  );
});

LuxuryBookingStatus _mapWalkStatus(WalkStatus status) {
  if (status == WalkStatus.closed) return LuxuryBookingStatus.completed;
  if (status == WalkStatus.open) {
    return LuxuryBookingStatus
        .upcoming; // Assuming open/taken are upcoming for now
  }
  return LuxuryBookingStatus.upcoming;
}

LuxuryBookingStatus _mapSittingStatus(SittingStatus status) {
  if (status == SittingStatus.closed) return LuxuryBookingStatus.completed;
  return LuxuryBookingStatus.upcoming;
}
