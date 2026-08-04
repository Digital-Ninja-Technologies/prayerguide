import '../../core/supabase/supabase_config.dart';
import '../models/challenge_progress.dart';

class ChallengeRepository {
  Future<List<ChallengeProgress>> fetchAll() async {
    final uid = supa.auth.currentUser!.id;
    final rows = await supa
        .from('challenge_progress')
        .select()
        .eq('user_id', uid)
        .order('started_at', ascending: false);
    return (rows as List)
        .map((r) => ChallengeProgress.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<ChallengeProgress> start({
    required String challengeKey,
    required String name,
    required int totalDays,
  }) async {
    final uid = supa.auth.currentUser!.id;
    final row = await supa
        .from('challenge_progress')
        .insert({
          'user_id': uid,
          'challenge_key': challengeKey,
          'name': name,
          'total_days': totalDays,
          'current_day': 0,
          'active': true,
        })
        .select()
        .single();
    return ChallengeProgress.fromMap(row);
  }

  Future<ChallengeProgress> markDayComplete(String id, int totalDays) async {
    final existing = await supa
        .from('challenge_progress')
        .select('current_day')
        .eq('id', id)
        .single();
    final current = (existing['current_day'] as num?)?.toInt() ?? 0;
    final next = (current + 1).clamp(0, totalDays);
    final today = DateTime.now();
    final todayStr =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final row = await supa
        .from('challenge_progress')
        .update({
          'current_day': next,
          'active': next < totalDays,
          'last_advanced_on': todayStr,
        })
        .eq('id', id)
        .select()
        .single();
    return ChallengeProgress.fromMap(row);
  }
}
