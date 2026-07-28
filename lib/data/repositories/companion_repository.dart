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

    final otherId = row['user_a'] == uid ? row['user_b'] as String : row['user_a'] as String;
    final profileRow = await supa.from('profiles').select('name, streak_count').eq('id', otherId).maybeSingle();
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
    await supa.from('companion_invites').insert({'inviter_id': uid, 'code': code});
    return code;
  }

  /// Redeems someone else's invite code, pairing the two accounts.
  /// Throws if the code is invalid, expired, already used, or your own.
  Future<void> redeemInvite(String code) async {
    await supa.rpc('redeem_companion_invite', params: {'invite_code': code.trim()});
  }

  Future<void> checkin({required String companionId, required String status}) async {
    final uid = supa.auth.currentUser!.id;
    await supa.from('companion_checkins').insert({
      'user_id': uid,
      'companion_id': companionId,
      'status': status,
    });
  }

  Future<List<CompanionCheckinEntry>> fetchRecentCheckins(String companionId, {int limit = 10}) async {
    final rows = await supa
        .from('companion_checkins')
        .select()
        .eq('companion_id', companionId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List).map((r) => CompanionCheckinEntry.fromMap(r as Map<String, dynamic>)).toList();
  }

  String _generateCode() {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789'; // no ambiguous chars (0/o, 1/l/i)
    final rand = math.Random.secure();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
