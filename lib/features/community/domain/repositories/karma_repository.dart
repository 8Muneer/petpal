abstract class KarmaRepository {
  Future<int> getCurrentUserKarma(String userId);
  Future<void> incrementKarma(String userId, String postId, int points, String reason);
  Future<bool> canGiveTreat(String userId, String postId);
  Future<bool> checkDailyLimit(String userId);
}
