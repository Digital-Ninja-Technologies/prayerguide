class FocusSession {
  FocusSession({required this.id, required this.mode, required this.startedAt, required this.endedAt});

  final String id;
  final String mode; // gentle | full
  final DateTime startedAt;
  final DateTime? endedAt;

  factory FocusSession.fromMap(Map<String, dynamic> m) => FocusSession(
        id: m['id'] as String,
        mode: m['mode'] as String,
        startedAt: DateTime.parse(m['started_at'] as String),
        endedAt: m['ended_at'] == null ? null : DateTime.parse(m['ended_at'] as String),
      );
}
