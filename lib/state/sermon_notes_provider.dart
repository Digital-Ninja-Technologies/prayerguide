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
    List<({String path, int? durationSeconds})> initialRecordingPaths = const [],
  }) async {
    final repo = ref.read(sermonNotesRepositoryProvider);
    final note = await repo.create(
      title: title,
      speaker: speaker,
      scriptureRef: scriptureRef,
      notes: notes,
      initialRecordingPaths: initialRecordingPaths,
    );
    state = AsyncData([note, ...state.value ?? []]);
  }

  /// Attaches a newly-recorded take to an already-saved note.
  Future<void> addRecording({
    required String noteId,
    required String localFilePath,
    int? durationSeconds,
  }) async {
    final repo = ref.read(sermonNotesRepositoryProvider);
    final recording = await repo.addRecording(
      noteId: noteId,
      localFilePath: localFilePath,
      durationSeconds: durationSeconds,
    );
    _replaceNote(noteId, (n) => _withFields(n, recordings: [...n.recordings, recording]));
  }

  Future<void> deleteRecording({required String noteId, required SermonRecording recording}) async {
    final repo = ref.read(sermonNotesRepositoryProvider);
    await repo.deleteRecording(recording);
    _replaceNote(noteId, (n) => _withFields(n, recordings: n.recordings.where((r) => r.id != recording.id).toList()));
  }

  Future<void> updateNote({
    required String noteId,
    required String title,
    String? speaker,
    String? scriptureRef,
    required String notes,
  }) async {
    final repo = ref.read(sermonNotesRepositoryProvider);
    await repo.update(noteId: noteId, title: title, speaker: speaker, scriptureRef: scriptureRef, notes: notes);
    _replaceNote(noteId, (n) => _withFields(n, title: title, speaker: speaker, scriptureRef: scriptureRef, notes: notes));
  }

  Future<void> delete(SermonNote note) async {
    final repo = ref.read(sermonNotesRepositoryProvider);
    await repo.delete(note);
    state = AsyncData((state.value ?? []).where((n) => n.id != note.id).toList());
  }

  void _replaceNote(String noteId, SermonNote Function(SermonNote) transform) {
    final current = state.value ?? [];
    state = AsyncData([
      for (final n in current) if (n.id == noteId) transform(n) else n,
    ]);
  }

  SermonNote _withFields(
    SermonNote n, {
    String? title,
    Object? speaker = _unset,
    Object? scriptureRef = _unset,
    String? notes,
    List<SermonRecording>? recordings,
  }) =>
      SermonNote(
        id: n.id,
        title: title ?? n.title,
        speaker: identical(speaker, _unset) ? n.speaker : speaker as String?,
        scriptureRef: identical(scriptureRef, _unset) ? n.scriptureRef : scriptureRef as String?,
        notes: notes ?? n.notes,
        recordings: recordings ?? n.recordings,
        createdAt: n.createdAt,
        sharedFromName: n.sharedFromName,
      );
}

const _unset = Object();

final sermonNotesProvider = AsyncNotifierProvider<SermonNotesNotifier, List<SermonNote>>(
  SermonNotesNotifier.new,
);
