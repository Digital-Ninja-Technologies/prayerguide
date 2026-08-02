import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/models/pg_group.dart';
import '../../state/groups_provider.dart';
import '../../widgets/pg_back_button.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_card.dart';
import '../../widgets/pg_icon_badge.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        PgBackButton(onTap: () => context.pop()),
                        const SizedBox(width: 12),
                        Text('Groups',
                            style: PgText.serif(size: 26, weight: FontWeight.w600)),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => context.push('/companion'),
                          style: TextButton.styleFrom(
                            backgroundColor: c.surface,
                            side: BorderSide(color: c.line),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 9),
                          ),
                          child: Text('Pray together',
                              style: TextStyle(
                                  color: c.dim,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        PgButton(
                          label: 'New',
                          expand: false,
                          dense: true,
                          icon: Icon(Icons.add_rounded,
                              color: c.onTeal, size: 16),
                          onPressed: () => context.push('/groups/new'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              groupsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, st) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text('Could not load groups.\n$e',
                      style: TextStyle(color: c.danger)),
                ),
                data: (groups) {
                  if (groups.isEmpty)
                    return _EmptyState(
                        onNew: () => context.push('/groups/new'));
                  return Column(
                    children: [
                      for (final g in groups)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PgCard(
                            radius: 18,
                            padding: const EdgeInsets.all(16),
                            onTap: () => _showGroupSheet(context, ref, g),
                            child: Row(
                              children: [
                                PgIconBadge(
                                    icon: Icons.diversity_1_outlined,
                                    color: c.teal,
                                    background: c.tealSoft),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(g.name,
                                          style: const TextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w700)),
                                      Text(
                                          '${g.memberCount} member${g.memberCount == 1 ? '' : 's'}',
                                          style: TextStyle(
                                              fontSize: 12.5, color: c.dim)),
                                    ],
                                  ),
                                ),
                                if (g.meetingTime != null)
                                  Text(g.meetingTime!,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: c.faint)),
                              ],
                            ),
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
    );
  }

  void _showGroupSheet(BuildContext context, WidgetRef ref, PgGroup group) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.name,
                style: PgText.serif(size: 21, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
                '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}${group.meetingTime != null ? ' · ${group.meetingTime}' : ''}',
                style: TextStyle(fontSize: 13, color: c.dim)),
            if (group.inviteCode != null) ...[
              const SizedBox(height: 18),
              Text('INVITE CODE',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: c.dim)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
                decoration: BoxDecoration(
                    color: c.surface2,
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(group.inviteCode!,
                          style: TextStyle(
                              fontSize: 14.5,
                              color: c.text,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace')),
                    ),
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: group.inviteCode!));
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                                content: Text('Invite code copied')));
                      },
                      child: Text('Copy',
                          style: TextStyle(
                              color: c.teal,
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: PgButton(
                label: 'Join live room',
                icon: const Icon(Icons.podcasts_rounded,
                    size: 17, color: Colors.white),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/room?groupId=${group.id}');
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: PgButton(
                label: 'Leave group',
                variant: PgButtonVariant.outline,
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await ref.read(groupsProvider.notifier).leave(group.id);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNew});
  final VoidCallback onNew;

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
          Text('No groups yet',
              style: PgText.serif(size: 21, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            width: 260,
            child: Text(
              "Start a prayer group and invite others, or join one with a code someone shared with you.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, height: 1.6, color: c.dim),
            ),
          ),
          const SizedBox(height: 16),
          PgButton(
              label: 'Start or join a group', expand: false, onPressed: onNew),
        ],
      ),
    );
  }
}
