import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/booking/data/models/booking_request_model.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';

/// Firestore CRUD for booking requests.
///
/// Notifications for the booking lifecycle are NOT written here — they are
/// written server-side by the `onBookingCreate` and `onBookingStatusChange`
/// Cloud Functions (see functions/index.js). Writing them client-side too
/// would double every notification, so this layer only mutates the booking
/// document and lets the triggers fan out the notifications.
class BookingRemoteDatasource {
  final FirebaseFirestore _firestore;

  BookingRemoteDatasource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference get _col => _firestore.collection('booking_requests');

  /// Upper bound on how many bookings a single stream fetches. Ordered by
  /// createdAt desc, so this keeps the most recent ones and stops the query
  /// (and the widget list) from growing without limit as history piles up.
  static const int _bookingsLimit = 200;

  Stream<List<BookingRequestModel>> watchOwnerBookings(String ownerUid) {
    return _col
        .where('ownerUid', isEqualTo: ownerUid)
        .orderBy('createdAt', descending: true)
        .limit(_bookingsLimit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BookingRequestModel.fromFirestore(d))
            .toList());
  }

  /// Cursor-paginated query for the owner's booking history tab — same
  /// underlying data as [watchOwnerBookings] but as a plain [Query] (no
  /// `.limit()`/`.snapshots()`) so callers can chain `.limit()` and
  /// `.startAfterDocument()` for page-based loading.
  Query ownerBookingsQuery(String ownerUid) {
    return _col
        .where('ownerUid', isEqualTo: ownerUid)
        .orderBy('createdAt', descending: true);
  }

  /// Cursor-paginated query for the provider's booking history tab — mirrors
  /// [ownerBookingsQuery] for the provider side.
  Query providerBookingsQuery(String providerUid) {
    return _col
        .where('providerUid', isEqualTo: providerUid)
        .orderBy('createdAt', descending: true);
  }

  Stream<List<BookingRequestModel>> watchProviderBookings(String providerUid) {
    return _col
        .where('providerUid', isEqualTo: providerUid)
        .orderBy('createdAt', descending: true)
        .limit(_bookingsLimit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BookingRequestModel.fromFirestore(d))
            .toList());
  }

  Future<String> createBooking(Map<String, dynamic> data) async {
    final doc = await _col.add(data);
    return doc.id;
  }

  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    String? providerNote,
  }) async {
    final update = <String, dynamic>{'status': status.name};
    if (providerNote != null) update['providerNote'] = providerNote;
    await _col.doc(bookingId).update(update);
  }

  /// Owner cancels — `cancelledBy` lets the onBookingStatusChange Cloud Function
  /// notify the right party, since a Firestore trigger has no way to know which
  /// authenticated user made the write that fired it.
  Future<void> cancelBooking(String bookingId) async {
    await _col.doc(bookingId).update({
      'status': BookingStatus.cancelled.name,
      'cancelledBy': 'owner',
    });
  }

  /// Provider backs out of a booking they already accepted.
  Future<void> cancelBookingByProvider(String bookingId) async {
    await _col.doc(bookingId).update({
      'status': BookingStatus.cancelled.name,
      'cancelledBy': 'provider',
    });
  }

  /// Owner rejects the provider's completion request — status returns to `accepted`.
  Future<void> disputeCompletion(String bookingId) async {
    await _col.doc(bookingId).update({'status': BookingStatus.accepted.name});
  }
}
