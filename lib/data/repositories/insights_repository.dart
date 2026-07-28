import '../../core/supabase/supabase_config.dart';
import '../models/insights_summary.dart';

class InsightsRepository {
  Future<InsightsSummary> fetchSummary() async {
    final uid = supa.auth.currentUser!.id;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: now.weekday % 7));
    final since = now.subtract(const Duration(days: 30));
    final earliest = since.isBefore(startOfWeek) ? since : startOfWeek;

    final rows = await supa
        .from('prayer_sessions')
        .select('completed_at, duration_seconds, category')
        .eq('user_id', uid)
        .gte('completed_at', earliest.toIso8601String());

    final dailySeconds = List<int>.filled(7, 0);
    final categoryCounts = <String, int>{};
    final timeOfDayCounts = <String, int>{};

    for (final r in rows as List) {
      final row = r as Map<String, dynamic>;
      final completedAt = DateTime.parse(row['completed_at'] as String).toLocal();
      final duration = (row['duration_seconds'] as num?)?.toInt() ?? 0;
      final category = row['category'] as String?;

      if (!completedAt.isBefore(startOfWeek)) {
        dailySeconds[completedAt.weekday % 7] += duration;
      }
      if (category != null && category.isNotEmpty) {
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }
      final bucket = _timeOfDayBucket(completedAt.hour);
      timeOfDayCounts[bucket] = (timeOfDayCounts[bucket] ?? 0) + 1;
    }

    return InsightsSummary(
      dailyMinutes: dailySeconds.map((s) => (s / 60).round()).toList(),
      totalMinutesThisWeek: (dailySeconds.reduce((a, b) => a + b) / 60).round(),
      topCategory: _top(categoryCounts),
      topTimeOfDay: _top(timeOfDayCounts),
      hasAnySessions: (rows).isNotEmpty,
    );
  }

  String _timeOfDayBucket(int hour) {
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    if (hour < 21) return 'evening';
    return 'night';
  }

  String? _top(Map<String, int> counts) {
    if (counts.isEmpty) return null;
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }
}
