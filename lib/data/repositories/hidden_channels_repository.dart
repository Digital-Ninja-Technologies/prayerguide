import '../../core/supabase/supabase_config.dart';

class HiddenChannelsRepository {
  Future<Set<String>> fetchAll() async {
    final rows = await supa.from('hidden_channels').select('channel_url');
    return (rows as List)
        .map((r) => (r as Map<String, dynamic>)['channel_url'] as String)
        .toSet();
  }

  Future<void> hide(String url) async {
    final uid = supa.auth.currentUser!.id;
    await supa.from('hidden_channels').upsert(
        {'user_id': uid, 'channel_url': url},
        onConflict: 'user_id,channel_url');
  }
}
