import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/models/bible_note.dart';
import '../../state/bible_notes_provider.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_pill.dart';

const _tabs = [
  ('highlight', 'Highlights'),
  ('bookmark', 'Bookmarks'),
  ('note', 'Notes'),
];

class BibleNotesScreen extends ConsumerStatefulWidget {
  const BibleNotesScreen({super.key});

  @override
  ConsumerState<BibleNotesScreen> createState() => _BibleNotesScreenState();
}

class _BibleNotesScreenState extends ConsumerState<BibleNotesScreen> {
  String _kind = 'highlight';

  Future<void> _confirmDelete(BibleNote note) async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Remove this?'),
        content: Text(note.reference),
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
    if (confirmed == true) {
      await ref.read(bibleNotesProvider.notifier).remove(note.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final notesAsync = ref.watch(bibleNotesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
              child: PgHeader(
                  title: 'Bookmarks & Notes', onBack: () => context.pop()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
              child: Row(
                children: [
                  for (final t in _tabs)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: PgPill(
                          label: t.$2,
                          active: _kind == t.$1,
                          onTap: () => setState(() => _kind = t.$1)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: notesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Could not load your notes.\n$e',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: c.danger)),
                  ),
                ),
                data: (notes) {
                  final filtered = notes.where((n) => n.kind == _kind).toList();
                  if (filtered.isEmpty) {
                    return Center(child: _EmptyState(kind: _kind));
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
                    children: [
                      for (final n in filtered)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onLongPress: () => _confirmDelete(n),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 15),
                              decoration: BoxDecoration(
                                color: c.surface,
                                border: Border.all(color: c.line),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                      width: 3,
                                      height: 40,
                                      color: n.kind == 'highlight'
                                          ? c.amber
                                          : c.teal),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          n.reference,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: n.kind == 'highlight'
                                                ? c.amber
                                                : c.teal,
                                          ),
                                        ),
                                        if (n.verseText != null) ...[
                                          const SizedBox(height: 6),
                                          Text(n.verseText!,
                                              style: PgText.serif(
                                                  size: 15.5, height: 1.5)),
                                        ],
                                        if (n.note != null &&
                                            n.note!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(n.note!,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: c.dim,
                                                  fontStyle: FontStyle.italic)),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Hold an entry to remove it',
                              style: TextStyle(fontSize: 11.5, color: c.faint)),
                        ),
                      ),
                    ],
                  );
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
  const _EmptyState({required this.kind});
  final String kind;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = switch (kind) {
      'highlight' => 'highlights',
      'bookmark' => 'bookmarks',
      _ => 'notes',
    };
    final icon = switch (kind) {
      'highlight' => Icons.brush_outlined,
      'bookmark' => Icons.bookmark_border_rounded,
      _ => Icons.sticky_note_2_outlined,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
                color: c.tealSoft, borderRadius: BorderRadius.circular(22)),
            child: Icon(icon, size: 32, color: c.teal),
          ),
          const SizedBox(height: 16),
          Text('No $label yet',
              style: PgText.serif(size: 19, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Tap a verse while reading to $label it.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: c.dim, height: 1.5),
          ),
        ],
      ),
    );
  }
}
