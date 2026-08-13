import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';
import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../core/errors/friendly_error.dart';
import '../../data/models/companion.dart';
import '../../state/companion_provider.dart';
import '../../state/prayer_invite_provider.dart';
import '../../state/profile_provider.dart';
import '../../widgets/pg_back_button.dart';

class TogetherScreen extends ConsumerWidget {
  const TogetherScreen({super.key, required this.companionRowId, this.inviteId});
  final String companionRowId;

  /// Set only when this screen was reached by tapping "Pray live" — lets
  /// the requester's session watch that specific invite for a decline,
  /// which Realtime Presence alone can't express (it can only ever say
  /// "not here yet", not "said no").
  final String? inviteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(companionDetailProvider(companionRowId));
    final myName = ref.watch(profileProvider).valueOrNull?.name ?? 'You';

    return Scaffold(
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _NoCompanionState(
          message: friendlyErrorMessage(e),
          onClose: () => context.pop(),
        ),
        data: (state) => _TogetherSession(
          companion: state.companion,
          myName: myName,
          inviteId: inviteId,
        ),
      ),
    );
  }
}

class _NoCompanionState extends StatelessWidget {
  const _NoCompanionState({required this.message, required this.onClose});
  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.diversity_1_outlined, size: 40, color: c.dim),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.6, color: c.dim)),
            const SizedBox(height: 22),
            TextButton(onPressed: onClose, child: const Text('Close')),
          ],
        ),
      ),
    );
  }
}

class _TogetherSession extends ConsumerStatefulWidget {
  const _TogetherSession({required this.companion, required this.myName, this.inviteId});
  final Companion companion;
  final String myName;
  final String? inviteId;

  @override
  ConsumerState<_TogetherSession> createState() => _TogetherSessionState();
}

class _TogetherSessionState extends ConsumerState<_TogetherSession> {
  late final String _myUid = supa.auth.currentUser!.id;
  late final RealtimeChannel _channel;
  StreamSubscription<String?>? _inviteSub;
  Timer? _ticker;
  DateTime? _myJoinedAt;
  DateTime? _theirJoinedAt;
  Duration _elapsed = Duration.zero;
  bool _declined = false;

  bool get _bothPresent => _myJoinedAt != null && _theirJoinedAt != null;

  @override
  void initState() {
    super.initState();
    _channel = supa.channel(
      'together-${widget.companion.companionRowId}',
      opts: const RealtimeChannelConfig(enabled: true),
    );
    _channel
        .onPresenceSync((_) => _handleSync())
        .subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _channel.track({
          'user_id': _myUid,
          'name': widget.myName,
          'joined_at': DateTime.now().toIso8601String(),
        });
      }
    });

    final inviteId = widget.inviteId;
    if (inviteId != null) {
      _inviteSub = ref
          .read(prayerInviteRepositoryProvider)
          .watchStatus(inviteId)
          .listen((status) {
        if (mounted && status == 'declined') setState(() => _declined = true);
      });
    }
  }

  void _handleSync() {
    DateTime? mine;
    DateTime? theirs;
    for (final entry in _channel.presenceState()) {
      for (final p in entry.presences) {
        final uid = p.payload['user_id'] as String?;
        final joinedAt =
            DateTime.tryParse(p.payload['joined_at'] as String? ?? '');
        if (uid == _myUid) {
          mine = joinedAt;
        } else if (uid == widget.companion.otherUserId) {
          theirs = joinedAt;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _myJoinedAt = mine;
      _theirJoinedAt = theirs;
    });
    _syncTicker();
  }

  void _syncTicker() {
    _ticker?.cancel();
    if (!_bothPresent) return;
    final start =
        _myJoinedAt!.isAfter(_theirJoinedAt!) ? _myJoinedAt! : _theirJoinedAt!;
    void tick() {
      if (!mounted) return;
      setState(() => _elapsed = DateTime.now().difference(start));
    }

    tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<void> _leave() async {
    _ticker?.cancel();
    await _channel.untrack();
    await supa.removeChannel(_channel);
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _inviteSub?.cancel();
    _channel.untrack();
    supa.removeChannel(_channel);
    super.dispose();
  }

  String get _label {
    final m = _elapsed.inMinutes;
    final s = _elapsed.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final myInitial =
        widget.myName.isNotEmpty ? widget.myName[0].toUpperCase() : '?';
    final theirInitial = widget.companion.otherName.isNotEmpty
        ? widget.companion.otherName[0].toUpperCase()
        : '?';

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                  center: const Alignment(0, -0.5),
                  radius: 1,
                  colors: [c.tealSoft, Colors.transparent]),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PgBackButton(icon: Icons.close_rounded, onTap: _leave),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: c.tealSoft,
                          borderRadius: BorderRadius.circular(100)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: c.teal, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(_bothPresent ? 'LIVE TOGETHER' : 'WAITING',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: c.teal)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 38),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 52,
                        child: Stack(
                          children: [
                            _Avatar(
                                letter: myInitial,
                                colors: [c.teal, c.tealDeep],
                                fg: c.onTeal,
                                dim: false),
                            Positioned(
                              left: 40,
                              child: _Avatar(
                                letter: theirInitial,
                                colors: [c.amber, const Color(0xFF8A5A1A)],
                                fg: c.onAmber,
                                dim: !_bothPresent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      if (_bothPresent)
                        Text(_label,
                            style: const TextStyle(
                                fontSize: 52, fontWeight: FontWeight.w300))
                      else if (_declined)
                        Text(
                          "${widget.companion.otherName} can't pray right now",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: c.dim),
                        )
                      else
                        Text(
                          'Waiting for ${widget.companion.otherName}…',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: c.dim),
                        ),
                      const SizedBox(height: 26),
                      Container(
                        padding: const EdgeInsets.all(18),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                            color: c.surface,
                            border: Border.all(color: c.line),
                            borderRadius: BorderRadius.circular(18)),
                        child: Column(
                          children: [
                            Text('PRAYING TOGETHER',
                                style: PgText.sans(
                                    size: 11,
                                    weight: FontWeight.w800,
                                    color: c.teal,
                                    letterSpacing: 1)),
                            const SizedBox(height: 8),
                            Text(
                                "Bear ye one another's burdens, and so fulfil the law of Christ.",
                                textAlign: TextAlign.center,
                                style: PgText.serif(size: 17, height: 1.5)),
                            const SizedBox(height: 8),
                            Text('Galatians 6:2',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: c.amber)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 34),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _leave,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: c.line2),
                      padding: const EdgeInsets.all(15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Leave session',
                        style: TextStyle(
                            color: c.dim,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(
      {required this.letter,
      required this.colors,
      required this.fg,
      required this.dim});
  final String letter;
  final List<Color> colors;
  final Color fg;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Opacity(
      opacity: dim ? 0.35 : 1,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          border: Border.all(color: c.bg, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(letter,
            style: TextStyle(fontWeight: FontWeight.w800, color: fg)),
      ),
    );
  }
}
