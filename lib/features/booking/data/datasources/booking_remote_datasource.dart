import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/booking/data/models/booking_request_model.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';

class BookingRemoteDatasource {
  final FirebaseFirestore _firestore;

  BookingRemoteDatasource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference get _col => _firestore.collection('booking_requests');

  Stream<List<BookingRequestModel>> watchOwnerBookings(String ownerUid) {
    return _col
        .where('ownerUid', isEqualTo: ownerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BookingRequestModel.fromFirestore(d))
            .toList());
  }

  Stream<List<BookingRequestModel>> watchProviderBookings(String providerUid) {
    return _col
        .where('providerUid', isEqualTo: providerUid)
        .orderBy('createdAt', descending: true)
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

  Future<void> cancelBooking(String bookingId) async {
    await _col.doc(bookingId).update({'status': BookingStatus.cancelled.name});
  }
}
