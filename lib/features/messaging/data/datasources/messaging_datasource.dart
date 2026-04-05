import 'package:cloud_firestore/cloud_firestore.dart';

class MessagingDatasource {
  final FirebaseFirestore _db;

  MessagingDatasource({required FirebaseFirestore db}) : _db = db;

  CollectionReference get _conversations => _db.collection('conversations');

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
    // Check if conversation already exists
    final existing = await _conversations
        .where('participants', arrayContains: myUid)
        .get();

    for (final doc in existing.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] ?? []);
      if (participants.contains(otherUid)) {
        // Update photo URLs in case they changed
        if (myPhotoUrl.isNotEmpty || otherPhotoUrl.isNotEmpty) {
          await doc.reference.update({
            'participantPhotoUrls.$myUid': myPhotoUrl,
            'participantPhotoUrls.$otherUid': otherPhotoUrl,
          });
        }
        return doc.id;
      }
    }

    // Create new conversation
    final doc = await _conversations.add({
      'participants': [myUid, otherUid],
      'participantNames': {myUid: myName, otherUid: otherName},
      'participantPhotoUrls': {myUid: myPhotoUrl, otherUid: otherPhotoUrl},
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'unreadCounts': {myUid: 0, otherUid: 0},
    });
    return doc.id;
  }

  // ── Messages ─────────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
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
    final batch = _db.batch();

    final msgRef = _conversations
        .doc(conversationId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'text': text,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
    });

    batch.update(_conversations.doc(conversationId), {
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
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
    await _conversations
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }
}
