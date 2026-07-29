import 'dart:math' as math;

import '../../core/supabase/supabase_config.dart';
import '../models/companion.dart';

class CompanionRepository {
  Future<Companion?> fetchCompanion() async {
    final uid = supa.auth.currentUser!.id;
    final row = await supa
        .from('companions')
        .select()
        .or('user_a.eq.$uid,user_b.eq.$uid')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;

    final otherId = row['user_a'] == uid
        ? row['user_b'] as String
        : row['user_a'] as String;
    final profileRow = await supa
        .from('profiles')
        .select('name, streak_count')
        .eq('id', otherId)
        .maybeSingle();
    final name = (profileRow?['name'] as String?)?.trim();

    return Companion(
      companionRowId: row['id'] as String,
      otherUserId: otherId,
      otherName: (name == null || name.isEmpty) ? 'Your companion' : name,
      otherStreak: (profileRow?['streak_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Creates a fresh invite code tied to the current user and returns it.
  Future<String> createInvite() async {
    final uid = supa.auth.currentUser!.id;
    final code = _generateCode();
    await supa
        .from('companion_invites')
        .insert({'inviter_id': uid, 'code': code});
    return code;
  }

  /// Redeems someone else's invite code, pairing the two accounts. Accepts
  /// either a bare code or the full shared link (`prayerguide.app/j/<code>`)
  /// — whatever the person pasted or scanned.
  /// Throws if the code is invalid, expired, already used, or your own.
  Future<void> redeemInvite(String codeOrLink) async {
    await supa.rpc('redeem_companion_invite',
        params: {'invite_code': _extractCode(codeOrLink)});
  }

  String _extractCode(String raw) {
    final trimmed = raw.trim();
    final marker = trimmed.lastIndexOf('/j/');
    return marker == -1 ? trimmed : trimmed.substring(marker + 3).trim();
  }

  Future<void> checkin(
      {required String companionId, required String status}) async {
    final uid = supa.auth.currentUser!.id;
    await supa.from('companion_checkins').insert({
      'user_id': uid,
      'companion_id': companionId,
      'status': status,
    });
  }

  Future<List<CompanionCheckinEntry>> fetchRecentCheckins(String companionId,
      {int limit = 10}) async {
    final rows = await supa
        .from('companion_checkins')
        .select()
        .eq('companion_id', companionId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => CompanionCheckinEntry.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Requests either of you has explicitly marked shared — visible via the
  /// owner-only policy for your own rows and the companion-visibility
  /// policy for theirs (see migration 0007).
  Future<List<SharedRequest>> fetchSharedRequests({
    required String myUserId,
    required String otherUserId,
    int limit = 20,
  }) async {
    final rows = await supa
        .from('prayer_requests')
        .select('user_id, category, title, created_at')
        .eq('shared_with_companion', true)
        .inFilter('user_id', [myUserId, otherUserId])
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => SharedRequest.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  String _generateCode() {
    const chars =
        'abcdefghjkmnpqrstuvwxyz23456789'; // no ambiguous chars (0/o, 1/l/i)
    final rand = math.Random.secure();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
