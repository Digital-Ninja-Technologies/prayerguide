import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/fasting_session.dart';
import '../data/repositories/fasting_repository.dart';
import 'repo_providers.dart';

final fastingRepositoryProvider = Provider((ref) => FastingRepository());

class FastingState {
  const FastingState({this.session, this.prayerSessionCount = 0, this.journalNoteCount = 0});
  final FastingSession? session;
  final int prayerSessionCount;
  final int journalNoteCount;
}

class FastingNotifier extends AsyncNotifier<FastingState> {
  @override
  Future<FastingState> build() async {
    ref.watch(currentUserIdProvider);
    final repo = ref.read(fastingRepositoryProvider);
    final session = await repo.fetchActive();
    if (session == null) return const FastingState();
    final prayerCount = await repo.countPrayerSessionsSince(session.startedAt);
    final journalCount = await repo.countJournalEntriesSince(session.startedAt);
    return FastingState(session: session, prayerSessionCount: prayerCount, journalNoteCount: journalCount);
  }

  Future<void> start(double targetHours) async {
    final repo = ref.read(fastingRepositoryProvider);
    await repo.start(targetHours);
    ref.invalidateSelf();
    await future;
  }

  Future<void> end() async {
    final repo = ref.read(fastingRepositoryProvider);
    final session = state.value?.session;
    if (session == null) return;
    await repo.end(session.id);
    state = const AsyncData(FastingState());
  }
}

final fastingProvider = AsyncNotifierProvider<FastingNotifier, FastingState>(FastingNotifier.new);
