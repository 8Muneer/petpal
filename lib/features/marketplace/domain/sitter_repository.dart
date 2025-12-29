import 'package:fpdart/fpdart.dart';
import 'package:petpal/core/error/failures.dart';
import 'package:petpal/features/marketplace/domain/sitter_entity.dart';

abstract class SitterRepository {
  Future<Either<Failure, List<SitterEntity>>> getSitters({
    String? category,
    double? maxPrice,
    double? minRating,
  });

  Future<Either<Failure, SitterEntity>> getSitterDetails(String id);
}
