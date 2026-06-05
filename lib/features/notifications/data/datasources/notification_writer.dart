import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Writes a notification document directly from the client.
/// Failures are swallowed — notifications are non-critical.
Future<void> writeClientNotification(
  FirebaseFirestore db, {
  required String userId,
  required String title,
  required String body,
  required String type,
  Map<String, dynamic> data = const {},
}) async {
  debugPrint('[NotificationWriter] writeClientNotification called: userId=$userId, title=$title, body=$body, type=$type, data=$data');
  if (userId.isEmpty) {
    debugPrint('[NotificationWriter] ABORTED: userId is empty');
    return;
  }
  try {
    final docRef = await db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'data': data,
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[NotificationWriter] SUCCESS: written notification doc ID = ${docRef.id}');
  } catch (e, st) {
    debugPrint('[NotificationWriter] FAILED to write notification: $e\n$st');
  }
}
