import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/lost_and_found/data/datasources/lost_found_remote_datasource.dart';
import 'package:petpal/features/lost_and_found/data/models/lost_found_post_model.dart';
import 'package:petpal/features/lost_and_found/domain/entities/lost_found_post.dart';

final lostFoundDatasourceProvider = Provider<LostFoundRemoteDatasource>((ref) {
  return LostFoundRemoteDatasource(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
});

final lostPostsProvider = StreamProvider<List<LostFoundPost>>((ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) return const Stream.empty();
  return ref.watch(lostFoundDatasourceProvider).watchPosts(LostFoundType.lost);
});

final foundPostsProvider = StreamProvider<List<LostFoundPost>>((ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) return const Stream.empty();
  return ref.watch(lostFoundDatasourceProvider).watchPosts(LostFoundType.found);
});

final singlePostProvider =
    StreamProvider.family<LostFoundPost?, String>((ref, postId) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) return const Stream.empty();
  return ref.watch(lostFoundDatasourceProvider).watchPost(postId);
});

final createLostFoundPostProvider =
    Provider<Future<void> Function(LostFoundPostModel, XFile)>((ref) {
  return (post, imageFile) async {
    final datasource = ref.read(lostFoundDatasourceProvider);

    // Generate a client-side document reference to get a secure ID first
    final docRef = FirebaseFirestore.instance.collection('lost_found_posts').doc();
    final docId = docRef.id;

    // Upload image — path is lost_found/<uid>/<postId> (scoped per user)
    final imageUrl = await datasource.uploadImage(post.reporterUid, docId, imageFile);

    // Write full document atomically — the onLostFoundCreate Cloud Function
    // trigger handles matching automatically once this write lands.
    final firestoreData = post.toFirestore();
    firestoreData['imageUrl'] = imageUrl;
    await docRef.set(firestoreData);
  };
});

final rerunMatchingProvider =
    Provider<Future<void> Function(LostFoundPost)>((ref) {
  return (post) async {
    final callable = FirebaseFunctions.instance
        .httpsCallable('rerunLostFoundMatching');
    await callable.call({'postId': post.id});
  };
});

final markResolvedProvider = Provider<Future<void> Function(String)>((ref) {
  return (postId) async {
    await ref.read(lostFoundDatasourceProvider).markResolved(postId);
  };
});

String get currentUserUid => FirebaseAuth.instance.currentUser?.uid ?? '';
String get currentUserName =>
    FirebaseAuth.instance.currentUser?.displayName ?? 'משתמש';
String? get currentUserPhoto => FirebaseAuth.instance.currentUser?.photoURL;
