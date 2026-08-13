import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_config.dart';

/// "Pray with Companion" live invites — tapping "Pray live"
/// (companion_detail_screen.dart) creates one of these and asks the
/// send-companion-invite-push Edge Function to notify the other side, so
/// they find out even if they're not already in the app. Prayer Together's
/// own Realtime Presence (together_screen.dart) already covers the case
/// where both people are already there; this only covers the "not yet"
/// case, and the explicit decline that presence alone can't express.
class PrayerInviteRepository {
  Future<String> sendInvite(String companionRowId) async {
    final uid = supa.auth.currentUser!.id;
    String inviteId;
    try {
      final row = await supa
          .from('companion_prayer_invites')
          .insert({'companion_id': companionRowId, 'requester_id': uid})
          .select('id')
          .single();
      inviteId = row['id'] as String;
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow;
      // Already a pending invite for this pair (e.g. a double-tap) — reuse
      // it instead of erroring.
      final row = await supa
          .from('companion_prayer_invites')
          .select('id')
          .eq('companion_id', companionRowId)
          .eq('status', 'pending')
          .single();
      inviteId = row['id'] as String;
    }

    try {
      await supa.functions
          .invoke('send-companion-invite-push', body: {'inviteId': inviteId});
    } catch (_) {
      // Best-effort: the requester still lands in the live session either
      // way (see together_screen.dart's own presence detection) — the
      // companion just won't be pushed if this fails, e.g. push isn't
      // configured server-side yet.
    }
    return inviteId;
  }

  Future<void> respond({required String inviteId, required bool accept}) {
    return supa.rpc('respond_to_prayer_invite', params: {
      'invite_id': inviteId,
      'new_status': accept ? 'accepted' : 'declined',
    });
  }

  /// Watches one invite's row so the requester can learn about a decline —
  /// an accept is instead discovered via Realtime Presence, the same way
  /// Prayer Together always has, once the companion actually joins.
  Stream<String?> watchStatus(String inviteId) {
    return supa
        .from('companion_prayer_invites')
        .stream(primaryKey: ['id'])
        .eq('id', inviteId)
        .map((rows) => rows.isEmpty ? null : rows.first['status'] as String?);
  }
}

final prayerInviteRepositoryProvider = Provider((ref) => PrayerInviteRepository());
