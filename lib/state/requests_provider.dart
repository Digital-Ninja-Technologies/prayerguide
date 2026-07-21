import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/prayer_request.dart';
import 'repo_providers.dart';

class RequestsNotifier extends AsyncNotifier<List<PrayerRequest>> {
  @override
  Future<List<PrayerRequest>> build() {
    ref.watch(currentUserIdProvider);
    return ref.read(requestsRepositoryProvider).fetchAll();
  }

  Future<void> add({
    required String category,
    required String title,
    String? note,
    bool reminder = false,
  }) async {
    final repo = ref.read(requestsRepositoryProvider);
    final req = await repo.create(category: category, title: title, note: note, reminder: reminder);
    state = AsyncData([req, ...state.value ?? []]);
  }

  Future<void> _patch(String id, Map<String, dynamic> patch, PrayerRequest Function(PrayerRequest) apply) async {
    final repo = ref.read(requestsRepositoryProvider);
    final current = state.value ?? [];
    state = AsyncData([
      for (final r in current) if (r.id == id) apply(r) else r,
    ]);
    await repo.update(id, patch);
  }

  Future<void> toggleReminder(String id) async {
    final r = (state.value ?? []).firstWhere((r) => r.id == id);
    await _patch(id, {'reminder': !r.reminder}, (x) => x.copyWith(reminder: !x.reminder));
  }

  Future<void> markAnswered(String id) async {
    await _patch(id, {'status': 'answered', 'reminder': false},
        (x) => x.copyWith(status: 'answered', reminder: false));
  }

  Future<void> archive(String id) async {
    await _patch(id, {'status': 'archived'}, (x) => x.copyWith(status: 'archived'));
  }

  Future<void> restore(String id) async {
    await _patch(id, {'status': 'active'}, (x) => x.copyWith(status: 'active'));
  }
}

final requestsProvider = AsyncNotifierProvider<RequestsNotifier, List<PrayerRequest>>(
  RequestsNotifier.new,
);
