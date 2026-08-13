import '../../core/supabase/supabase_config.dart';
import '../models/favorite_channel.dart';

class FavoriteChannelsRepository {
  Future<List<FavoriteChannel>> fetchAll() async {
    final rows = await supa
        .from('favorite_channels')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => FavoriteChannel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> add({required String name, required String url}) async {
    final uid = supa.auth.currentUser!.id;
    await supa.from('favorite_channels').upsert({
      'user_id': uid,
      'channel_name': name,
      'channel_url': url,
    }, onConflict: 'user_id,channel_url');
  }

  Future<void> remove(String url) async {
    final uid = supa.auth.currentUser!.id;
    await supa
        .from('favorite_channels')
        .delete()
        .eq('user_id', uid)
        .eq('channel_url', url);
  }
}
