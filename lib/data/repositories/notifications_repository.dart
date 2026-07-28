import '../../core/supabase/supabase_config.dart';
import '../models/notification_prefs.dart';

class NotificationsRepository {
  Future<NotificationPrefs> fetch() async {
    final uid = supa.auth.currentUser!.id;
    final row = await supa.from('notification_prefs').select().eq('user_id', uid).maybeSingle();
    if (row == null) return const NotificationPrefs();
    return NotificationPrefs.fromMap(row);
  }

  Future<void> update(Map<String, dynamic> patch) async {
    final uid = supa.auth.currentUser!.id;
    await supa.from('notification_prefs').upsert({'user_id': uid, ...patch});
  }
}
