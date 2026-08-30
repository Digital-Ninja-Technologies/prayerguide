import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio/local_recording_store.dart';
import '../data/models/sermon_note.dart';
import '../data/repositories/sermon_notes_repository.dart';
import 'repo_providers.dart';

final sermonNotesRepositoryProvider = Provider((ref) => SermonNotesRepository());

class SermonNotesNotifier extends AsyncNotifier<List<SermonNote>> {
  @override
  Future<List<SermonNote>> build() async {
    ref.watch(currentUserIdProvider);
    final notes = await ref.read(sermonNotesRepositoryProvider).fetchAll();
    // Fire-and-forget: retries any recording that made it to disk but never
    // made it to Supabase (offline, or the app was killed mid-upload) — runs
    // once per provider build, so it happens automatically as soon as
    // there's a chance of connectivity, with no dedicated background worker.
    unawaited(_retryPendingUploads());
    return notes;
  }

  Future<void> add({
    required String title,
    String? speaker,
    String? scriptureRef,
    required String notes,
    List<({String path, int? durationSeconds})> initialRecordingPaths = const [],
  }) async {
    final repo = ref.read(sermonNotesRepositoryProvider);
    final note = await repo.create(title: title, speaker: speaker, scriptureRef: scriptureRef, notes: notes);
    state = AsyncData([note, ...state.value ?? []]);
    // Each take goes through the same local-first path as one added later —
    // safely on-device immediately, uploaded in the background, never lost
    // to a failed/offline upload.
    for (final rec in initialRecordingPaths) {
      await addRecording(noteId: note.id, localFilePath: rec.path, durationSeconds: rec.durationSeconds);
    }
  }

  /// Attaches a newly-recorded take to an already-saved note — local-first:
  /// the take is indexed and durably on-device before any network call, so
  /// it's never lost even if the upload that follows fails or there's no
  /// connection at all.
  Future<void> addRecording({
    required String noteId,
    required String localFilePath,
    int? durationSeconds,
  }) async {
    final localKey = newLocalRecordingKey();
    await localRecordingStore.put(
      localKey,
      LocalRecordingEntry(
        localPath: localFilePath,
        noteId: noteId,
        pendingUpload: true,
        durationSeconds: durationSeconds,
      ),
    );
    final optimistic = SermonRecording(
      id: localKey,
      audioPath: '',
      durationSeconds: durationSeconds,
      createdAt: DateTime.now(),
      pendingUpload: true,
    );
    _replaceNote(noteId, (n) => _withFields(n, recordings: [...n.recordings, optimistic]));
    await _uploadPending(localKey, noteId);
  }

  /// Uploads one still-pending local recording; on failure it simply stays
  /// pending (already safe on-device) for the next retry sweep or explicit
  /// call to pick back up.
  Future<void> _uploadPending(String localKey, String noteId) async {
    final entry = await localRecordingStore.get(localKey);
    if (entry == null) return;
    try {
      final repo = ref.read(sermonNotesRepositoryProvider);
      final recording = await repo.addRecording(
        noteId: noteId,
        localFilePath: entry.localPath,
        durationSeconds: entry.durationSeconds,
      );
      await localRecordingStore.rekey(localKey, recording.id);
      await localRecordingStore.markSynced(recording.id);
      _replaceNote(
        noteId,
        (n) => _withFields(n,
            recordings: [for (final r in n.recordings) if (r.id == localKey) recording else r]),
      );
    } catch (_) {
      // Left pending — retried by `_retryPendingUploads` next time the
      // provider builds, or the next explicit save attempt on this note.
    }
  }

  Future<void> _retryPendingUploads() async {
    for (final e in await localRecordingStore.pending()) {
      if (!await File(e.value.localPath).exists()) continue;
      await _uploadPending(e.key, e.value.noteId);
    }
  }

  Future<void> deleteRecording({required String noteId, required SermonRecording recording}) async {
    if (recording.pendingUpload) {
      // Never made it to Supabase — nothing to delete there, just the local
      // copy and its index entry.
      final entry = await localRecordingStore.get(recording.id);
      if (entry != null) {
        await _deleteLocalFileQuietly(entry.localPath);
        await localRecordingStore.remove(recording.id);
      }
    } else {
      final repo = ref.read(sermonNotesRepositoryProvider);
      await repo.deleteRecording(recording);
      // A synced recording may still have a local copy kept for offline
      // playback — clean that up too.
      final entry = await localRecordingStore.get(recording.id);
      if (entry != null) {
        await _deleteLocalFileQuietly(entry.localPath);
        await localRecordingStore.remove(recording.id);
      }
    }
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
    for (final r in note.recordings) {
      final entry = await localRecordingStore.get(r.id);
      if (entry != null) {
        await _deleteLocalFileQuietly(entry.localPath);
        await localRecordingStore.remove(r.id);
      }
    }
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

/// Best-effort local cleanup — a leftover file isn't worth surfacing to the
/// user (mirrors the same best-effort delete already used for draft takes
/// in `sermon_note_new_screen.dart`).
Future<void> _deleteLocalFileQuietly(String path) async {
  try {
    await File(path).delete();
  } catch (_) {}
}

const _unset = Object();

final sermonNotesProvider = AsyncNotifierProvider<SermonNotesNotifier, List<SermonNote>>(
  SermonNotesNotifier.new,
);
