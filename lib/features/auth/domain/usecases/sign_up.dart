import 'package:fpdart/fpdart.dart';
import 'package:petpal/core/error/failures.dart';
import 'package:petpal/features/auth/domain/entities/app_user.dart';
import 'package:petpal/features/auth/domain/enums/user_role.dart';
import 'package:petpal/features/auth/domain/repositories/auth_repository.dart';

class SignUp {
  final AuthRepository repository;

  const SignUp(this.repository);

  Future<Either<Failure, AppUser>> call({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) {
    return repository.signUp(
      name: name,
      email: email,
      password: password,
      role: role,
    );
  }
}
