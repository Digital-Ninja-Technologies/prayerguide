import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';
import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../state/groups_provider.dart';
import '../../state/profile_provider.dart';
import '../../widgets/pg_back_button.dart';

class RoomScreen extends ConsumerWidget {
  const RoomScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);
    final groups = groupsAsync.valueOrNull;
    final group = groups == null ? null : (groups.where((g) => g.id == groupId).isEmpty ? null : groups.firstWhere((g) => g.id == groupId));
    final myName = ref.watch(profileProvider).valueOrNull?.name ?? 'You';

    if (groupId.isEmpty || (groupsAsync.hasValue && group == null)) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Couldn't find that room.", textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextButton(onPressed: () => context.pop(), child: const Text('Close')),
              ],
            ),
          ),
        ),
      );
    }
    if (group == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _RoomPresence(groupId: groupId, groupName: group.name, createdBy: group.createdBy, myName: myName);
  }
}

class _RoomPresence extends StatefulWidget {
  const _RoomPresence({required this.groupId, required this.groupName, required this.createdBy, required this.myName});
  final String groupId;
  final String groupName;
  final String createdBy;
  final String myName;

  @override
  State<_RoomPresence> createState() => _RoomPresenceState();
}

class _Participant {
  _Participant({required this.uid, required this.name, required this.handRaised});
  final String uid;
  final String name;
  final bool handRaised;
}

class _RoomPresenceState extends State<_RoomPresence> {
  late final String _myUid = supa.auth.currentUser!.id;
  late final RealtimeChannel _channel;
  bool _handRaised = false;
  List<_Participant> _participants = [];

  @override
  void initState() {
    super.initState();
    _channel = supa.channel('room-${widget.groupId}', opts: const RealtimeChannelConfig(enabled: true));
    _channel.onPresenceSync((_) => _handleSync()).subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _track();
      }
    });
  }

  Future<void> _track() {
    return _channel.track({'user_id': _myUid, 'name': widget.myName, 'hand_raised': _handRaised});
  }

  void _handleSync() {
    final seen = <String, _Participant>{};
    for (final entry in _channel.presenceState()) {
      for (final p in entry.presences) {
        final uid = p.payload['user_id'] as String?;
        if (uid == null) continue;
        seen[uid] = _Participant(
          uid: uid,
          name: p.payload['name'] as String? ?? '?',
          handRaised: p.payload['hand_raised'] as bool? ?? false,
        );
      }
    }
    if (!mounted) return;
    setState(() => _participants = seen.values.toList()..sort((a, b) => a.name.compareTo(b.name)));
  }

  Future<void> _toggleHand() async {
    setState(() => _handRaised = !_handRaised);
    await _track();
  }

  Future<void> _leave() async {
    await _channel.untrack();
    await supa.removeChannel(_channel);
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _channel.untrack();
    supa.removeChannel(_channel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(center: const Alignment(0, -0.6), radius: 1, colors: [c.tealSoft, Colors.transparent]),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PgBackButton(onTap: _leave),
                      Row(
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: c.teal, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('LIVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.teal)),
                        ],
                      ),
                      const SizedBox(width: 38),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.groupName, style: PgText.serif(size: 22, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        '${_participants.length} in the room',
                        style: TextStyle(fontSize: 13, color: c.dim),
                      ),
                      const SizedBox(height: 22),
                      if (_participants.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text('Waiting for others to join…', style: TextStyle(fontSize: 13.5, color: c.faint)),
                        )
                      else
                        GridView.count(
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.75,
                          children: [
                            for (final p in _participants)
                              _MemberAvatar(name: p.name, host: p.uid == widget.createdBy, handRaised: p.handRaised),
                          ],
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 34),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _toggleHand,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _handRaised ? c.teal : c.line),
                            backgroundColor: _handRaised ? c.tealSoft : null,
                            padding: const EdgeInsets.all(15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: Icon(Icons.back_hand_outlined, size: 18, color: _handRaised ? c.teal : c.text),
                          label: Text(_handRaised ? 'Hand raised' : 'Raise hand',
                              style: TextStyle(color: _handRaised ? c.teal : c.text, fontSize: 14.5, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _leave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.danger,
                            padding: const EdgeInsets.all(15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Leave', style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.name, required this.host, required this.handRaised});
  final String name;
  final bool host;
  final bool handRaised;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: host ? null : c.surface2,
                gradient: host ? LinearGradient(colors: [c.teal, c.tealDeep], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                border: handRaised ? Border.all(color: c.amber, width: 2) : null,
              ),
              alignment: Alignment.center,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(fontWeight: FontWeight.w800, color: host ? c.onTeal : c.dim)),
            ),
            if (handRaised)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: c.amber, shape: BoxShape.circle, border: Border.all(color: c.bg, width: 2)),
                  child: Icon(Icons.back_hand_rounded, size: 10, color: c.onAmber),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: host ? null : c.dim)),
      ],
    );
  }
}
