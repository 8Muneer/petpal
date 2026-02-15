import 'package:fpdart/fpdart.dart';
import 'package:petpal/core/error/failures.dart';
import 'package:petpal/features/profile/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserProfile>> getProfile(String uid);
  Future<Either<Failure, void>> updateProfile(
      String uid, Map<String, dynamic> data);
  Stream<UserProfile?> watchProfile(String uid);
}
