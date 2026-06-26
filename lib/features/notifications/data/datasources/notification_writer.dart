import 'package:cloud_firestore/cloud_firestore.dart';

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
  if (userId.isEmpty) return;
  try {
    await db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'data': data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (_) {
    // Non-critical — notifications are best-effort.
  }
}
