import '../../core/supabase/supabase_config.dart';
import '../models/pg_profile.dart';

class ProfileRepository {
  Future<PgProfile> fetch() async {
    final uid = supa.auth.currentUser!.id;
    final row =
        await supa.from('profiles').select().eq('id', uid).maybeSingle();
    if (row == null) {
      return PgProfile.empty(uid, email: supa.auth.currentUser?.email);
    }
    return PgProfile.fromMap(row);
  }

  Future<void> update(Map<String, dynamic> patch) async {
    final uid = supa.auth.currentUser!.id;
    await supa.from('profiles').update(patch).eq('id', uid);
  }

  /// Records a completed prayer session. A DB trigger recomputes the streak.
  Future<void> logSession(
      {required int durationSeconds, String? category}) async {
    final uid = supa.auth.currentUser!.id;
    await supa.from('prayer_sessions').insert({
      'user_id': uid,
      'duration_seconds': durationSeconds,
      'category': category,
    });
  }

  /// Records that the app was opened today. A DB trigger recomputes the
  /// app-open streak — a separate metric from the prayer streak above.
  Future<void> logAppOpen() async {
    final uid = supa.auth.currentUser!.id;
    await supa.from('app_opens').insert({'user_id': uid});
  }

  /// Days-of-month (1-31) that have at least one qualifying prayer session,
  /// for rendering the streak calendar.
  Future<Set<int>> fetchQualifyingDaysInMonth(DateTime month) async {
    final uid = supa.auth.currentUser!.id;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final rows = await supa
        .from('prayer_sessions')
        .select('completed_at, duration_seconds')
        .eq('user_id', uid)
        .gte('completed_at', start.toIso8601String())
        .lt('completed_at', end.toIso8601String());
    final days = <int>{};
    for (final r in rows as List) {
      if (((r['duration_seconds'] as num?) ?? 0) >= 180) {
        days.add(DateTime.parse(r['completed_at'] as String).day);
      }
    }
    return days;
  }
}
