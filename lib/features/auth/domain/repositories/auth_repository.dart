import 'package:fpdart/fpdart.dart';
import 'package:petpal/core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> signOut();
}
