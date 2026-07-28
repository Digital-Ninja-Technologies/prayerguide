import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/bible/bible_library.dart';
import '../../data/models/bible_note.dart';
import '../../state/bible_library_provider.dart';
import '../../state/bible_notes_provider.dart';
import '../../widgets/pg_pill.dart';
import 'bible_picker_sheet.dart';

class BibleScreen extends ConsumerStatefulWidget {
  const BibleScreen({super.key});

  @override
  ConsumerState<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends ConsumerState<BibleScreen> {
  String _book = 'Psalms';
  int _chapter = 23;

  String get _chapterRef => '$_book $_chapter';

  Future<void> _openPicker(BibleLibrary library) async {
    final result = await showBiblePickerSheet(context, library: library, initialBook: _book);
    if (result != null) {
      setState(() {
        _book = result.$1;
        _chapter = result.$2;
      });
    }
  }

  void _shiftChapter(int delta, BibleLibrary library) {
    var bookIndex = library.books.indexWhere((b) => b.name == _book);
    if (bookIndex == -1) return;
    var chapter = _chapter + delta;

    if (chapter < 1) {
      bookIndex -= 1;
      if (bookIndex < 0) return;
      final prevBook = library.books[bookIndex];
      setState(() {
        _book = prevBook.name;
        _chapter = prevBook.chapterCount;
      });
      return;
    }

    final chapterCount = library.chapterCountFor(_book);
    if (chapter > chapterCount) {
      bookIndex += 1;
      if (bookIndex >= library.books.length) return;
      setState(() {
        _book = library.books[bookIndex].name;
        _chapter = 1;
      });
      return;
    }

    setState(() => _chapter = chapter);
  }

  Future<void> _toggleBookmark(WidgetRef ref) async {
    final notifier = ref.read(bibleNotesProvider.notifier);
    final existing = notifier.bookmarkFor(_chapterRef);
    if (existing != null) {
      await notifier.remove(existing.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bookmark removed')));
    } else {
      await notifier.add(kind: 'bookmark', reference: _chapterRef);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$_chapterRef bookmarked')));
    }
  }

  Future<void> _openVerseActions(WidgetRef ref, int verseNum, String text) async {
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

    if (!mounted) return;
    if (action == 'highlight') {
      await ref.read(bibleNotesProvider.notifier).add(kind: 'highlight', reference: reference, verseText: text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Highlighted $reference')));
    } else if (action == 'note') {
      await _promptForNote(ref, reference, text);
    }
  }

  Future<void> _promptForNote(WidgetRef ref, String reference, String verseText) async {
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Note saved on $reference')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final libraryAsync = ref.watch(bibleLibraryProvider);
    final notesAsync = ref.watch(bibleNotesProvider);
    final notes = notesAsync.valueOrNull ?? const <BibleNote>[];
    final isBookmarked = notes.any((n) => n.kind == 'bookmark' && n.reference == _chapterRef);
    final highlightedVerses = <int>{};
    for (final n in notes) {
      if (n.kind == 'highlight' && n.reference.startsWith('$_chapterRef:')) {
        final verseNum = int.tryParse(n.reference.substring(_chapterRef.length + 1));
        if (verseNum != null) highlightedVerses.add(verseNum);
      }
    }

    return libraryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not load the Bible text.\n$e', textAlign: TextAlign.center, style: TextStyle(color: c.danger)),
        ),
      ),
      data: (library) {
        final verses = library.versesFor(_book, _chapter);
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
                    Row(
                      children: [
                        _RoundIcon(icon: Icons.chevron_left_rounded, onTap: () => _shiftChapter(-1, library)),
                        const SizedBox(width: 6),
                        Material(
                          color: c.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: c.line)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openPicker(library),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_chapterRef, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Icon(Icons.expand_more_rounded, size: 15, color: c.text),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _RoundIcon(icon: Icons.chevron_right_rounded, onTap: () => _shiftChapter(1, library)),
                      ],
                    ),
                    Row(
                      children: [
                        _RoundIcon(
                          icon: isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: isBookmarked ? c.teal : null,
                          onTap: () => _toggleBookmark(ref),
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
                    Text(_chapterRef, style: PgText.serif(size: 26, weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('King James Version', style: TextStyle(fontSize: 13, color: c.dim, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 22),
                    if (verses.isEmpty)
                      Text('This chapter is unavailable.', style: TextStyle(fontSize: 14, color: c.dim))
                    else
                      for (var i = 0; i < verses.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: GestureDetector(
                            onTap: () => _openVerseActions(ref, i + 1, verses[i]),
                            child: Container(
                              padding: highlightedVerses.contains(i + 1)
                                  ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
                                  : EdgeInsets.zero,
                              decoration: highlightedVerses.contains(i + 1)
                                  ? BoxDecoration(color: c.amberSoft, borderRadius: BorderRadius.circular(6))
                                  : null,
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${i + 1} ',
                                      style: TextStyle(
                                        color: highlightedVerses.contains(i + 1) ? c.amber : c.teal,
                                        fontFamily: 'Manrope',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    TextSpan(
                                      text: verses[i],
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
      },
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
