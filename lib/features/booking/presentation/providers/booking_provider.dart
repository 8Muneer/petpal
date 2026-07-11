import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/booking/data/datasources/booking_remote_datasource.dart';
import 'package:petpal/features/booking/data/models/booking_request_model.dart';
import 'package:petpal/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';
import 'package:petpal/features/booking/domain/repositories/booking_repository.dart';
import 'package:petpal/features/booking/presentation/providers/booking_history_state.dart';

final bookingDatasourceProvider = Provider<BookingRemoteDatasource>((ref) {
  return BookingRemoteDatasource(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepositoryImpl(ref.watch(bookingDatasourceProvider));
});

/// Bookings the current pet owner has sent.
final myBookingsProvider = StreamProvider<List<BookingRequest>>((ref) {
  final uid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(bookingRepositoryProvider).watchOwnerBookings(uid);
});

/// Booking requests incoming to the current service provider.
final incomingBookingsProvider = StreamProvider<List<BookingRequest>>((ref) {
  final uid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(bookingRepositoryProvider).watchProviderBookings(uid);
});

/// Pending-only count for badge display.
final pendingBookingCountProvider = Provider<int>((ref) {
  return ref.watch(incomingBookingsProvider).asData?.value
          .where((b) => b.status == BookingStatus.pending)
          .length ??
      0;
});

// ─────────────────────────────────────────────────────────────────────────────
//  Cursor-paginated booking history (the "היסטוריה" tab). Mirrors
//  PaginatedFeedNotifier (feed_provider.dart): fixed page size, one-shot
//  `.get()` queries chained with `.startAfterDocument()`, loaded further on
//  scroll. The "פעילות" tab keeps using the live streams above — it's a
//  handful of in-flight bookings that need to update in real time, while
//  history is terminal (completed/declined/cancelled/expired) and never
//  changes once fetched, so a one-shot paginated fetch fits it better.
class PaginatedBookingHistoryNotifier
    extends StateNotifier<AsyncValue<BookingHistoryState>> {
  final Query Function() _queryBuilder;
  static const int pageSize = 15;

  PaginatedBookingHistoryNotifier(this._queryBuilder)
      : super(const AsyncLoading()) {
    fetchFirstPage();
  }

  Future<void> fetchFirstPage() async {
    state = const AsyncLoading();
    try {
      final snap = await _queryBuilder().limit(pageSize).get();
      final bookings = snap.docs
          .map((doc) => BookingRequestModel.fromFirestore(doc))
          .toList();
      state = AsyncValue.data(BookingHistoryState(
        bookings: bookings,
        hasMore: snap.docs.length == pageSize,
        lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> fetchNextPage() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final snap = await _queryBuilder()
          .startAfterDocument(current.lastDoc!)
          .limit(pageSize)
          .get();
      final newBookings = snap.docs
          .map((doc) => BookingRequestModel.fromFirestore(doc))
          .toList();
      state = AsyncValue.data(BookingHistoryState(
        bookings: [...current.bookings, ...newBookings],
        hasMore: snap.docs.length == pageSize,
        lastDoc: snap.docs.isNotEmpty ? snap.docs.last : current.lastDoc,
      ));
    } catch (_) {
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
    }
  }
}

/// Paginated booking history for the current pet owner.
final myBookingHistoryProvider = StateNotifierProvider.autoDispose<
    PaginatedBookingHistoryNotifier, AsyncValue<BookingHistoryState>>((ref) {
  final uid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
  final datasource = ref.watch(bookingDatasourceProvider);
  return PaginatedBookingHistoryNotifier(
      () => datasource.ownerBookingsQuery(uid));
});

/// Paginated booking history for the current service provider.
final incomingBookingHistoryProvider = StateNotifierProvider.autoDispose<
    PaginatedBookingHistoryNotifier, AsyncValue<BookingHistoryState>>((ref) {
  final uid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
  final datasource = ref.watch(bookingDatasourceProvider);
  return PaginatedBookingHistoryNotifier(
      () => datasource.providerBookingsQuery(uid));
});
