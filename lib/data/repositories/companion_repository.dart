import 'dart:math' as math;

import '../../core/supabase/supabase_config.dart';
import '../models/companion.dart';

class CompanionRepository {
  /// All companion pairs the current user is part of, most recent first.
  Future<List<Companion>> fetchCompanions() async {
    final uid = supa.auth.currentUser!.id;
    final rows = await supa
        .from('companions')
        .select()
        .or('user_a.eq.$uid,user_b.eq.$uid')
        .order('created_at', ascending: false);
    if (rows.isEmpty) return [];

    String otherIdOf(Map<String, dynamic> row) => row['user_a'] == uid
        ? row['user_b'] as String
        : row['user_a'] as String;

    final otherIds = rows.map(otherIdOf).toList();
    final profileRows = await supa
        .from('profiles')
        .select('id, name, streak_count')
        .inFilter('id', otherIds);
    final profileById = {
      for (final p in profileRows) p['id'] as String: p,
    };

    return rows
        .map((row) => _companionFromRow(row, uid, profileById[otherIdOf(row)]))
        .toList();
  }

  Future<Companion?> fetchCompanionByRowId(String companionRowId) async {
    final uid = supa.auth.currentUser!.id;
    final row = await supa
        .from('companions')
        .select()
        .eq('id', companionRowId)
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
    return _companionFromRow(row, uid, profileRow);
  }

  Companion _companionFromRow(
      Map<String, dynamic> row, String uid, Map<String, dynamic>? profileRow) {
    final otherId = row['user_a'] == uid
        ? row['user_b'] as String
        : row['user_a'] as String;
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
