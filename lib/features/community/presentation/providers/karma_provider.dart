import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/features/community/domain/entities/karma_transaction.dart';
import 'package:petpal/features/community/domain/repositories/karma_repository.dart';
import 'package:petpal/features/community/presentation/providers/community_provider.dart';

class KarmaState {
  final int totalKarma;
  final List<KarmaTransaction> history;
  final bool isLoading;

  KarmaState({
    this.totalKarma = 0,
    this.history = const [],
    this.isLoading = false,
  });

  KarmaState copyWith({
    int? totalKarma,
    List<KarmaTransaction>? history,
    bool? isLoading,
  }) {
    return KarmaState(
      totalKarma: totalKarma ?? this.totalKarma,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class KarmaNotifier extends StateNotifier<KarmaState> {
  final KarmaRepository _repository;
  final String _currentUserId = 'current_user';

  KarmaNotifier(this._repository) : super(KarmaState()) {
    loadKarma();
  }

  Future<void> loadKarma() async {
    state = state.copyWith(isLoading: true);
    try {
      final karma = await _repository.getCurrentUserKarma(_currentUserId);
      state = state.copyWith(
        totalKarma: karma,
        isLoading: false,
        // In a real app, we'd also load history from ledger
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addKarma(int points, KarmaReason reason, {String? postId, String? description}) async {
    try {
      // Security Check: Daily Limit
      final underLimit = await _repository.checkDailyLimit(_currentUserId);
      if (!underLimit && points > 0) return;

      await _repository.incrementKarma(
        _currentUserId, 
        postId ?? 'manual', 
        points, 
        reason.toString().split('.').last,
      );
      
      // Update local state
      state = state.copyWith(
        totalKarma: state.totalKarma + points,
        // (Optional: prepend new transaction to history)
      );
    } catch (e) {
      // Rollback or handle error
    }
  }
}

final karmaProvider = StateNotifierProvider<KarmaNotifier, KarmaState>((ref) {
  final repository = ref.watch(karmaRepositoryProvider);
  return KarmaNotifier(repository);
});
