class ChallengeProgress {
  ChallengeProgress({
    required this.id,
    required this.challengeKey,
    required this.name,
    required this.totalDays,
    required this.currentDay,
    required this.active,
    required this.startedAt,
  });

  final String id;
  final String challengeKey;
  final String name;
  final int totalDays;
  final int currentDay;
  final bool active;
  final DateTime startedAt;

  factory ChallengeProgress.fromMap(Map<String, dynamic> m) => ChallengeProgress(
        id: m['id'] as String,
        challengeKey: m['challenge_key'] as String,
        name: m['name'] as String,
        totalDays: (m['total_days'] as num).toInt(),
        currentDay: (m['current_day'] as num?)?.toInt() ?? 0,
        active: (m['active'] as bool?) ?? true,
        startedAt: DateTime.parse(m['started_at'] as String),
      );
}
