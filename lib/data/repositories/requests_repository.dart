import '../../core/supabase/supabase_config.dart';
import '../models/prayer_request.dart';

/// Prayer requests are stored in plaintext (RLS-gated, not client-side
/// encrypted like Journal) — that's what makes sharing a request with a
/// companion possible. See supabase/migrations/0007_unencrypt_requests_for_sharing.sql.
class RequestsRepository {
  Future<List<PrayerRequest>> fetchAll() async {
    final rows =
        await supa.from('prayer_requests').select().order('created_at', ascending: false);
    return (rows as List).map((r) => PrayerRequest.fromMap(r as Map<String, dynamic>)).toList();
  }

  Future<PrayerRequest> create({
    required String category,
    required String title,
    String? note,
    bool reminder = false,
    bool sharedWithCompanion = false,
  }) async {
    final uid = supa.auth.currentUser!.id;
    final row = await supa
        .from('prayer_requests')
        .insert({
          'user_id': uid,
          'category': category,
          'title': title,
          'note': note,
          'reminder': reminder,
          'shared_with_companion': sharedWithCompanion,
        })
        .select()
        .single();
    return PrayerRequest.fromMap(row);
  }

  Future<void> update(String id, Map<String, dynamic> patch) async {
    await supa
        .from('prayer_requests')
        .update({...patch, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
