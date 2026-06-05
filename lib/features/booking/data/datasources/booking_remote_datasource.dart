import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:petpal/features/booking/data/models/booking_request_model.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';
import 'package:petpal/features/notifications/data/datasources/notification_writer.dart';

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
    try {
      await writeClientNotification(
        _firestore,
        userId: (data['providerUid'] as String?) ?? '',
        title: 'בקשת הזמנה חדשה',
        body: '${data['ownerName'] ?? 'משתמש'} שלח/ה אליך בקשת הזמנה',
        type: 'bookingNew',
        data: {'bookingId': doc.id},
      );
    } catch (e, st) {
      assert(() {
        debugPrint('[BookingRemoteDatasource] FAILED to write new booking notification: $e\n$st');
        return true;
      }());
    }
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
    _sendStatusNotification(bookingId, status).ignore();
  }

  Future<void> cancelBooking(String bookingId) async {
    await _col.doc(bookingId).update({'status': BookingStatus.cancelled.name});
    _sendStatusNotification(bookingId, BookingStatus.cancelled).ignore();
  }

  Future<void> _sendStatusNotification(
      String bookingId, BookingStatus status) async {
    debugPrint('[BookingRemoteDatasource] _sendStatusNotification called: bookingId=$bookingId, status=$status');
    try {
      final snap = await _col.doc(bookingId).get();
      final d = snap.data() as Map<String, dynamic>?;
      if (d == null) {
        debugPrint('[BookingRemoteDatasource] _sendStatusNotification ABORTED: document data is null');
        return;
      }
      debugPrint('[BookingRemoteDatasource] booking doc ownerUid=${d['ownerUid']}, providerUid=${d['providerUid']}');

      switch (status) {
        case BookingStatus.accepted:
          final targetUserId = (d['ownerUid'] as String?) ?? '';
          debugPrint('[BookingRemoteDatasource] Attempting to send accepted notification to owner: $targetUserId');
          await writeClientNotification(
            _firestore,
            userId: targetUserId,
            title: 'הזמנה אושרה',
            body: '${d['providerName'] ?? 'הנותן שירות'} אישר/ה את ההזמנה שלך',
            type: 'bookingAccepted',
            data: {'bookingId': bookingId},
          );
          break;
        case BookingStatus.declined:
          final targetUserId = (d['ownerUid'] as String?) ?? '';
          debugPrint('[BookingRemoteDatasource] Attempting to send declined notification to owner: $targetUserId');
          await writeClientNotification(
            _firestore,
            userId: targetUserId,
            title: 'הזמנה נדחתה',
            body: '${d['providerName'] ?? 'הנותן שירות'} דחה/תה את ההזמנה שלך',
            type: 'bookingDeclined',
            data: {'bookingId': bookingId},
          );
          break;
        case BookingStatus.cancelled:
          final targetUserId = (d['providerUid'] as String?) ?? '';
          debugPrint('[BookingRemoteDatasource] Attempting to send cancelled notification to provider: $targetUserId');
          await writeClientNotification(
            _firestore,
            userId: targetUserId,
            title: 'הזמנה בוטלה',
            body: '${d['ownerName'] ?? 'בעל החיות'} ביטל/ה את ההזמנה',
            type: 'bookingCancelled',
            data: {'bookingId': bookingId},
          );
          break;
        default:
          debugPrint('[BookingRemoteDatasource] _sendStatusNotification: Unhandled status: $status');
          break;
      }
    } catch (e, st) {
      debugPrint('[BookingRemoteDatasource] FAILED to send status notification ($status): $e\n$st');
    }
  }
}
