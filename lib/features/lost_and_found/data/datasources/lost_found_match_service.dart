import 'package:petpal/features/lost_and_found/data/datasources/gemini_matching_service.dart';
import 'package:petpal/features/lost_and_found/data/datasources/lost_found_remote_datasource.dart';
import 'package:petpal/features/lost_and_found/data/models/lost_found_post_model.dart';

class LostFoundMatchService {
  final LostFoundRemoteDatasource _datasource;
  final GeminiMatchingService _gemini;

  LostFoundMatchService({
    required LostFoundRemoteDatasource datasource,
    required GeminiMatchingService gemini,
  })  : _datasource = datasource,
        _gemini = gemini;

  /// Called after a new post is created. Finds potential matches using
  /// Phase 1 (metadata filter) then Phase 2 (Gemini visual comparison).
  Future<void> runMatching(LostFoundPostModel newPost) async {
    // Phase 1: metadata filter — same species, opposite type, last 30 days
    final candidates = await _datasource.getOppositeTypePosts(
      newPost.type,
      newPost.species,
    );

    for (final candidate in candidates) {
      // Phase 2: Gemini visual comparison
      final result = await _gemini.compareImages(
        newPost.imageUrl,
        candidate.imageUrl,
      );

      if (result == null) continue;
      if (!result.isMatch || result.confidence < 60) continue;

      // Save match on the new post
      final matchForNew = LostFoundMatchModel(
        postId: candidate.id,
        imageUrl: candidate.imageUrl,
        reporterName: candidate.reporterName,
        confidence: result.confidence,
        reason: result.reason,
      );
      await _datasource.addMatch(newPost.id, matchForNew.toMap());

      // Save reverse match on the candidate post
      final matchForCandidate = LostFoundMatchModel(
        postId: newPost.id,
        imageUrl: newPost.imageUrl,
        reporterName: newPost.reporterName,
        confidence: result.confidence,
        reason: result.reason,
      );
      await _datasource.addMatch(candidate.id, matchForCandidate.toMap());
    }
  }
}
