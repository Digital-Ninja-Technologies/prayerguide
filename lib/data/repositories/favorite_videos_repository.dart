import '../../core/supabase/supabase_config.dart';
import '../models/favorite_video.dart';

class FavoriteVideosRepository {
  Future<List<FavoriteVideo>> fetchAll() async {
    final rows = await supa
        .from('favorite_videos')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => FavoriteVideo.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> add({required String title, required String url}) async {
    final uid = supa.auth.currentUser!.id;
    await supa.from('favorite_videos').upsert({
      'user_id': uid,
      'video_title': title,
      'video_url': url,
    }, onConflict: 'user_id,video_url');
  }

  Future<void> remove(String url) async {
    final uid = supa.auth.currentUser!.id;
    await supa
        .from('favorite_videos')
        .delete()
        .eq('user_id', uid)
        .eq('video_url', url);
  }
}
