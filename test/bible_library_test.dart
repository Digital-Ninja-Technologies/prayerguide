import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_guide/data/bible/bible_library.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the bundled KJV and parses all 66 books', () async {
    final library = await BibleLibrary.load();
    expect(library.books.length, 66);

    final genesis = library.books.firstWhere((b) => b.name == 'Genesis');
    expect(genesis.testament, 'OT');
    expect(genesis.chapterCount, 50);

    final revelation = library.books.firstWhere((b) => b.name == 'Revelation');
    expect(revelation.testament, 'NT');
    expect(revelation.chapterCount, 22);

    final gen1 = library.versesFor('Genesis', 1);
    expect(gen1.length, 31);
    expect(gen1.first, 'In the beginning God created the heaven and the earth.');

    final psalm23 = library.versesFor('Psalms', 23);
    expect(psalm23.length, 6);
    expect(psalm23.first, contains('The LORD is my shepherd'));

    // Out-of-range chapter / unknown book should return empty, not throw.
    expect(library.versesFor('Genesis', 999), isEmpty);
    expect(library.versesFor('Nope', 1), isEmpty);

    final totalVerses = library.books.fold<int>(
      0,
      (sum, b) => sum + List.generate(b.chapterCount, (i) => library.versesFor(b.name, i + 1).length).reduce((a, b) => a + b),
    );
    expect(totalVerses, 31102);
  });

  test('parseReference handles plain, multi-word, and numbered books', () async {
    final library = await BibleLibrary.load();

    final john316 = library.parseReference('John 3:16');
    expect(john316?.book, 'John');
    expect(john316?.chapter, 3);
    expect(john316?.verse, 16);

    final genesis1 = library.parseReference('Genesis 1');
    expect(genesis1?.book, 'Genesis');
    expect(genesis1?.chapter, 1);
    expect(genesis1?.verse, isNull);

    final firstCorinthians = library.parseReference('1 Corinthians 13');
    expect(firstCorinthians?.book, '1 Corinthians');
    expect(firstCorinthians?.chapter, 13);

    final songOfSolomon = library.parseReference('Song of Solomon 2:3');
    expect(songOfSolomon?.book, 'Song of Solomon');
    expect(songOfSolomon?.chapter, 2);
    expect(songOfSolomon?.verse, 3);

    expect(library.parseReference('Not a real book 1'), isNull);
    expect(library.parseReference('John 999'), isNull);
    expect(library.parseReference(''), isNull);
  });

  test('searchText finds verses containing the query, case-insensitively', () async {
    final library = await BibleLibrary.load();

    final hits = library.searchText('for God so loved the world');
    expect(hits, isNotEmpty);
    expect(hits.first.book, 'John');
    expect(hits.first.chapter, 3);
    expect(hits.first.verse, 16);

    expect(library.searchText('ab'), isEmpty); // below the 3-char minimum
    expect(library.searchText('zzzznotarealwordzzzz'), isEmpty);
  });
}
