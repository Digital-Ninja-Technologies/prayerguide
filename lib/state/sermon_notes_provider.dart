import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/sermon_note.dart';
import '../data/repositories/sermon_notes_repository.dart';
import 'repo_providers.dart';

final sermonNotesRepositoryProvider = Provider((ref) => SermonNotesRepository());

class SermonNotesNotifier extends AsyncNotifier<List<SermonNote>> {
  @override
  Future<List<SermonNote>> build() {
    ref.watch(currentUserIdProvider);
    return ref.read(sermonNotesRepositoryProvider).fetchAll();
  }

  Future<void> add({
    required String title,
    String? speaker,
    String? scriptureRef,
    required String notes,
    String? audioFilePath,
    int? audioDurationSeconds,
  }) async {
    final repo = ref.read(sermonNotesRepositoryProvider);
    final note = await repo.create(
      title: title,
      speaker: speaker,
      scriptureRef: scriptureRef,
      notes: notes,
      audioFilePath: audioFilePath,
      audioDurationSeconds: audioDurationSeconds,
    );
    state = AsyncData([note, ...state.value ?? []]);
  }

  Future<void> delete(SermonNote note) async {
    final repo = ref.read(sermonNotesRepositoryProvider);
    await repo.delete(note);
    state = AsyncData((state.value ?? []).where((n) => n.id != note.id).toList());
  }
}

final sermonNotesProvider = AsyncNotifierProvider<SermonNotesNotifier, List<SermonNote>>(
  SermonNotesNotifier.new,
);
