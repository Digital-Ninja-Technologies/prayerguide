import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_config.dart';
import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../state/companion_provider.dart';
import '../../state/profile_provider.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_section_label.dart';

class CompanionScreen extends ConsumerWidget {
  const CompanionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final companionAsync = ref.watch(companionProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(
              title: 'Companion',
              onBack: () => context.pop(),
              trailing: TextButton.icon(
                onPressed: () => context.push('/companion/invite'),
                style: TextButton.styleFrom(
                  backgroundColor: c.surface,
                  side: BorderSide(color: c.line),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                ),
                icon: Icon(Icons.add_rounded, size: 15, color: c.dim),
                label: Text('Invite', style: TextStyle(color: c.dim, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
            companionAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text('Could not load your companion.\n$e', style: TextStyle(color: c.danger)),
              ),
              data: (state) {
                if (state.companion == null) return _EmptyState(onInvite: () => context.push('/companion/invite'));
                return _CompanionContent(state: state);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanionContent extends ConsumerWidget {
  const _CompanionContent({required this.state});
  final CompanionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final companion = state.companion!;
    final myStreak = ref.watch(profileProvider).valueOrNull?.streakCount ?? 0;
    final sharedStreak = myStreak < companion.otherStreak ? myStreak : companion.otherStreak;
    final initial = companion.otherName.isNotEmpty ? companion.otherName[0].toUpperCase() : '?';
    final uid = supa.auth.currentUser?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c.surface2, c.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
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
                  gradient: LinearGradient(colors: [c.amber, const Color(0xFF8A5A1A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                alignment: Alignment.center,
                child: Text(initial, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.onAmber)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(companion.otherName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded, size: 15, color: c.amber),
                        const SizedBox(width: 6),
                        Text('$sharedStreak-day shared streak', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.amber)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Today's check-in", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Let ${companion.otherName} know you prayed — no pressure either way.', style: TextStyle(fontSize: 12.5, color: c.dim)),
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
                          onTap: () => ref.read(companionProvider.notifier).setCheckin(v),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const PgSectionLabel('Recent check-ins'),
        if (state.recentCheckins.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No check-ins yet.', style: TextStyle(fontSize: 13.5, color: c.faint)),
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

class _CheckinBtn extends StatelessWidget {
  const _CheckinBtn({required this.label, required this.active, required this.onTap});
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
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: active ? c.teal : c.line)),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: active ? c.onTeal : c.dim)),
        ),
      ),
    );
  }
}

class _CheckinCard extends StatelessWidget {
  const _CheckinCard({required this.isMe, required this.otherName, required this.status, required this.createdAt});
  final bool isMe;
  final String otherName;
  final String status;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = isMe ? c.amber : c.teal;
    final label = isMe ? 'YOU' : otherName.toUpperCase();
    final statusLabel = switch (status) { 'prayed' => 'Prayed', 'later' => 'Praying later', _ => 'Missed today' };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
              Text(_relativeTime(createdAt), style: TextStyle(fontSize: 11.5, color: c.faint)),
            ],
          ),
          const SizedBox(height: 5),
          Text(statusLabel, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onInvite});
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(color: c.tealSoft, borderRadius: BorderRadius.circular(24)),
            child: Icon(Icons.diversity_1_outlined, size: 36, color: c.teal),
          ),
          const SizedBox(height: 16),
          Text('Pray with someone', style: PgText.serif(size: 21, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            width: 260,
            child: Text(
              "You don't have a prayer companion yet. Invite someone you trust to share encouragement and a shared streak.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, height: 1.6, color: c.dim),
            ),
          ),
          const SizedBox(height: 16),
          PgButton(label: 'Invite a companion', expand: false, onPressed: onInvite),
        ],
      ),
    );
  }
}
