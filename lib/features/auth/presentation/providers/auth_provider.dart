import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:petpal/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:petpal/features/auth/domain/repositories/auth_repository.dart';

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDatasourceProvider));
});

final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return false;
  
  final doc = await ref.watch(firebaseFirestoreProvider)
      .collection('users')
      .doc(user.uid)
      .get();
      
  final data = doc.data();
  if (data == null) return false;
  
  final role = data['role']?.toString().toLowerCase();
  return role == 'admin';
});
