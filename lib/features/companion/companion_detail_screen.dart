import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_config.dart';
import '../../core/theme/pg_colors.dart';
import '../../state/companion_provider.dart';
import '../../state/profile_provider.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_section_label.dart';

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(
              title:
                  detailAsync.valueOrNull?.companion.otherName ?? 'Companion',
              onBack: () => context.pop(),
            ),
            detailAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text('Could not load this companion.\n$e',
                    style: TextStyle(color: c.danger)),
              ),
              data: (state) => _CompanionContent(
                  state: state, companionRowId: companionRowId),
            ),
          ],
        ),
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
                  onTap: () => context.push('/together/$companionRowId'),
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
              ),
            ),
        const SizedBox(height: 6),
        const PgSectionLabel('Recent check-ins'),
        if (state.recentCheckins.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No check-ins yet.',
                style: TextStyle(fontSize: 13.5, color: c.faint)),
          )
        else
          for (final entry in state.recentCheckins.take(10))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CheckinCard(
                isMe: entry.userId == uid,
                otherName: companion.otherName,
                status: entry.status,
                createdAt: entry.createdAt,
              ),
            ),
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
  });
  final bool isMe;
  final String otherName;
  final String category;
  final String title;
  final DateTime createdAt;

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
          Text(title,
              style:
                  const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
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
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: active ? c.teal : c.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: active ? c.teal : c.line)),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: active ? c.onTeal : c.dim)),
        ),
      ),
    );
  }
}

class _CheckinCard extends StatelessWidget {
  const _CheckinCard(
      {required this.isMe,
      required this.otherName,
      required this.status,
      required this.createdAt});
  final bool isMe;
  final String otherName;
  final String status;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = isMe ? c.amber : c.teal;
    final label = isMe ? 'YOU' : otherName.toUpperCase();
    final statusLabel = switch (status) {
      'prayed' => 'Prayed',
      'later' => 'Praying later',
      _ => 'Missed today'
    };
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
          const SizedBox(height: 5),
          Text(statusLabel,
              style:
                  const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
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
