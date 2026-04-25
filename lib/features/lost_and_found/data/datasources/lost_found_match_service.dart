import 'package:flutter/foundation.dart';
import 'package:petpal/features/lost_and_found/data/datasources/gemini_matching_service.dart';
import 'package:petpal/features/lost_and_found/data/datasources/lost_found_remote_datasource.dart';
import 'package:petpal/features/lost_and_found/data/models/lost_found_post_model.dart';
import 'package:petpal/features/lost_and_found/domain/entities/lost_found_post.dart';

class LostFoundMatchService {
  final LostFoundRemoteDatasource _datasource;
  final GeminiMatchingService _gemini;

  LostFoundMatchService({
    required LostFoundRemoteDatasource datasource,
    required GeminiMatchingService gemini,
  })  : _datasource = datasource,
        _gemini = gemini;

  Future<void> runMatching(LostFoundPostModel post) async {
    try {
      debugPrint('[Match] Starting for post ${post.id} type=${post.type} species=${post.species}');
      await _datasource.updateMatchingStatus(post.id, MatchingStatus.searching);

      final candidates = await _datasource.getOppositeTypePosts(
        post.type,
        post.species,
      );
      debugPrint('[Match] Found ${candidates.length} candidates');

      for (final candidate in candidates) {
        if (candidate.imageUrl.isEmpty) continue;
        debugPrint('[Match] Comparing with candidate ${candidate.id}');

        final result = await _gemini.compareImages(
          post.imageUrl,
          candidate.imageUrl,
        );

        debugPrint('[Match] Result: ${result?.confidence}% match=${result?.isMatch}');
        if (result == null) continue;
        if (!result.isMatch || result.confidence < 50) continue;

        final matchForNew = LostFoundMatchModel(
          postId: candidate.id,
          imageUrl: candidate.imageUrl,
          reporterName: candidate.reporterName,
          confidence: result.confidence,
          reason: result.reason,
        );
        await _datasource.addMatch(post.id, matchForNew.toMap());

        final matchForCandidate = LostFoundMatchModel(
          postId: post.id,
          imageUrl: post.imageUrl,
          reporterName: post.reporterName,
          confidence: result.confidence,
          reason: result.reason,
        );
        await _datasource.addMatch(candidate.id, matchForCandidate.toMap());
        debugPrint('[Match] Saved match between ${post.id} and ${candidate.id}');
      }
    } catch (e, st) {
      debugPrint('[Match] ERROR: $e\n$st');
    } finally {
      await _datasource.updateMatchingStatus(post.id, MatchingStatus.done);
      debugPrint('[Match] Done for post ${post.id}');
    }
  }

  /// One-off comparison between two specific posts — used for manual compare.
  Future<GeminiMatchResult?> compareTwo(
      LostFoundPostModel a, LostFoundPostModel b) async {
    return _gemini.compareImages(a.imageUrl, b.imageUrl);
  }
}
