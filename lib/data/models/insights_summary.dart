class InsightsSummary {
  const InsightsSummary({
    required this.dailyMinutes,
    required this.totalMinutesThisWeek,
    required this.topCategory,
    required this.topTimeOfDay,
    required this.hasAnySessions,
  });

  /// Minutes prayed per day this week, Sunday..Saturday (7 entries).
  final List<int> dailyMinutes;
  final int totalMinutesThisWeek;
  final String? topCategory;

  /// 'morning' | 'afternoon' | 'evening' | 'night', or null if no data.
  final String? topTimeOfDay;
  final bool hasAnySessions;

  String get totalTimeLabel {
    final h = totalMinutesThisWeek ~/ 60;
    final m = totalMinutesThisWeek % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  String get gentleInsight {
    if (!hasAnySessions) {
      return "Complete a prayer session and we'll start noticing your rhythm here.";
    }
    final timePhrase = switch (topTimeOfDay) {
      'morning' => 'in the mornings',
      'afternoon' => 'in the afternoons',
      'evening' => 'in the evenings',
      'night' => 'late at night',
      _ => null,
    };
    final parts = <String>[];
    if (timePhrase != null) parts.add('You pray most consistently $timePhrase.');
    if (topCategory != null) {
      parts.add('$topCategory is your most-visited guide — a beautiful place to keep returning.');
    }
    if (parts.isEmpty) return 'Keep showing up — your rhythm will start to take shape here.';
    return parts.join(' ');
  }
}
