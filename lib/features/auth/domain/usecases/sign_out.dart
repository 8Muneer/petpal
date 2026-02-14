import 'package:fpdart/fpdart.dart';
import 'package:petpal/core/error/failures.dart';
import 'package:petpal/features/auth/domain/repositories/auth_repository.dart';

class SignOut {
  final AuthRepository repository;

  const SignOut(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.signOut();
  }
}
