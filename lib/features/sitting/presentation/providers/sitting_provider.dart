import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/sitting/data/datasources/sitting_image_service.dart';
import 'package:petpal/features/sitting/data/datasources/sitting_remote_datasource.dart';
import 'package:petpal/features/sitting/data/repositories/sitting_repository_impl.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_service.dart';
import 'package:petpal/features/sitting/domain/repositories/sitting_repository.dart';
import 'package:rxdart/rxdart.dart';

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

final assignedSittingRequestsProvider = StreamProvider<List<SittingRequest>>((ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  final uid = userAsync.asData?.value?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();

  final datasource = ref.watch(sittingDatasourceProvider);
  return datasource.watchAssignedRequests(uid).map((requests) {
    final sorted = [...requests];
    sorted.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return sorted;
  });
});

final sittingImageServiceProvider = Provider<SittingImageService>((ref) {
  return SittingImageService(storage: FirebaseStorage.instance);
});

final openSittingRequestsProvider = StreamProvider<List<SittingRequest>>((ref) {
  final datasource = ref.watch(sittingDatasourceProvider);
  return datasource.watchPublicRequests().map((requests) {
    final sorted = [...requests];
    sorted.sort((a, b) {
      final aTime = a.createdAt ?? DateTime(0);
      final bTime = b.createdAt ?? DateTime(0);
      return bTime.compareTo(aTime);
    });
    return sorted;
  });
});

final sittingServicesProvider = StreamProvider<List<SittingService>>((ref) {
  final datasource = ref.watch(sittingDatasourceProvider);
  return datasource.watchSittingServices().map((services) {
    final sorted = [...services];
    sorted.sort((a, b) {
      final aTime = a.createdAt ?? DateTime(0);
      final bTime = b.createdAt ?? DateTime(0);
      return bTime.compareTo(aTime);
    });
    return sorted;
  });
});

final mySittingServicesProvider = StreamProvider<List<SittingService>>((ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  final uid = userAsync.asData?.value?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  final datasource = ref.watch(sittingDatasourceProvider);
  return datasource.watchMyServices(uid).map((services) {
    final sorted = [...services];
    sorted.sort((a, b) {
      final aTime = a.createdAt ?? DateTime(0);
      final bTime = b.createdAt ?? DateTime(0);
      return bTime.compareTo(aTime);
    });
    return sorted;
  });
});

final combinedSittingBookingsProvider = StreamProvider<List<SittingRequest>>((ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  final uid = userAsync.asData?.value?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();

  final repository = ref.watch(sittingRepositoryProvider);
  
  return Rx.combineLatest2(
    repository.watchRequests(uid),
    repository.watchAssignedRequests(uid),
    (owned, assigned) {
      final combined = [...owned, ...assigned];
      // Unique by ID
      final seen = <String>{};
      return combined.where((req) => seen.add(req.id)).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    },
  );
});

final sittingControllerProvider =
    StateNotifierProvider<SittingController, AsyncValue<void>>((ref) {
  return SittingController(ref.watch(sittingRepositoryProvider));
});

class SittingController extends StateNotifier<AsyncValue<void>> {
  final SittingRepository _repository;

  SittingController(this._repository) : super(const AsyncValue.data(null));

  Future<void> acceptRequest(String requestId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateRequestStatus(requestId, SittingStatus.taken);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refuseRequest(String requestId, String reason) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateRequestStatus(
        requestId,
        SittingStatus.declined,
        refusalReason: reason,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
