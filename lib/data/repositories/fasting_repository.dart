import '../../core/supabase/supabase_config.dart';
import '../models/fasting_session.dart';

class FastingRepository {
  Future<FastingSession?> fetchActive() async {
    final uid = supa.auth.currentUser!.id;
    final row = await supa
        .from('fasting_sessions')
        .select()
        .eq('user_id', uid)
        .isFilter('ended_at', null)
        .order('started_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : FastingSession.fromMap(row);
  }

  Future<FastingSession> start(double targetHours) async {
    final uid = supa.auth.currentUser!.id;
    final row = await supa
        .from('fasting_sessions')
        .insert({'user_id': uid, 'target_hours': targetHours})
        .select()
        .single();
    return FastingSession.fromMap(row);
  }

  Future<void> end(String id) async {
    await supa.from('fasting_sessions').update({'ended_at': DateTime.now().toIso8601String()}).eq('id', id);
  }

  Future<int> countPrayerSessionsSince(DateTime since) async {
    final uid = supa.auth.currentUser!.id;
    final rows = await supa
        .from('prayer_sessions')
        .select('id')
        .eq('user_id', uid)
        .gte('completed_at', since.toIso8601String());
    return (rows as List).length;
  }

  Future<int> countJournalEntriesSince(DateTime since) async {
    final uid = supa.auth.currentUser!.id;
    final rows = await supa
        .from('journal_entries')
        .select('id')
        .eq('user_id', uid)
        .gte('created_at', since.toIso8601String());
    return (rows as List).length;
  }
}
