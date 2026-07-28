import '../../core/supabase/supabase_config.dart';
import '../models/reading_plan_progress.dart';

class ReadingPlanRepository {
  Future<List<ReadingPlanProgress>> fetchAll() async {
    final uid = supa.auth.currentUser!.id;
    final rows = await supa.from('reading_plan_progress').select().eq('user_id', uid);
    return (rows as List).map((r) => ReadingPlanProgress.fromMap(r as Map<String, dynamic>)).toList();
  }

  /// Advances [planKey] by exactly one day (capped at [totalDays]) and marks
  /// it active. Creates the progress row on first call for this plan.
  Future<ReadingPlanProgress> markDayComplete({required String planKey, required int totalDays}) async {
    final uid = supa.auth.currentUser!.id;
    final existing =
        await supa.from('reading_plan_progress').select().eq('user_id', uid).eq('plan_key', planKey).maybeSingle();
    final current = (existing?['days_completed'] as num?)?.toInt() ?? 0;
    final next = (current + 1).clamp(0, totalDays);
    final pct = totalDays == 0 ? 0.0 : next / totalDays;

    final row = await supa.from('reading_plan_progress').upsert(
      {
        'user_id': uid,
        'plan_key': planKey,
        'days_completed': next,
        'pct': pct,
        'active': true,
      },
      onConflict: 'user_id,plan_key',
    ).select().single();
    return ReadingPlanProgress.fromMap(row);
  }
}
