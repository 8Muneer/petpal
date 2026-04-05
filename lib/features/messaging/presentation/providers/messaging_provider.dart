import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/messaging/data/datasources/messaging_datasource.dart';

final messagingDatasourceProvider = Provider<MessagingDatasource>((ref) {
  return MessagingDatasource(db: ref.watch(firebaseFirestoreProvider));
});

final conversationsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(messagingDatasourceProvider).watchConversations(uid);
});

final messagesProvider = StreamProvider.family<List<Map<String, dynamic>>, String>(
  (ref, conversationId) {
    final uid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
    if (uid.isEmpty) return const Stream.empty();
    return ref.watch(messagingDatasourceProvider).watchMessages(conversationId);
  },
);
