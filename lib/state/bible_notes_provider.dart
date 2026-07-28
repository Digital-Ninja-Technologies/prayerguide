import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/bible_note.dart';
import 'repo_providers.dart';

class BibleNotesNotifier extends AsyncNotifier<List<BibleNote>> {
  @override
  Future<List<BibleNote>> build() {
    ref.watch(currentUserIdProvider);
    return ref.read(bibleNotesRepositoryProvider).fetchAll();
  }

  Future<BibleNote> add({
    required String kind,
    required String reference,
    String? verseText,
    String? note,
  }) async {
    final repo = ref.read(bibleNotesRepositoryProvider);
    final created = await repo.create(kind: kind, reference: reference, verseText: verseText, note: note);
    state = AsyncData([created, ...state.value ?? []]);
    return created;
  }

  Future<void> remove(String id) async {
    final repo = ref.read(bibleNotesRepositoryProvider);
    final current = state.value ?? [];
    state = AsyncData(current.where((n) => n.id != id).toList());
    await repo.delete(id);
  }

  /// The bookmark row for [reference], if the current chapter is bookmarked.
  BibleNote? bookmarkFor(String reference) {
    final entries = state.value ?? [];
    for (final n in entries) {
      if (n.kind == 'bookmark' && n.reference == reference) return n;
    }
    return null;
  }
}

final bibleNotesProvider = AsyncNotifierProvider<BibleNotesNotifier, List<BibleNote>>(
  BibleNotesNotifier.new,
);
