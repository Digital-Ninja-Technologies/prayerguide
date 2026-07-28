import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/reading_plan_progress.dart';
import '../data/repositories/reading_plan_repository.dart';
import 'repo_providers.dart';

final readingPlanRepositoryProvider = Provider((ref) => ReadingPlanRepository());

class ReadingPlanNotifier extends AsyncNotifier<List<ReadingPlanProgress>> {
  @override
  Future<List<ReadingPlanProgress>> build() {
    ref.watch(currentUserIdProvider);
    return ref.read(readingPlanRepositoryProvider).fetchAll();
  }

  Future<void> markDayComplete({required String planKey, required int totalDays}) async {
    final repo = ref.read(readingPlanRepositoryProvider);
    final updated = await repo.markDayComplete(planKey: planKey, totalDays: totalDays);
    final current = state.value ?? [];
    state = AsyncData([
      updated,
      ...current.where((p) => p.planKey != planKey),
    ]);
  }

  int daysCompletedFor(String planKey) {
    final entries = state.value ?? [];
    for (final p in entries) {
      if (p.planKey == planKey) return p.daysCompleted;
    }
    return 0;
  }
}

final readingPlanProvider = AsyncNotifierProvider<ReadingPlanNotifier, List<ReadingPlanProgress>>(
  ReadingPlanNotifier.new,
);
