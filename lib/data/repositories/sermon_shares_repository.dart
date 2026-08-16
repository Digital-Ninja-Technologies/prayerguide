import '../../core/supabase/supabase_config.dart';
import '../models/sermon_share.dart';

class SermonSharesRepository {
  Future<List<UserSearchResult>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final rows = await supa.rpc('search_users', params: {'query': query.trim()});
    return (rows as List)
        .map((r) => UserSearchResult.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> shareSermon({
    required String sermonNoteId,
    required String recipientId,
  }) async {
    final uid = supa.auth.currentUser!.id;
    final profile = await supa
        .from('profiles')
        .select('name')
        .eq('id', uid)
        .maybeSingle();
    final senderName = (profile?['name'] as String?)?.trim();

    final row = await supa
        .from('sermon_shares')
        .insert({
          'sermon_note_id': sermonNoteId,
          'sender_id': uid,
          'recipient_id': recipientId,
          'sender_name': senderName == null || senderName.isEmpty ? null : senderName,
        })
        .select('id')
        .single();
    final shareId = row['id'] as String;

    try {
      await supa.functions.invoke('send-sermon-share-push', body: {'shareId': shareId});
    } catch (_) {
      // Best-effort — the share still exists and shows up in the recipient's
      // in-app inbox either way; they just won't get pushed if this fails.
    }
  }

  Future<List<SermonShare>> fetchPendingForMe() async {
    final uid = supa.auth.currentUser!.id;
    final rows = await supa
        .from('sermon_shares')
        .select('*, sermon_notes(title)')
        .eq('recipient_id', uid)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (rows as List).map((r) => SermonShare.fromMap(r as Map<String, dynamic>)).toList();
  }

  /// Copies the sermon note (and its recordings) into the caller's own
  /// sermon_notes/sermon_note_recordings — done server-side (Edge Function)
  /// since copying the recording audio between two users' storage folders
  /// needs a service-role client, not something RLS lets a plain client do.
  Future<void> accept(String shareId) {
    return supa.functions.invoke('accept-sermon-share', body: {'shareId': shareId});
  }

  Future<void> decline(String shareId) {
    return supa.rpc('decline_sermon_share', params: {'share_id': shareId});
  }

  /// Live count of shares pending for the current user — drives the badge
  /// on the Sermon Notes list.
  Stream<int> watchPendingCount() {
    final uid = supa.auth.currentUser?.id;
    if (uid == null) return const Stream.empty();
    return supa
        .from('sermon_shares')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', uid)
        .map((rows) => rows.where((r) => r['status'] == 'pending').length);
  }
}
