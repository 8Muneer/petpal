import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/lost_and_found/data/datasources/gemini_matching_service.dart';
import 'package:petpal/features/lost_and_found/data/datasources/lost_found_match_service.dart';
import 'package:petpal/features/lost_and_found/data/datasources/lost_found_remote_datasource.dart';
import 'package:petpal/features/lost_and_found/data/models/lost_found_post_model.dart';
import 'package:petpal/features/lost_and_found/domain/entities/lost_found_post.dart';

final lostFoundDatasourceProvider = Provider<LostFoundRemoteDatasource>((ref) {
  return LostFoundRemoteDatasource(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
});

final geminiServiceProvider = Provider<GeminiMatchingService>((ref) {
  return GeminiMatchingService();
});

final lostFoundMatchServiceProvider = Provider<LostFoundMatchService>((ref) {
  return LostFoundMatchService(
    datasource: ref.watch(lostFoundDatasourceProvider),
    gemini: ref.watch(geminiServiceProvider),
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

final createLostFoundPostProvider =
    Provider<Future<void> Function(LostFoundPostModel, XFile)>((ref) {
  return (post, imageFile) async {
    final datasource = ref.read(lostFoundDatasourceProvider);
    final matchService = ref.read(lostFoundMatchServiceProvider);

    // 1. Create a placeholder to get the document ID
    final docId = await datasource.createPost(post.toFirestore());

    // 2. Upload image
    final imageUrl = await datasource.uploadImage(docId, imageFile);

    // 3. Update post with imageUrl
    await FirebaseFirestore.instance
        .collection('lost_found_posts')
        .doc(docId)
        .update({'imageUrl': imageUrl});

    // 4. Build final model for matching
    final finalPost = LostFoundPostModel(
      id: docId,
      reporterUid: post.reporterUid,
      reporterName: post.reporterName,
      reporterPhotoUrl: post.reporterPhotoUrl,
      type: post.type,
      petName: post.petName,
      species: post.species,
      breed: post.breed,
      color: post.color,
      description: post.description,
      area: post.area,
      imageUrl: imageUrl,
    );

    // 5. Run AI matching in background (don't await — let it complete async)
    matchService.runMatching(finalPost);
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
String? get currentUserPhoto =>
    FirebaseAuth.instance.currentUser?.photoURL;
