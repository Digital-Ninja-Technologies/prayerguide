import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/models/bible_note.dart';
import '../../state/bible_notes_provider.dart';
import '../../widgets/pg_pill.dart';

const _chapterRef = 'Psalm 23';

const _verses = [
  (1, 'The LORD is my shepherd; I shall not want.'),
  (2, 'He maketh me to lie down in green pastures: he leadeth me beside the still waters.'),
  (3, "He restoreth my soul: he leadeth me in the paths of righteousness for his name's sake."),
  (
    4,
    'Yea, though I walk through the valley of the shadow of death, I will fear no evil: for thou art with me; thy rod and thy staff they comfort me.'
  ),
  (
    5,
    'Thou preparest a table before me in the presence of mine enemies: thou anointest my head with oil; my cup runneth over.'
  ),
  (
    6,
    'Surely goodness and mercy shall follow me all the days of my life: and I will dwell in the house of the LORD for ever.'
  ),
];

class BibleScreen extends ConsumerWidget {
  const BibleScreen({super.key});

  Future<void> _toggleBookmark(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(bibleNotesProvider.notifier);
    final existing = notifier.bookmarkFor(_chapterRef);
    if (existing != null) {
      await notifier.remove(existing.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bookmark removed')));
      }
    } else {
      await notifier.add(kind: 'bookmark', reference: _chapterRef);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$_chapterRef bookmarked')));
      }
    }
  }

  Future<void> _openVerseActions(BuildContext context, WidgetRef ref, int verseNum, String text) async {
    final c = context.colors;
    final reference = '$_chapterRef:$verseNum';
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: c.line2, borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: Icon(Icons.brush_outlined, color: c.amber),
              title: const Text('Highlight this verse'),
              onTap: () => Navigator.of(context).pop('highlight'),
            ),
            ListTile(
              leading: Icon(Icons.sticky_note_2_outlined, color: c.teal),
              title: const Text('Add a note'),
              onTap: () => Navigator.of(context).pop('note'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == 'highlight') {
      await ref.read(bibleNotesProvider.notifier).add(kind: 'highlight', reference: reference, verseText: text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Highlighted $reference')));
      }
    } else if (action == 'note' && context.mounted) {
      await _promptForNote(context, ref, reference, text);
    }
  }

  Future<void> _promptForNote(BuildContext context, WidgetRef ref, String reference, String verseText) async {
    final c = context.colors;
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Note on $reference'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Write your note…'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (note != null && note.isNotEmpty) {
      await ref.read(bibleNotesProvider.notifier).add(kind: 'note', reference: reference, verseText: verseText, note: note);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Note saved on $reference')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final notesAsync = ref.watch(bibleNotesProvider);
    final notes = notesAsync.valueOrNull ?? const <BibleNote>[];
    final isBookmarked = notes.any((n) => n.kind == 'bookmark' && n.reference == _chapterRef);
    final highlightedVerses = {
      for (final n in notes)
        if (n.kind == 'highlight' && n.reference.startsWith('$_chapterRef:'))
          int.tryParse(n.reference.split(':').last),
    }..removeWhere((v) => v == null);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 6, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              children: [
                const PgPill(label: 'Read', active: true),
                const SizedBox(width: 8),
                PgPill(label: 'Reading plans', onTap: () => context.push('/plans')),
                const SizedBox(width: 8),
                PgPill(label: 'Devotional', onTap: () => context.push('/devotional')),
                const SizedBox(width: 8),
                PgPill(label: 'Notes', onTap: () => context.pushOnce('/bible-notes')),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Psalm 23', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(width: 6),
                      Icon(Icons.expand_more_rounded, size: 15, color: c.text),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _RoundIcon(
                      icon: isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: isBookmarked ? c.teal : null,
                      onTap: () => _toggleBookmark(context, ref),
                    ),
                    const SizedBox(width: 6),
                    _RoundIcon(
                      icon: Icons.format_list_bulleted_rounded,
                      onTap: () => context.pushOnce('/bible-notes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Psalm 23', style: PgText.serif(size: 26, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('A Psalm of David · KJV', style: TextStyle(fontSize: 13, color: c.dim, fontWeight: FontWeight.w600)),
                const SizedBox(height: 22),
                for (final v in _verses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GestureDetector(
                      onTap: () => _openVerseActions(context, ref, v.$1, v.$2),
                      child: Container(
                        padding: highlightedVerses.contains(v.$1)
                            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
                            : EdgeInsets.zero,
                        decoration: highlightedVerses.contains(v.$1)
                            ? BoxDecoration(color: c.amberSoft, borderRadius: BorderRadius.circular(6))
                            : null,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${v.$1} ',
                                style: TextStyle(
                                  color: highlightedVerses.contains(v.$1) ? c.amber : c.teal,
                                  fontFamily: 'Manrope',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: v.$2,
                                style: PgText.serif(size: 18.5, height: 1.85, color: c.text),
                              ),
                            ],
                          ),
                        ),
                      ),
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

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, this.onTap, this.color});
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11), side: BorderSide(color: c.line)),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: SizedBox(width: 38, height: 38, child: Icon(icon, size: 18, color: color ?? c.dim)),
      ),
    );
  }
}
