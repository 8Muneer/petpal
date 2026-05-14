import 'package:petpal/features/community/domain/repositories/karma_repository.dart';

class MockKarmaRepository implements KarmaRepository {
  @override
  Future<int> getCurrentUserKarma(String userId) async {
    return 125;
  }

  @override
  Future<void> incrementKarma(String userId, String postId, int points, String reason) async {
    // Mock success
  }

  @override
  Future<bool> canGiveTreat(String userId, String postId) async {
    return true;
  }

  @override
  Future<bool> checkDailyLimit(String userId) async {
    return true;
  }
}
