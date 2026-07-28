class FastingSession {
  FastingSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.targetHours,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double targetHours;

  factory FastingSession.fromMap(Map<String, dynamic> m) => FastingSession(
        id: m['id'] as String,
        startedAt: DateTime.parse(m['started_at'] as String),
        endedAt: m['ended_at'] == null ? null : DateTime.parse(m['ended_at'] as String),
        targetHours: (m['target_hours'] as num).toDouble(),
      );
}
