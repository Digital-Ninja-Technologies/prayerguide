class ChallengeProgress {
  ChallengeProgress({
    required this.id,
    required this.challengeKey,
    required this.name,
    required this.totalDays,
    required this.currentDay,
    required this.active,
    required this.startedAt,
    this.lastAdvancedOn,
  });

  final String id;
  final String challengeKey;
  final String name;
  final int totalDays;
  final int currentDay;
  final bool active;
  final DateTime startedAt;

  /// The last date [markDayComplete] actually advanced this challenge —
  /// null if it's never been advanced. Used to tell whether today's
  /// session is still outstanding for the engagement reminder.
  final DateTime? lastAdvancedOn;

  bool get engagedToday {
    final d = lastAdvancedOn;
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  factory ChallengeProgress.fromMap(Map<String, dynamic> m) =>
      ChallengeProgress(
        id: m['id'] as String,
        challengeKey: m['challenge_key'] as String,
        name: m['name'] as String,
        totalDays: (m['total_days'] as num).toInt(),
        currentDay: (m['current_day'] as num?)?.toInt() ?? 0,
        active: (m['active'] as bool?) ?? true,
        startedAt: DateTime.parse(m['started_at'] as String),
        lastAdvancedOn: m['last_advanced_on'] == null
            ? null
            : DateTime.parse(m['last_advanced_on'] as String),
      );
}
