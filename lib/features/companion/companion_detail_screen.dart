import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/supabase/supabase_config.dart';
import '../../core/theme/pg_colors.dart';
import '../../data/models/companion.dart';
import '../../state/companion_provider.dart';
import '../../state/prayer_invite_provider.dart';
import '../../state/profile_provider.dart';
import '../../widgets/pg_error_state.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_section_label.dart';

/// The color a check-in status renders as everywhere on this screen (the
/// Today's check-in buttons and the calendar's dots), so a glance at either
/// one explains the other.
Color _checkinStatusColor(PgColors c, String status) => switch (status) {
      'prayed' => c.teal,
      'later' => c.amber,
      _ => c.dim,
    };

Future<void> _confirmRemove(BuildContext context, WidgetRef ref,
    String companionRowId, String otherName) async {
  final c = context.colors;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('Remove $otherName?'),
      content: const Text(
          "You'll stop sharing check-ins and requests with each other. This can't be undone — you'd need a new invite to pair again."),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Remove', style: TextStyle(color: c.danger)),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await ref
      .read(companionDetailProvider(companionRowId).notifier)
      .removeCompanion();
  if (context.mounted) context.pop();
}

/// Shared by both people in the pair — whoever opens this sees the same
/// check-ins and shared requests, since it's keyed by the `companions` row
/// id rather than "my" companion.
class CompanionDetailScreen extends ConsumerWidget {
  const CompanionDetailScreen({super.key, required this.companionRowId});
  final String companionRowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final detailAsync = ref.watch(companionDetailProvider(companionRowId));

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
            child: PgHeader(
              title:
                  detailAsync.valueOrNull?.companion.otherName ?? 'Companion',
              onBack: () => context.pop(),
              trailing: detailAsync.valueOrNull == null
                  ? null
                  : IconButton(
                      onPressed: () => _confirmRemove(
                          context,
                          ref,
                          companionRowId,
                          detailAsync.value!.companion.otherName),
                      icon: Icon(Icons.person_remove_outlined,
                          size: 20, color: c.danger),
                    ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  detailAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, st) => PgErrorState(
                        error: e,
                        onRetry: () => ref.invalidate(
                            companionDetailProvider(companionRowId))),
                    data: (state) => _CompanionContent(
                        state: state, companionRowId: companionRowId),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanionContent extends ConsumerWidget {
  const _CompanionContent({required this.state, required this.companionRowId});
  final CompanionDetailState state;
  final String companionRowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final companion = state.companion;
    final myStreak = ref.watch(profileProvider).valueOrNull?.streakCount ?? 0;
    final sharedStreak =
        myStreak < companion.otherStreak ? myStreak : companion.otherStreak;
    final initial = companion.otherName.isNotEmpty
        ? companion.otherName[0].toUpperCase()
        : '?';
    final uid = supa.auth.currentUser?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [c.surface2, c.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(22),
          ),
          margin: const EdgeInsets.only(bottom: 18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [c.amber, const Color(0xFF8A5A1A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                ),
                alignment: Alignment.center,
                child: Text(initial,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: c.onAmber)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(companion.otherName,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded,
                            size: 15, color: c.amber),
                        const SizedBox(width: 6),
                        Text('$sharedStreak-day shared streak',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: c.amber)),
                      ],
                    ),
                  ],
                ),
              ),
              Material(
                color: c.tealSoft,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    // Best-effort: push-notify the companion so they find
                    // out even if they're not already in the app — the
                    // Together screen's own Realtime presence covers the
                    // case where they already are. Never blocks getting
                    // into the live session either way.
                    String? inviteId;
                    try {
                      inviteId = await ref
                          .read(prayerInviteRepositoryProvider)
                          .sendInvite(companionRowId);
                    } catch (_) {
                      inviteId = null;
                    }
                    if (context.mounted) {
                      context.push(inviteId == null
                          ? '/together/$companionRowId'
                          : '/together/$companionRowId?inviteId=$inviteId');
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.podcasts_rounded, size: 16, color: c.teal),
                        const SizedBox(width: 6),
                        Text('Pray live',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: c.teal)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Today's check-in",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                  'Let ${companion.otherName} know you prayed — no pressure either way.',
                  style: TextStyle(fontSize: 12.5, color: c.dim)),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final v in const ['prayed', 'later', 'missed'])
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: v == 'missed' ? 0 : 9),
                        child: _CheckinBtn(
                          label: v[0].toUpperCase() + v.substring(1),
                          color: _checkinStatusColor(c, v),
                          active: state.myTodayCheckin == v,
                          onTap: () => ref
                              .read(companionDetailProvider(companionRowId)
                                  .notifier)
                              .setCheckin(v),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const PgSectionLabel('Shared requests'),
        if (state.sharedRequests.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Nothing shared yet. Turn on "Share with companion" when adding a request to carry it here.',
              style: TextStyle(fontSize: 13.5, color: c.faint),
            ),
          )
        else
          for (final r in state.sharedRequests.take(10))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SharedRequestCard(
                isMe: r.userId == uid,
                otherName: companion.otherName,
                category: r.category,
                title: r.title,
                createdAt: r.createdAt,
                onUnshare: r.userId != uid
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: c.surface,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                            title: const Text('Stop sharing this request?'),
                            content: const Text(
                                "It'll no longer show here, but stays in your own Requests list."),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel')),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text('Stop sharing',
                                    style: TextStyle(color: c.danger)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await ref
                              .read(companionDetailProvider(companionRowId)
                                  .notifier)
                              .unshareRequest(r.id);
                        }
                      },
              ),
            ),
        const SizedBox(height: 6),
        const PgSectionLabel('Check-ins'),
        _CheckinCalendar(
          checkins: state.monthCheckins,
          myUserId: uid ?? '',
          otherName: companion.otherName,
        ),
      ],
    );
  }
}

class _CheckinCalendar extends StatelessWidget {
  const _CheckinCalendar({
    required this.checkins,
    required this.myUserId,
    required this.otherName,
  });
  final List<CompanionCheckinEntry> checkins;
  final String myUserId;
  final String otherName;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday % 7;

    // checkins is ordered most-recent-first, so the first entry seen for a
    // given (user, day) pair is that day's latest status.
    final mine = <int, String>{};
    final theirs = <int, String>{};
    for (final entry in checkins) {
      final target = entry.userId == myUserId ? mine : theirs;
      target.putIfAbsent(entry.createdAt.day, () => entry.status);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(monthName,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final d in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                Center(
                  child: Text(d,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: c.faint)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            children: [
              for (var i = 0; i < firstWeekday; i++) const SizedBox(),
              for (var day = 1; day <= daysInMonth; day++)
                _CalendarDayCell(
                  day: day,
                  isToday: day == now.day,
                  mineColor: mine.containsKey(day)
                      ? _checkinStatusColor(c, mine[day]!)
                      : null,
                  theirsColor: theirs.containsKey(day)
                      ? _checkinStatusColor(c, theirs[day]!)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _LegendDot(label: 'You (left)', color: c.dim, outline: true),
              _LegendDot(
                  label: '$otherName (right)', color: c.dim, outline: true),
              _LegendDot(label: 'Prayed', color: c.teal),
              _LegendDot(label: 'Later', color: c.amber),
              _LegendDot(label: 'Missed', color: c.dim),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.isToday,
    required this.mineColor,
    required this.theirsColor,
  });
  final int day;
  final bool isToday;
  final Color? mineColor;
  final Color? theirsColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isToday ? Border.all(color: c.teal, width: 1.5) : null,
          ),
          child: Text('$day',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isToday ? c.teal : c.dim)),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(color: mineColor),
            const SizedBox(width: 3),
            _Dot(color: theirsColor),
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? Colors.transparent,
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(
      {required this.label, required this.color, this.outline = false});
  final String label;
  final Color color;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: outline ? null : color,
            border: outline ? Border.all(color: color, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: c.dim)),
      ],
    );
  }
}

class _SharedRequestCard extends StatelessWidget {
  const _SharedRequestCard({
    required this.isMe,
    required this.otherName,
    required this.category,
    required this.title,
    required this.createdAt,
    this.onUnshare,
  });
  final bool isMe;
  final String otherName;
  final String category;
  final String title;
  final DateTime createdAt;

  /// Non-null only for the current user's own shared requests — a paired
  /// companion can see these but never unshare them on the owner's behalf
  /// (this action is only ever wired up for [isMe] rows). Stops sharing —
  /// the request itself stays in the owner's own Requests list.
  final VoidCallback? onUnshare;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = isMe ? c.amber : c.teal;
    final label = isMe ? 'YOU SHARED' : '${otherName.toUpperCase()} SHARED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800, color: color)),
              Text(_relativeTime(createdAt),
                  style: TextStyle(fontSize: 11.5, color: c.faint)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                    color: c.tealSoft,
                    borderRadius: BorderRadius.circular(100)),
                child: Text(category.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .4,
                        color: c.teal)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600)),
              ),
              if (onUnshare != null)
                InkWell(
                  onTap: onUnshare,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child:
                        Icon(Icons.link_off_rounded, size: 17, color: c.faint),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _CheckinBtn extends StatelessWidget {
  const _CheckinBtn(
      {required this.label,
      required this.color,
      required this.active,
      required this.onTap});
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final onColor = color == c.teal
        ? c.onTeal
        : color == c.amber
            ? c.onAmber
            : Colors.white;
    return Material(
      color: active ? color : c.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: active ? color : c.line)),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: active ? onColor : c.dim)),
        ),
      ),
    );
  }
}
