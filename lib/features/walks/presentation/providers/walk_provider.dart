import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/walks/data/datasources/walk_image_service.dart';
import 'package:petpal/features/walks/data/datasources/walk_remote_datasource.dart';
import 'package:petpal/features/walks/data/repositories/walk_repository_impl.dart';
import 'package:petpal/features/walks/domain/entities/walk_request.dart';
import 'package:petpal/features/walks/domain/repositories/walk_repository.dart';

final walkDatasourceProvider = Provider<WalkRemoteDatasource>((ref) {
  return WalkRemoteDatasource(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final walkRepositoryProvider = Provider<WalkRepository>((ref) {
  return WalkRepositoryImpl(ref.watch(walkDatasourceProvider));
});

final walkRequestsProvider = StreamProvider<List<WalkRequest>>((ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  final uid = userAsync.asData?.value?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();

  final datasource = ref.watch(walkDatasourceProvider);
  return datasource.watchRequests(uid).map((requests) {
    final sorted = [...requests];
    sorted.sort((a, b) {
      final aTime = a.createdAt ?? DateTime(0);
      final bTime = b.createdAt ?? DateTime(0);
      return bTime.compareTo(aTime);
    });
    return sorted;
  });
});

final walkImageServiceProvider = Provider<WalkImageService>((ref) {
  return WalkImageService(storage: FirebaseStorage.instance);
});
