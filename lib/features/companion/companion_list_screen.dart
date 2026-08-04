import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/models/companion.dart';
import '../../state/companion_provider.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_error_state.dart';
import '../../widgets/pg_header.dart';

class CompanionListScreen extends ConsumerWidget {
  const CompanionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final companionsAsync = ref.watch(companionsProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
            child: PgHeader(
              title: 'Companions',
              onBack: () => context.pop(),
              trailing: TextButton.icon(
                onPressed: () => pushInviteCompanion(context, ref),
                style: TextButton.styleFrom(
                  backgroundColor: c.surface,
                  side: BorderSide(color: c.line),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                ),
                icon: Icon(Icons.add_rounded, size: 15, color: c.dim),
                label: Text('Invite',
                    style: TextStyle(
                        color: c.dim,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  companionsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, st) => PgErrorState(
                        error: e,
                        onRetry: () => ref.invalidate(companionsProvider)),
                    data: (companions) {
                      if (companions.isEmpty) {
                        return _EmptyState(
                            onInvite: () => pushInviteCompanion(context, ref));
                      }
                      return Column(
                        children: [
                          for (final companion in companions)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CompanionTile(
                                companion: companion,
                                onTap: () => context.push(
                                    '/companion/${companion.companionRowId}'),
                              ),
                            ),
                        ],
                      );
                    },
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

class _CompanionTile extends StatelessWidget {
  const _CompanionTile({required this.companion, required this.onTap});
  final Companion companion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final initial = companion.otherName.isNotEmpty
        ? companion.otherName[0].toUpperCase()
        : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
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
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: c.onAmber)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(companion.otherName,
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded,
                            size: 14, color: c.amber),
                        const SizedBox(width: 5),
                        Text('${companion.otherStreak}-day streak',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: c.dim)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.faint),
            ],
          ),
        ),
      ),
    );
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
            decoration: BoxDecoration(
                color: c.tealSoft, borderRadius: BorderRadius.circular(24)),
            child: Icon(Icons.diversity_1_outlined, size: 36, color: c.teal),
          ),
          const SizedBox(height: 16),
          Text('Pray with someone',
              style: PgText.serif(size: 21, weight: FontWeight.w600)),
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
          PgButton(
              label: 'Invite a companion', expand: false, onPressed: onInvite),
        ],
      ),
    );
  }
}
