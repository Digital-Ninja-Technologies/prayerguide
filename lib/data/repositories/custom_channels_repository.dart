import '../../core/supabase/supabase_config.dart';
import '../models/custom_channel.dart';

class CustomChannelsRepository {
  Future<List<CustomChannel>> fetchAll() async {
    final rows = await supa
        .from('custom_channels')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => CustomChannel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<CustomChannel> add({required String name, required String url}) async {
    final uid = supa.auth.currentUser!.id;
    final row = await supa
        .from('custom_channels')
        .insert({'user_id': uid, 'channel_name': name, 'channel_url': url})
        .select()
        .single();
    return CustomChannel.fromMap(row);
  }

  Future<void> remove(String id) async {
    await supa.from('custom_channels').delete().eq('id', id);
  }
}
