class SermonNote {
  SermonNote({
    required this.id,
    required this.title,
    required this.speaker,
    required this.scriptureRef,
    required this.notes,
    required this.audioPath,
    required this.audioDurationSeconds,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? speaker;
  final String? scriptureRef;
  final String notes;
  final String? audioPath;
  final int? audioDurationSeconds;
  final DateTime createdAt;

  bool get hasAudio => audioPath != null;

  factory SermonNote.fromMap(Map<String, dynamic> m) => SermonNote(
        id: m['id'] as String,
        title: m['title'] as String,
        speaker: m['speaker'] as String?,
        scriptureRef: m['scripture_ref'] as String?,
        notes: (m['notes'] as String?) ?? '',
        audioPath: m['audio_path'] as String?,
        audioDurationSeconds: (m['audio_duration_seconds'] as num?)?.toInt(),
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
