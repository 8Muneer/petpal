import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:petpal/features/auth/domain/user_entity.dart';
import 'package:petpal/features/auth/presentation/auth_providers.dart';

part 'auth_state.g.dart';

@riverpod
class AuthState extends _$AuthState {
  @override
  FutureOr<UserEntity?> build() async {
    return _init();
  }

  Future<UserEntity?> _init() async {
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.getCurrentUser();

    return result.fold(
      (failure) => null, // Or handle error state specifically
      (user) => user,
    );
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.login(email: email, password: password);

    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (user) => AsyncData(user),
    );
  }

  Future<void> signUp(String email, String password, String name) async {
    state = const AsyncLoading();
    final repository = ref.read(authRepositoryProvider);
    final result =
        await repository.signUp(email: email, password: password, name: name);

    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (user) => AsyncData(user),
    );
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.logout();

    result.fold(
      (failure) => state = AsyncError(failure.message, StackTrace.current),
      (_) => state = const AsyncData(null),
    );
  }
}
