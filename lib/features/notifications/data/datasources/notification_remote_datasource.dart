import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/notifications/data/models/app_notification_model.dart';

class NotificationRemoteDatasource {
  final FirebaseFirestore _db;

  NotificationRemoteDatasource(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  Stream<List<AppNotificationModel>> watchNotifications(String userId) {
    debugPrint('[NotificationRemoteDatasource] watchNotifications initialized for userId: $userId');
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) {
      debugPrint('[NotificationRemoteDatasource] watchNotifications snap received: docCount=${snap.docs.length}');
      try {
        final list = snap.docs.map((doc) {
          debugPrint('[NotificationRemoteDatasource] Notification doc found: id=${doc.id}, data=${doc.data()}');
          return AppNotificationModel.fromFirestore(doc);
        }).toList();
        return list;
      } catch (e, st) {
        debugPrint('[NotificationRemoteDatasource] ERROR mapping notifications: $e\n$st');
        rethrow;
      }
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _col.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    // Firestore batches are capped at 500 writes — paginate in chunks.
    const chunkSize = 500;
    while (true) {
      final snap = await _col
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .limit(chunkSize)
          .get();

      if (snap.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      if (snap.docs.length < chunkSize) return;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    await _col.doc(notificationId).delete();
  }
}
