import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/security/encryption_service.dart';
import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/models/journal_entry.dart';
import '../../state/journal_provider.dart';
import '../../state/repo_providers.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_card.dart';
import '../../widgets/pg_passphrase_unlock.dart';
import '../../widgets/pg_pill.dart';

const _types = ['All', 'Gratitude', 'Request', 'Testimony', 'Reflection'];

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  String _filter = 'All';

  Color _tagColor(String type, PgColors c) {
    switch (type) {
      case 'Gratitude':
        return c.amber;
      case 'Request':
      case 'Testimony':
        return c.teal;
      default:
        return c.dim;
    }
  }

  Color _tagBg(String type, PgColors c) {
    switch (type) {
      case 'Gratitude':
        return c.amberSoft;
      case 'Request':
      case 'Testimony':
        return c.tealSoft;
      default:
        return c.surface2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final entriesAsync = ref.watch(journalProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Journal', style: PgText.serif(size: 26, weight: FontWeight.w600)),
                PgButton(
                  label: 'New',
                  expand: false,
                  dense: true,
                  icon: Icon(Icons.add_rounded, color: c.onTeal, size: 16),
                  onPressed: () => context.push('/journal/new'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => e is PassphraseRequiredException
                  ? Center(
                      child: PgPassphraseUnlock(
                        uid: ref.read(currentUserIdProvider)!,
                        onUnlocked: () => ref.invalidate(journalProvider),
                      ),
                    )
                  : Center(
                      child: Text('Could not load your journal.\n$e',
                          textAlign: TextAlign.center, style: TextStyle(color: c.danger)),
                    ),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(child: _EmptyState(onNew: () => context.push('/journal/new')));
                }
                final filtered =
                    _filter == 'All' ? entries : entries.where((e) => e.type == _filter).toList();
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final t in _types)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: PgPill(label: t, active: _filter == t, onTap: () => setState(() => _filter = t)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      for (final e in filtered) _EntryCard(entry: e, tagColor: _tagColor(e.type, c), tagBg: _tagBg(e.type, c)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.tagColor, required this.tagBg});

  final JournalEntry entry;
  final Color tagColor;
  final Color tagBg;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PgCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(100)),
                  child: Text(entry.type.toUpperCase(),
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: .5, color: tagColor)),
                ),
                Text(_friendlyDate(entry.createdAt), style: TextStyle(fontSize: 12, color: c.faint, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 9),
            Text(entry.title, style: PgText.serif(size: 17, weight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text(entry.excerpt, style: TextStyle(fontSize: 13.5, height: 1.55, color: c.dim)),
          ],
        ),
      ),
    );
  }

  String _friendlyDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    if (that == today) return 'Today';
    if (that == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMM d').format(d);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNew});
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(color: c.tealSoft, borderRadius: BorderRadius.circular(24)),
            child: Icon(Icons.edit_note_rounded, size: 36, color: c.teal),
          ),
          const SizedBox(height: 16),
          Text('Your journal is quiet', style: PgText.serif(size: 21, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            width: 250,
            child: Text(
              'Capture a prayer request, a moment of gratitude, or a testimony of what God has done.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, height: 1.6, color: c.dim),
            ),
          ),
          const SizedBox(height: 16),
          PgButton(label: 'Write your first entry', expand: false, onPressed: onNew),
        ],
      ),
    );
  }
}
