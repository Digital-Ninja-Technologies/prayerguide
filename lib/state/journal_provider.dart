import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/journal_entry.dart';
import 'repo_providers.dart';

class JournalNotifier extends AsyncNotifier<List<JournalEntry>> {
  @override
  Future<List<JournalEntry>> build() {
    ref.watch(currentUserIdProvider);
    return ref.read(journalRepositoryProvider).fetchAll();
  }

  Future<void> add({required String type, required String title, required String body}) async {
    final repo = ref.read(journalRepositoryProvider);
    final entry = await repo.create(type: type, title: title, body: body);
    state = AsyncData([entry, ...state.value ?? []]);
  }
}

final journalProvider = AsyncNotifierProvider<JournalNotifier, List<JournalEntry>>(
  JournalNotifier.new,
);
