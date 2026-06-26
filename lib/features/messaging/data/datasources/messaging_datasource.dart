import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/notifications/data/datasources/notification_writer.dart';

class MessagingDatasource {
  final FirebaseFirestore _db;

  MessagingDatasource({required FirebaseFirestore db}) : _db = db;

  CollectionReference get _conversations => _db.collection('conversations');

  /// A deterministic, order-independent ID for the 1:1 conversation between
  /// two UIDs. Using this as the document ID (instead of an auto-ID reached
  /// via a "does a conversation with this pair already exist?" query) means
  /// there's nothing to race: two concurrent calls for the same pair always
  /// target the same document, so they can't create two separate threads.
  String _pairKey(String a, String b) => ([a, b]..sort()).join('_');

  // ── Conversations ────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchConversations(String uid) {
    return _conversations
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
            .toList());
  }

  Future<String> getOrCreateConversation({
    required String myUid,
    required String myName,
    required String otherUid,
    required String otherName,
    String myPhotoUrl = '',
    String otherPhotoUrl = '',
  }) async {
    final convoRef = _conversations.doc(_pairKey(myUid, otherUid));
    final snap = await convoRef.get();

    if (snap.exists) {
      // Refresh cached photo URLs in case either changed since creation.
      if (myPhotoUrl.isNotEmpty || otherPhotoUrl.isNotEmpty) {
        await convoRef.update({
          'participantPhotoUrls.$myUid': myPhotoUrl,
          'participantPhotoUrls.$otherUid': otherPhotoUrl,
        });
      }
      return convoRef.id;
    }

    try {
      await convoRef.set({
        'participants': [myUid, otherUid],
        'participantNames': {myUid: myName, otherUid: otherName},
        'participantPhotoUrls': {myUid: myPhotoUrl, otherUid: otherPhotoUrl},
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'unreadCounts': {myUid: 0, otherUid: 0},
      });
    } on FirebaseException catch (e) {
      // Another concurrent call for this same pair won the race and created
      // the document first — since the ID is deterministic, it's the exact
      // same conversation either way, so this isn't an error worth surfacing.
      if (e.code != 'permission-denied') rethrow;
    }
    return convoRef.id;
  }

  // ── Messages ─────────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limitToLast(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
    String senderPhotoUrl = '',
  }) async {
    final convoRef = _conversations.doc(conversationId);

    // Read the conversation once up front to find the recipient — needed both
    // to bump their unread count in the same batch as the message write, and
    // to notify them afterward, instead of reading the document twice.
    final convoSnap = await convoRef.get();
    final convoData = convoSnap.data() as Map<String, dynamic>?;
    final participants = List<String>.from(convoData?['participants'] ?? []);
    final recipientId =
        participants.firstWhere((p) => p != senderId, orElse: () => '');

    final batch = _db.batch();

    final msgRef = convoRef.collection('messages').doc();

    batch.set(msgRef, {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'text': text,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
    });

    final convoUpdate = <String, dynamic>{
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    };
    if (recipientId.isNotEmpty) {
      convoUpdate['unreadCounts.$recipientId'] = FieldValue.increment(1);
    }
    batch.update(convoRef, convoUpdate);

    await batch.commit();

    if (recipientId.isNotEmpty) {
      // Notify the other participant — fire-and-forget
      _sendMessageNotification(conversationId, recipientId, senderName, text)
          .ignore();
    }
  }

  Future<void> _sendMessageNotification(String conversationId,
      String recipientId, String senderName, String text) async {
    try {
      await writeClientNotification(
        _db,
        userId: recipientId,
        title: senderName,
        body: text.length > 80 ? text.substring(0, 80) : text,
        type: 'newMessage',
        data: {'conversationId': conversationId, 'otherName': senderName},
      );
    } catch (_) {}
  }

  /// Sends a context card message (request/service details) without updating lastMessage.
  Future<void> sendContextMessage({
    required String conversationId,
    required String senderId,
    required Map<String, dynamic> metadata,
  }) async {
    await _conversations
        .doc(conversationId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'senderName': '',
      'text': '',
      'type': 'context',
      'metadata': metadata,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markRead(String conversationId, String uid) async {
    await _conversations.doc(conversationId).update({
      'unreadCounts.$uid': 0,
    });
  }

  Future<void> deleteMessage(String conversationId, String messageId) async {
    final convoRef = _conversations.doc(conversationId);
    final messagesRef = convoRef.collection('messages');
    final msgRef = messagesRef.doc(messageId);

    final msgSnap = await msgRef.get();
    final deletedData = msgSnap.data();

    await msgRef.delete();

    if (deletedData == null || deletedData['type'] == 'context') return;

    // If the deleted message was the one currently shown as the conversation's
    // last-message preview, recompute the preview from what's left — otherwise
    // the chat list keeps showing text for a message that no longer exists.
    final convoSnap = await convoRef.get();
    final convoData = convoSnap.data() as Map<String, dynamic>?;
    if (convoData == null) return;

    final deletedTimestamp = deletedData['timestamp'] as Timestamp?;
    final lastMessageAt = convoData['lastMessageAt'] as Timestamp?;
    final wasLastMessage = deletedTimestamp != null &&
        lastMessageAt != null &&
        deletedTimestamp == lastMessageAt;
    if (!wasLastMessage) return;

    final recent = await messagesRef
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();
    Map<String, dynamic>? replacement;
    for (final doc in recent.docs) {
      final data = doc.data();
      if (data['type'] != 'context') {
        replacement = data;
        break;
      }
    }

    await convoRef.update({
      'lastMessage': replacement?['text'] as String? ?? '',
      'lastMessageAt': replacement?['timestamp'],
    });
  }
}
