import 'dart:math' as math;

import '../../core/supabase/supabase_config.dart';
import '../models/pg_group.dart';

class GroupsRepository {
  Future<List<PgGroup>> fetchMyGroups() async {
    final uid = supa.auth.currentUser!.id;
    final memberRows = await supa.from('group_members').select('group_id').eq('user_id', uid);
    final groupIds = (memberRows as List).map((r) => r['group_id'] as String).toList();
    if (groupIds.isEmpty) return [];

    final groupRows = await supa.from('groups').select().inFilter('id', groupIds);
    final allMemberRows = await supa.from('group_members').select('group_id').inFilter('group_id', groupIds);
    final counts = <String, int>{};
    for (final r in allMemberRows as List) {
      final gid = r['group_id'] as String;
      counts[gid] = (counts[gid] ?? 0) + 1;
    }

    final groups = (groupRows as List)
        .map((r) => PgGroup.fromMap(r as Map<String, dynamic>, memberCount: counts[r['id']] ?? 1))
        .toList();
    groups.sort((a, b) => a.name.compareTo(b.name));
    return groups;
  }

  /// Creates a group (with a shareable invite code) and adds the creator as
  /// its first member.
  Future<PgGroup> createGroup({required String name, String? meetingTime}) async {
    final uid = supa.auth.currentUser!.id;
    final code = _generateCode();
    final row = await supa
        .from('groups')
        .insert({'name': name, 'meeting_time': meetingTime, 'created_by': uid, 'invite_code': code})
        .select()
        .single();
    await supa.from('group_members').insert({'group_id': row['id'], 'user_id': uid});
    return PgGroup.fromMap(row, memberCount: 1);
  }

  /// Redeems someone else's group invite code, joining that group.
  Future<void> joinGroup(String code) async {
    await supa.rpc('redeem_group_invite', params: {'p_code': code.trim()});
  }

  Future<void> leaveGroup(String groupId) async {
    final uid = supa.auth.currentUser!.id;
    await supa.from('group_members').delete().eq('group_id', groupId).eq('user_id', uid);
  }

  String _generateCode() {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789'; // no ambiguous chars (0/o, 1/l/i)
    final rand = math.Random.secure();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
