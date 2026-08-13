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

  /// Parses [query] as a book/chapter[:verse] reference (e.g. "John 3:16",
  /// "Genesis 1", "1 John 2") — matched against the longest book name that
  /// prefixes the query, so multi-word/numbered books ("Song of Solomon",
  /// "1 Corinthians") work too. Returns null if it doesn't look like a
  /// reference, so the caller can fall back to a keyword search instead.
  BibleReference? parseReference(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();

    BibleBookInfo? matched;
    for (final book in books) {
      final name = book.name.toLowerCase();
      if (lower == name || lower.startsWith('$name ') || lower.startsWith('$name:')) {
        if (matched == null || book.name.length > matched.name.length) {
          matched = book;
        }
      }
    }
    if (matched == null) return null;

    final rest = trimmed.substring(matched.name.length).trim();
    if (rest.isEmpty) return BibleReference(book: matched.name, chapter: 1);

    final parts = rest.split(':');
    final chapter = int.tryParse(parts[0].trim());
    if (chapter == null || chapter < 1 || chapter > matched.chapterCount) return null;
    int? verse;
    if (parts.length > 1) verse = int.tryParse(parts[1].trim());
    return BibleReference(book: matched.name, chapter: chapter, verse: verse);
  }

  /// A simple offline full-text search across all 66 books — case-insensitive
  /// substring match against verse text, capped at [limit] hits.
  List<BibleSearchHit> searchText(String query, {int limit = 40}) {
    final q = query.trim().toLowerCase();
    if (q.length < 3) return const [];
    final results = <BibleSearchHit>[];
    for (final book in books) {
      final chapters = _chaptersByBook[book.name]!;
      for (var c = 0; c < chapters.length; c++) {
        final verses = chapters[c];
        for (var v = 0; v < verses.length; v++) {
          if (verses[v].toLowerCase().contains(q)) {
            results.add(BibleSearchHit(
                book: book.name, chapter: c + 1, verse: v + 1, text: verses[v]));
            if (results.length >= limit) return results;
          }
        }
      }
    }
    return results;
  }
}

class BibleReference {
  const BibleReference({required this.book, required this.chapter, this.verse});
  final String book;
  final int chapter;
  final int? verse;
}

class BibleSearchHit {
  const BibleSearchHit(
      {required this.book, required this.chapter, required this.verse, required this.text});
  final String book;
  final int chapter;
  final int verse;
  final String text;
}
