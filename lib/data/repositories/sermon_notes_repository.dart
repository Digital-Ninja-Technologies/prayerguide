import 'dart:io';

import '../../core/supabase/supabase_config.dart';
import '../models/sermon_note.dart';

class SermonNotesRepository {
  Future<List<SermonNote>> fetchAll() async {
    final rows = await supa.from('sermon_notes').select().order('created_at', ascending: false);
    return (rows as List).map((r) => SermonNote.fromMap(r as Map<String, dynamic>)).toList();
  }

  /// Creates the note row, uploading [audioFilePath] to Storage first (if
  /// given) so `audio_path` is set atomically with everything else — no
  /// row ever points at audio that failed to upload.
  Future<SermonNote> create({
    required String title,
    String? speaker,
    String? scriptureRef,
    required String notes,
    String? audioFilePath,
    int? audioDurationSeconds,
  }) async {
    final uid = supa.auth.currentUser!.id;
    String? audioPath;
    if (audioFilePath != null) {
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      audioPath = '$uid/$id.m4a';
      final bytes = await File(audioFilePath).readAsBytes();
      await supa.storage.from('sermon-audio').uploadBinary(audioPath, bytes);
    }

    final row = await supa
        .from('sermon_notes')
        .insert({
          'user_id': uid,
          'title': title,
          'speaker': speaker,
          'scripture_ref': scriptureRef,
          'notes': notes,
          'audio_path': audioPath,
          'audio_duration_seconds': audioDurationSeconds,
        })
        .select()
        .single();
    return SermonNote.fromMap(row);
  }

  Future<void> delete(SermonNote note) async {
    if (note.audioPath != null) {
      await supa.storage.from('sermon-audio').remove([note.audioPath!]);
    }
    await supa.from('sermon_notes').delete().eq('id', note.id);
  }

  /// A short-lived signed URL for playback — the bucket is private, so the
  /// audio isn't reachable any other way.
  Future<String> signedAudioUrl(String audioPath) {
    return supa.storage.from('sermon-audio').createSignedUrl(audioPath, 60 * 60);
  }
}
