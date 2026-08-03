import 'dart:io';

import '../../core/supabase/supabase_config.dart';
import '../models/sermon_note.dart';

class SermonNotesRepository {
  Future<List<SermonNote>> fetchAll() async {
    final rows = await supa
        .from('sermon_notes')
        .select('*, sermon_note_recordings(*)')
        .order('created_at', ascending: false);
    return (rows as List).map((r) => SermonNote.fromMap(r as Map<String, dynamic>)).toList();
  }

  /// Creates the note row, then uploads and attaches [initialRecordingPaths]
  /// (one or more local files, oldest take first) as separate recordings —
  /// each stopped take is locked in rather than overwriting a prior one.
  Future<SermonNote> create({
    required String title,
    String? speaker,
    String? scriptureRef,
    required String notes,
    List<({String path, int? durationSeconds})> initialRecordingPaths = const [],
  }) async {
    final uid = supa.auth.currentUser!.id;
    final row = await supa
        .from('sermon_notes')
        .insert({
          'user_id': uid,
          'title': title,
          'speaker': speaker,
          'scripture_ref': scriptureRef,
          'notes': notes,
        })
        .select()
        .single();
    final noteId = row['id'] as String;

    final recordings = <SermonRecording>[];
    for (final rec in initialRecordingPaths) {
      recordings.add(await addRecording(
        noteId: noteId,
        localFilePath: rec.path,
        durationSeconds: rec.durationSeconds,
      ));
    }

    return SermonNote.fromMap({...row, 'sermon_note_recordings': recordings.map(_recordingToMap).toList()});
  }

  /// Uploads a local recording and attaches it to an existing note — used
  /// both for a brand-new note's first take(s) and for "record a new one"
  /// on a note that's already saved.
  Future<SermonRecording> addRecording({
    required String noteId,
    required String localFilePath,
    int? durationSeconds,
  }) async {
    final uid = supa.auth.currentUser!.id;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final audioPath = '$uid/$noteId/$id.m4a';
    final bytes = await File(localFilePath).readAsBytes();
    await supa.storage.from('sermon-audio').uploadBinary(audioPath, bytes);

    final row = await supa
        .from('sermon_note_recordings')
        .insert({
          'sermon_note_id': noteId,
          'audio_path': audioPath,
          'duration_seconds': durationSeconds,
        })
        .select()
        .single();
    return SermonRecording.fromMap(row);
  }

  Map<String, dynamic> _recordingToMap(SermonRecording r) => {
        'id': r.id,
        'audio_path': r.audioPath,
        'duration_seconds': r.durationSeconds,
        'created_at': r.createdAt.toIso8601String(),
      };

  Future<void> delete(SermonNote note) async {
    if (note.recordings.isNotEmpty) {
      await supa.storage.from('sermon-audio').remove(note.recordings.map((r) => r.audioPath).toList());
    }
    await supa.from('sermon_notes').delete().eq('id', note.id);
  }

  Future<void> deleteRecording(SermonRecording recording) async {
    await supa.storage.from('sermon-audio').remove([recording.audioPath]);
    await supa.from('sermon_note_recordings').delete().eq('id', recording.id);
  }

  Future<void> update({
    required String noteId,
    required String title,
    String? speaker,
    String? scriptureRef,
    required String notes,
  }) async {
    await supa.from('sermon_notes').update({
      'title': title,
      'speaker': speaker,
      'scripture_ref': scriptureRef,
      'notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', noteId);
  }

  /// A short-lived signed URL for playback — the bucket is private, so the
  /// audio isn't reachable any other way.
  Future<String> signedAudioUrl(String audioPath) {
    return supa.storage.from('sermon-audio').createSignedUrl(audioPath, 60 * 60);
  }
}
