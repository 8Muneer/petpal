import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/booking/data/datasources/booking_remote_datasource.dart';
import 'package:petpal/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';
import 'package:petpal/features/booking/domain/repositories/booking_repository.dart';

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
