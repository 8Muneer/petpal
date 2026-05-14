import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/features/community/domain/entities/community_alert.dart';
import 'package:petpal/features/community/presentation/providers/community_provider.dart';

final communityAlertsProvider = FutureProvider.family<List<CommunityAlert>, String>((ref, neighborhood) async {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.getAlerts(neighborhood);
});
