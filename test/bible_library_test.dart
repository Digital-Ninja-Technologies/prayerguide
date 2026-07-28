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
}
