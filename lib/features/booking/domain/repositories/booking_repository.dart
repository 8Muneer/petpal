import 'package:petpal/features/booking/domain/entities/booking_request.dart';

abstract class BookingRepository {
  Stream<List<BookingRequest>> watchOwnerBookings(String ownerUid);
  Stream<List<BookingRequest>> watchProviderBookings(String providerUid);
  Future<String> createBooking(Map<String, dynamic> data);
  Future<void> updateBookingStatus(String bookingId, BookingStatus status, {String? providerNote});
  Future<void> cancelBooking(String bookingId);
}
