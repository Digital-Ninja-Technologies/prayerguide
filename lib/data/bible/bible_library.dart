import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class BibleBookInfo {
  const BibleBookInfo({required this.name, required this.testament, required this.chapterCount});

  final String name;
  final String testament; // OT | NT
  final int chapterCount;
}

/// The full KJV text (public domain), bundled as a local asset
/// (assets/bible/kjv.json) so reading Scripture never depends on a network
/// call. Loaded once and cached in memory.
class BibleLibrary {
  BibleLibrary._(this._chaptersByBook, this.books);

  final Map<String, List<List<String>>> _chaptersByBook;
  final List<BibleBookInfo> books;

  static Future<BibleLibrary> load() async {
    final raw = await rootBundle.loadString('assets/bible/kjv.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final booksJson = json['books'] as List;

    final chaptersByBook = <String, List<List<String>>>{};
    final books = <BibleBookInfo>[];
    for (final entry in booksJson) {
      final map = entry as Map<String, dynamic>;
      final name = map['name'] as String;
      final testament = map['testament'] as String;
      final chapters = (map['chapters'] as List)
          .map((chapter) => (chapter as List).cast<String>())
          .toList();
      chaptersByBook[name] = chapters;
      books.add(BibleBookInfo(name: name, testament: testament, chapterCount: chapters.length));
    }
    return BibleLibrary._(chaptersByBook, books);
  }

  /// Verse text for [book]/[chapter] (1-indexed), or an empty list if either
  /// doesn't exist.
  List<String> versesFor(String book, int chapter) {
    final chapters = _chaptersByBook[book];
    if (chapters == null || chapter < 1 || chapter > chapters.length) return const [];
    return chapters[chapter - 1];
  }

  int chapterCountFor(String book) => _chaptersByBook[book]?.length ?? 0;

  bool hasBook(String book) => _chaptersByBook.containsKey(book);
}
