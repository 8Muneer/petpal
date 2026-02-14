import 'package:fpdart/fpdart.dart';
import 'package:petpal/core/error/failures.dart';
import 'package:petpal/features/auth/domain/entities/app_user.dart';
import 'package:petpal/features/auth/domain/repositories/auth_repository.dart';

class SignIn {
  final AuthRepository repository;

  const SignIn(this.repository);

  Future<Either<Failure, AppUser>> call({
    required String email,
    required String password,
  }) {
    return repository.signIn(email: email, password: password);
  }
}
