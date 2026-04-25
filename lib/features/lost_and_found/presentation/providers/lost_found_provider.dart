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
    final matchService = ref.read(lostFoundMatchServiceProvider);

    final docId = await datasource.createPost(post.toFirestore());
    final imageUrl = await datasource.uploadImage(docId, imageFile);

    await FirebaseFirestore.instance
        .collection('lost_found_posts')
        .doc(docId)
        .update({'imageUrl': imageUrl});

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

    // Run in background — status updates stream to detail screen automatically
    matchService.runMatching(finalPost);
  };
});

final rerunMatchingProvider =
    Provider<Future<void> Function(LostFoundPost)>((ref) {
  return (post) async {
    final datasource = ref.read(lostFoundDatasourceProvider);
    final matchService = ref.read(lostFoundMatchServiceProvider);

    // Reset status to pending so UI reflects fresh start
    await datasource.updateMatchingStatus(post.id, MatchingStatus.pending);

    final model = LostFoundPostModel(
      id: post.id,
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
      imageUrl: post.imageUrl,
    );

    matchService.runMatching(model);
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
