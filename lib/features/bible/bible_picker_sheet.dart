import 'package:flutter/material.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/bible/bible_library.dart';

/// Two-step book → chapter picker. Returns the chosen (book, chapter), or
/// null if dismissed without a selection.
Future<(String, int)?> showBiblePickerSheet(
  BuildContext context, {
  required BibleLibrary library,
  required String initialBook,
}) {
  return showModalBottomSheet<(String, int)>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => _PickerSheet(library: library, initialBook: initialBook),
  );
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({required this.library, required this.initialBook});

  final BibleLibrary library;
  final String initialBook;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String? _selectedBook;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: c.line2, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  if (_selectedBook != null)
                    IconButton(
                      onPressed: () => setState(() => _selectedBook = null),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
                    ),
                  Expanded(
                    child: Text(
                      _selectedBook ?? 'Choose a book',
                      style: PgText.serif(size: 19, weight: FontWeight.w600),
                      textAlign: _selectedBook != null ? TextAlign.center : TextAlign.left,
                    ),
                  ),
                  if (_selectedBook != null) const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(child: _selectedBook == null ? _buildBookList(c) : _buildChapterGrid(c)),
          ],
        ),
      ),
    );
  }

  Widget _buildBookList(PgColors c) {
    final ot = widget.library.books.where((b) => b.testament == 'OT').toList();
    final nt = widget.library.books.where((b) => b.testament == 'NT').toList();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      children: [
        _sectionLabel('Old Testament', c),
        for (final b in ot) _bookRow(b, c),
        const SizedBox(height: 10),
        _sectionLabel('New Testament', c),
        for (final b in nt) _bookRow(b, c),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _sectionLabel(String label, PgColors c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(label.toUpperCase(),
            style: PgText.sans(size: 11.5, weight: FontWeight.w700, color: c.dim, letterSpacing: 1)),
      );

  Widget _bookRow(BibleBookInfo b, PgColors c) {
    return InkWell(
      onTap: () => setState(() => _selectedBook = b.name),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Expanded(child: Text(b.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
            Text('${b.chapterCount}', style: TextStyle(fontSize: 13, color: c.faint)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 17, color: c.faint),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterGrid(PgColors c) {
    final count = widget.library.chapterCountFor(_selectedBook!);
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: count,
      itemBuilder: (context, i) {
        final chapter = i + 1;
        return Material(
          color: c.surface2,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).pop((_selectedBook!, chapter)),
            child: Center(child: Text('$chapter', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700))),
          ),
        );
      },
    );
  }
}
