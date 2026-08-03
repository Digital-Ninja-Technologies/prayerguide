class SermonRecording {
  SermonRecording({
    required this.id,
    required this.audioPath,
    required this.durationSeconds,
    required this.createdAt,
  });

  final String id;
  final String audioPath;
  final int? durationSeconds;
  final DateTime createdAt;

  factory SermonRecording.fromMap(Map<String, dynamic> m) => SermonRecording(
        id: m['id'] as String,
        audioPath: m['audio_path'] as String,
        durationSeconds: (m['duration_seconds'] as num?)?.toInt(),
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

class SermonNote {
  SermonNote({
    required this.id,
    required this.title,
    required this.speaker,
    required this.scriptureRef,
    required this.notes,
    required this.recordings,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? speaker;
  final String? scriptureRef;
  final String notes;
  final List<SermonRecording> recordings;
  final DateTime createdAt;

  bool get hasAudio => recordings.isNotEmpty;

  factory SermonNote.fromMap(Map<String, dynamic> m) => SermonNote(
        id: m['id'] as String,
        title: m['title'] as String,
        speaker: m['speaker'] as String?,
        scriptureRef: m['scripture_ref'] as String?,
        notes: (m['notes'] as String?) ?? '',
        recordings: ((m['sermon_note_recordings'] as List?) ?? [])
            .map((r) => SermonRecording.fromMap(r as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
