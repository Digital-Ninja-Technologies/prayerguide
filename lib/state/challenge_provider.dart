import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/challenge_progress.dart';
import '../data/repositories/challenge_repository.dart';
import 'repo_providers.dart';

final challengeRepositoryProvider = Provider((ref) => ChallengeRepository());

class ChallengeNotifier extends AsyncNotifier<List<ChallengeProgress>> {
  @override
  Future<List<ChallengeProgress>> build() {
    ref.watch(currentUserIdProvider);
    return ref.read(challengeRepositoryProvider).fetchAll();
  }

  /// The most recently started challenge for [challengeKey], if any.
  ChallengeProgress? forKey(String challengeKey) {
    ChallengeProgress? best;
    for (final p in state.value ?? const <ChallengeProgress>[]) {
      if (p.challengeKey == challengeKey) {
        if (best == null || p.startedAt.isAfter(best.startedAt)) best = p;
      }
    }
    return best;
  }

  /// The most recently started challenge that's still active and not
  /// finished — shown as the "in progress" card on the Challenges list.
  ChallengeProgress? get mostRecentActive {
    final active = (state.value ?? const <ChallengeProgress>[])
        .where((p) => p.active && p.currentDay < p.totalDays)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return active.isEmpty ? null : active.first;
  }

  /// Starts [challengeKey] if it hasn't been started yet, then marks the
  /// next day complete either way — a single tap means "I'm doing today's
  /// session", consistent with the design's one-button Continue/Start CTA.
  Future<ChallengeProgress> startOrAdvance({
    required String challengeKey,
    required String name,
    required int totalDays,
  }) async {
    final repo = ref.read(challengeRepositoryProvider);
    final existing = forKey(challengeKey);
    final current = state.value ?? const <ChallengeProgress>[];

    if (existing == null) {
      final created = await repo.start(challengeKey: challengeKey, name: name, totalDays: totalDays);
      final advanced = await repo.markDayComplete(created.id, totalDays);
      state = AsyncData([advanced, ...current]);
      return advanced;
    }

    final advanced = await repo.markDayComplete(existing.id, totalDays);
    state = AsyncData([for (final p in current) if (p.id == existing.id) advanced else p]);
    return advanced;
  }
}

final challengeProvider = AsyncNotifierProvider<ChallengeNotifier, List<ChallengeProgress>>(ChallengeNotifier.new);
