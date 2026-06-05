import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/features/admin/data/repositories/admin_repository.dart';
import 'package:petpal/features/admin/data/repositories/moderation_repository.dart';
import 'package:petpal/features/admin/domain/entities/verification_request.dart';
import 'package:petpal/features/admin/domain/entities/report_model.dart';

/// Aggregate counts for the dashboard KPI strip (users, POIs, etc.).
final adminStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) {
  return ref.watch(adminRepositoryProvider).getAdminStats();
});

/// Live queue of provider verification requests awaiting review.
final pendingVerificationsProvider =
    StreamProvider.autoDispose<List<VerificationRequest>>((ref) {
  return ref.watch(adminRepositoryProvider).watchPendingVerifications();
});

/// Live queue of open content reports awaiting moderation.
final openReportsProvider =
    StreamProvider.autoDispose<List<ContentReport>>((ref) {
  return ref.watch(moderationRepositoryProvider).watchOpenReports();
});
