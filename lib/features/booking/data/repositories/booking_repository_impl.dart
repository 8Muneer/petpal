import 'package:petpal/features/booking/data/datasources/booking_remote_datasource.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';
import 'package:petpal/features/booking/domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDatasource _datasource;

  BookingRepositoryImpl(this._datasource);

  @override
  Stream<List<BookingRequest>> watchOwnerBookings(String ownerUid) =>
      _datasource.watchOwnerBookings(ownerUid);

  @override
  Stream<List<BookingRequest>> watchProviderBookings(String providerUid) =>
      _datasource.watchProviderBookings(providerUid);

  @override
  Future<String> createBooking(Map<String, dynamic> data) =>
      _datasource.createBooking(data);

  @override
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    String? providerNote,
  }) =>
      _datasource.updateBookingStatus(bookingId, status,
          providerNote: providerNote);

  @override
  Future<void> cancelBooking(String bookingId) =>
      _datasource.cancelBooking(bookingId);
}
