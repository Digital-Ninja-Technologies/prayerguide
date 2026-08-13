import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/bible/bible_library.dart';
import '../../data/bible/reading_plan_schedule.dart';
import '../../data/models/bible_note.dart';
import '../../state/bible_library_provider.dart';
import '../../state/bible_notes_provider.dart';
import '../../state/reading_plan_provider.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_error_state.dart';
import '../../widgets/pg_pill.dart';
import 'bible_picker_sheet.dart';

class BibleScreen extends ConsumerStatefulWidget {
  const BibleScreen({
    super.key,
    this.initialBook,
    this.initialChapter,
    this.planKey,
    this.planDay,
  });

  /// Optional deep-link target (e.g. from a Reading Plan's "Read Day N").
  /// When absent, the reader defaults to Genesis 1.
  final String? initialBook;
  final int? initialChapter;

  /// When both are set (arrived here via a Reading Plan's "Read Day N"
  /// button), a fixed "Mark Day N Done" button is shown above the bottom
  /// nav bar so the day can be marked complete without leaving the reader.
  final String? planKey;
  final int? planDay;

  @override
  ConsumerState<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends ConsumerState<BibleScreen> {
  late String _book = widget.initialBook ?? 'Genesis';
  late int _chapter = widget.initialChapter ?? 1;
  late String? _planKey = widget.planKey;
  late int? _planDay = widget.planDay;
  bool _marking = false;

  bool _searching = false;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  List<BibleSearchHit> _searchResults = const [];
  bool _searchedNoMatch = false;
  int? _pendingScrollToVerse;
  final _verseKeys = <int, GlobalKey>{};

  final _tts = FlutterTts();
  bool _speaking = false;

  String get _chapterRef => '$_book $_chapter';

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _speaking = false);
    });
  }

  Future<void> _toggleReadAloud(List<String> verses) async {
    if (_speaking) {
      await _tts.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    if (verses.isEmpty) return;
    final text =
        [for (var i = 0; i < verses.length; i++) '${i + 1}. ${verses[i]}'].join(' ');
    setState(() => _speaking = true);
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.42);
    await _tts.speak(text);
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchController.clear();
        _searchResults = const [];
        _searchedNoMatch = false;
      }
    });
    if (_searching) _searchFocus.requestFocus();
  }

  void _runSearch(BibleLibrary library) {
    final query = _searchController.text;
    final ref = library.parseReference(query);
    if (ref != null) {
      _jumpTo(ref.book, ref.chapter, verse: ref.verse);
      return;
    }
    final hits = library.searchText(query);
    setState(() {
      _searchResults = hits;
      _searchedNoMatch = hits.isEmpty;
    });
  }

  void _jumpTo(String book, int chapter, {int? verse}) {
    _stopReading();
    setState(() {
      _book = book;
      _chapter = chapter;
      _searching = false;
      _searchResults = const [];
      _searchedNoMatch = false;
      _searchController.clear();
      _pendingScrollToVerse = verse;
    });
    _searchFocus.unfocus();
    if (verse != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToPendingVerse());
    }
  }

  void _scrollToPendingVerse() {
    final verse = _pendingScrollToVerse;
    if (verse == null) return;
    final key = _verseKeys[verse];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 350), alignment: 0.15);
    }
    _pendingScrollToVerse = null;
  }

  @override
  void dispose() {
    _tts.stop();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BibleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The Bible tab stays mounted across navigations (StatefulShellRoute), so
    // a fresh deep link (different book/chapter query params) won't remount
    // this state — apply it explicitly instead.
    final book = widget.initialBook;
    final chapter = widget.initialChapter;
    if (book != null &&
        chapter != null &&
        (book != _book || chapter != _chapter)) {
      if (book != oldWidget.initialBook ||
          chapter != oldWidget.initialChapter) {
        _stopReading();
        setState(() {
          _book = book;
          _chapter = chapter;
          _planKey = widget.planKey;
          _planDay = widget.planDay;
        });
      }
    }
  }

  Future<void> _markPlanDayDone() async {
    final planKey = _planKey;
    if (planKey == null) return;
    final def = readingPlanDefs[planKey];
    if (def == null) return;
    setState(() => _marking = true);
    try {
      await ref.read(readingPlanProvider.notifier).markDayComplete(
            planKey: planKey,
            totalDays: def.totalDays,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Day ${_planDay ?? ''} marked done'.trim())),
        );
        setState(() {
          _planKey = null;
          _planDay = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update your progress: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  Future<void> _stopReading() async {
    if (_speaking) {
      await _tts.stop();
      if (mounted) setState(() => _speaking = false);
    }
  }

  Future<void> _openPicker(BibleLibrary library) async {
    final result = await showBiblePickerSheet(context,
        library: library, initialBook: _book);
    if (result != null) {
      await _stopReading();
      setState(() {
        _book = result.$1;
        _chapter = result.$2;
      });
    }
  }

  void _shiftChapter(int delta, BibleLibrary library) {
    _stopReading();
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
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Bookmark removed')));
      }
    } else {
      await notifier.add(kind: 'bookmark', reference: _chapterRef);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$_chapterRef bookmarked')));
      }
    }
  }

  Future<void> _openVerseActions(
      WidgetRef ref, int verseNum, String text) async {
    final c = context.colors;
    final reference = '$_chapterRef:$verseNum';
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: c.line2, borderRadius: BorderRadius.circular(2))),
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
      await ref
          .read(bibleNotesProvider.notifier)
          .add(kind: 'highlight', reference: reference, verseText: text);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Highlighted $reference')));
      }
    } else if (action == 'note') {
      await _promptForNote(ref, reference, text);
    }
  }

  Future<void> _promptForNote(
      WidgetRef ref, String reference, String verseText) async {
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
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (note != null && note.isNotEmpty) {
      await ref.read(bibleNotesProvider.notifier).add(
          kind: 'note', reference: reference, verseText: verseText, note: note);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Note saved on $reference')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final libraryAsync = ref.watch(bibleLibraryProvider);
    final notesAsync = ref.watch(bibleNotesProvider);
    final notes = notesAsync.valueOrNull ?? const <BibleNote>[];
    final isBookmarked =
        notes.any((n) => n.kind == 'bookmark' && n.reference == _chapterRef);
    final highlightedVerses = <int>{};
    for (final n in notes) {
      if (n.kind == 'highlight' && n.reference.startsWith('$_chapterRef:')) {
        final verseNum =
            int.tryParse(n.reference.substring(_chapterRef.length + 1));
        if (verseNum != null) highlightedVerses.add(verseNum);
      }
    }

    return libraryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: PgErrorState(
            error: e, onRetry: () => ref.invalidate(bibleLibraryProvider)),
      ),
      data: (library) {
        final verses = library.versesFor(_book, _chapter);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                children: [
                  const PgPill(label: 'Read', active: true),
                  const SizedBox(width: 8),
                  PgPill(
                      label: 'Reading plans',
                      onTap: () => context.push('/plans')),
                  const SizedBox(width: 8),
                  PgPill(
                      label: 'Devotional',
                      onTap: () => context.push('/devotional')),
                  const SizedBox(width: 8),
                  PgPill(
                      label: 'Notes',
                      onTap: () => context.pushOnce('/bible-notes')),
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
                      _RoundIcon(
                          icon: Icons.chevron_left_rounded,
                          onTap: () => _shiftChapter(-1, library)),
                      const SizedBox(width: 6),
                      Material(
                        color: c.surface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: c.line)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openPicker(library),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_chapterRef,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                                const SizedBox(width: 6),
                                Icon(Icons.expand_more_rounded,
                                    size: 15, color: c.text),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _RoundIcon(
                          icon: Icons.chevron_right_rounded,
                          onTap: () => _shiftChapter(1, library)),
                    ],
                  ),
                  Row(
                    children: [
                      _RoundIcon(
                        icon: _speaking
                            ? Icons.stop_circle_rounded
                            : Icons.volume_up_rounded,
                        color: _speaking ? c.teal : null,
                        onTap: () => _toggleReadAloud(verses),
                      ),
                      const SizedBox(width: 6),
                      _RoundIcon(
                        icon: _searching ? Icons.close_rounded : Icons.search_rounded,
                        color: _searching ? c.teal : null,
                        onTap: _toggleSearch,
                      ),
                      const SizedBox(width: 6),
                      _RoundIcon(
                        icon: isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
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
            if (_searching)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _runSearch(library),
                      decoration: InputDecoration(
                        hintText: 'Search a verse, passage, or reference…',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                          onPressed: () => _runSearch(library),
                        ),
                        filled: true,
                        fillColor: c.surface,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: c.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: c.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: c.teal),
                        ),
                      ),
                    ),
                    if (_searchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          color: c.surface,
                          border: Border.all(color: c.line),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: c.line),
                          itemBuilder: (context, i) {
                            final hit = _searchResults[i];
                            return ListTile(
                              dense: true,
                              title: Text('${hit.book} ${hit.chapter}:${hit.verse}',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: c.teal)),
                              subtitle: Text(hit.text,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: c.dim)),
                              onTap: () =>
                                  _jumpTo(hit.book, hit.chapter, verse: hit.verse),
                            );
                          },
                        ),
                      )
                    else if (_searchedNoMatch)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text('No matches found.',
                            style: TextStyle(fontSize: 13, color: c.dim)),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_chapterRef,
                          style:
                              PgText.serif(size: 26, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('King James Version',
                          style: TextStyle(
                              fontSize: 13,
                              color: c.dim,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 22),
                      if (verses.isEmpty)
                        Text('This chapter is unavailable.',
                            style: TextStyle(fontSize: 14, color: c.dim))
                      else
                        for (var i = 0; i < verses.length; i++)
                          Padding(
                            key: _verseKeys.putIfAbsent(i + 1, () => GlobalKey()),
                            padding: const EdgeInsets.only(bottom: 14),
                            child: GestureDetector(
                              onTap: () =>
                                  _openVerseActions(ref, i + 1, verses[i]),
                              child: Container(
                                padding: highlightedVerses.contains(i + 1)
                                    ? const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2)
                                    : EdgeInsets.zero,
                                decoration: highlightedVerses.contains(i + 1)
                                    ? BoxDecoration(
                                        color: c.amberSoft,
                                        borderRadius: BorderRadius.circular(6))
                                    : null,
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${i + 1} ',
                                        style: TextStyle(
                                          color:
                                              highlightedVerses.contains(i + 1)
                                                  ? c.amber
                                                  : c.teal,
                                          fontFamily: 'Manrope',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      TextSpan(
                                        text: verses[i],
                                        style: PgText.serif(
                                            size: 18.5,
                                            height: 1.85,
                                            color: c.text),
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
              ),
            ),
            if (_planKey != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 10),
                child: PgButton(
                  label: _marking
                      ? 'Updating…'
                      : 'Mark Day ${_planDay ?? ''} Done'.replaceAll('  ', ' '),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  onPressed: _marking ? null : _markPlanDayDone,
                ),
              ),
          ],
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
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
          side: BorderSide(color: c.line)),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 18, color: color ?? c.dim)),
      ),
    );
  }
}
