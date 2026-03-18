import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/sitting/data/datasources/sitting_image_service.dart';
import 'package:petpal/features/sitting/data/datasources/sitting_remote_datasource.dart';
import 'package:petpal/features/sitting/data/repositories/sitting_repository_impl.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart';
import 'package:petpal/features/sitting/domain/repositories/sitting_repository.dart';

final sittingDatasourceProvider = Provider<SittingRemoteDatasource>((ref) {
  return SittingRemoteDatasource(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final sittingRepositoryProvider = Provider<SittingRepository>((ref) {
  return SittingRepositoryImpl(ref.watch(sittingDatasourceProvider));
});

final sittingRequestsProvider = StreamProvider<List<SittingRequest>>((ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  final uid = userAsync.asData?.value?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();

  final datasource = ref.watch(sittingDatasourceProvider);
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

final sittingImageServiceProvider = Provider<SittingImageService>((ref) {
  return SittingImageService(storage: FirebaseStorage.instance);
});
