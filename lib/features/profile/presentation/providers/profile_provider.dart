import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/profile/data/datasources/profile_image_service.dart';
import 'package:petpal/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:petpal/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:petpal/features/profile/domain/entities/user_profile.dart';
import 'package:petpal/features/profile/domain/repositories/profile_repository.dart';

final profileDatasourceProvider = Provider<ProfileRemoteDatasource>((ref) {
  return ProfileRemoteDatasource(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileDatasourceProvider));
});

final profileStreamProvider =
    StreamProvider.family<UserProfile?, String>((ref, uid) {
  final datasource = ref.watch(profileDatasourceProvider);
  return datasource.watchProfile(uid);
});

final profileImageServiceProvider = Provider<ProfileImageService>((ref) {
  return ProfileImageService(storage: FirebaseStorage.instance);
});

final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.valueOrNull;
  if (user == null) return Stream.value(null);
  final datasource = ref.watch(profileDatasourceProvider);
  return datasource.watchProfile(user.uid);
});
