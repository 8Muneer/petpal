import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/notifications/data/models/app_notification_model.dart';

class NotificationRemoteDatasource {
  final FirebaseFirestore _db;

  NotificationRemoteDatasource(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  Stream<List<AppNotificationModel>> watchNotifications(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) {
      try {
        return snap.docs
            .map((doc) => AppNotificationModel.fromFirestore(doc))
            .toList();
      } catch (e, st) {
        // Keep error visibility (no user content), rethrow so the UI's
        // error state shows instead of silently swallowing a mapping failure.
        debugPrint('[NotificationRemoteDatasource] mapping error: $e\n$st');
        rethrow;
      }
    });
  }

  /// Live count of unread notifications, capped at 10. The UI never shows an
  /// exact number above 9 (it renders "9+"), so counting past 10 would just be
  /// wasted reads. Crucially this is a *separate* query from watchNotifications'
  /// 50-doc display window — the bell badge previously derived its count from
  /// that window, so unread notifications older than the most-recent 50 were
  /// silently missed (and the "mark all read" button could vanish while unread
  /// items still existed). Equality-only filters on userId+isRead need no
  /// composite index — the same query markAllAsRead already relies on.
  Stream<int> watchUnreadCount(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs.length);
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
