import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/reviews/data/datasources/reviews_remote_datasource.dart';
import 'package:petpal/features/reviews/data/repositories/reviews_repository_impl.dart';
import 'package:petpal/features/reviews/domain/entities/review_entity.dart';
import 'package:petpal/features/reviews/domain/repositories/reviews_repository.dart';

final reviewsRemoteDataSourceProvider = Provider<ReviewsRemoteDataSource>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestoreReviewsDataSource(firestore);
});

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  final remoteDataSource = ref.watch(reviewsRemoteDataSourceProvider);
  return ReviewsRepositoryImpl(remoteDataSource);
});

final reviewsForUserProvider = FutureProvider.family<List<ReviewEntity>, String>((ref, userId) async {
  final repository = ref.watch(reviewsRepositoryProvider);
  return repository.getReviewsForUser(userId);
});
