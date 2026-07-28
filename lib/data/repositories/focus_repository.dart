import '../../core/supabase/supabase_config.dart';
import '../models/focus_session.dart';

class FocusRepository {
  Future<FocusSession?> fetchActive() async {
    final uid = supa.auth.currentUser!.id;
    final row = await supa
        .from('focus_sessions')
        .select()
        .eq('user_id', uid)
        .isFilter('ended_at', null)
        .order('started_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : FocusSession.fromMap(row);
  }

  Future<FocusSession> start(String mode) async {
    final uid = supa.auth.currentUser!.id;
    final row = await supa.from('focus_sessions').insert({'user_id': uid, 'mode': mode}).select().single();
    return FocusSession.fromMap(row);
  }

  Future<void> end(String id) async {
    await supa.from('focus_sessions').update({'ended_at': DateTime.now().toIso8601String()}).eq('id', id);
  }
}
