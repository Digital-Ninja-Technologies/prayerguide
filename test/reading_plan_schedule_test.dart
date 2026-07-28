import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_guide/data/bible/bible_library.dart';
import 'package:prayer_guide/data/bible/reading_plan_schedule.dart';
import 'package:prayer_guide/data/devotional/devotional_library.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BibleLibrary library;

  setUpAll(() async {
    library = await BibleLibrary.load();
  });

  for (final def in readingPlanDefs.values) {
    test('${def.key} schedule covers every chapter exactly once, no empty days', () {
      final schedule = ReadingPlanSchedule.build(def, library);
      final seen = <String>{};
      var totalReadings = 0;

      for (var day = 1; day <= def.totalDays; day++) {
        final readings = schedule.readingsForDay(day);
        expect(readings, isNotEmpty, reason: 'Day $day of ${def.key} has no reading');
        for (final r in readings) {
          final key = '${r.$1} ${r.$2}';
          expect(seen.add(key), isTrue, reason: '$key scheduled more than once in ${def.key}');
        }
        totalReadings += readings.length;

        // label() should always produce a non-empty, well-formed string.
        expect(schedule.label(day), isNotEmpty);
      }

      final expectedTotal = def
          .bookSelector(library)
          .fold<int>(0, (sum, book) => sum + library.chapterCountFor(book));
      expect(totalReadings, expectedTotal);
    });
  }

  test('devotionalForDate returns a valid entry with real scripture text for every day of a leap year', () {
    for (var day = 1; day <= 366; day++) {
      final date = DateTime(2028, 1, 1).add(Duration(days: day - 1)); // 2028 is a leap year
      final entry = devotionalForDate(date);
      final verses = library.versesFor(entry.book, entry.chapter);
      expect(verses, isNotEmpty, reason: '${entry.book} ${entry.chapter} not found for "${entry.title}"');
      expect(entry.verseEnd, lessThanOrEqualTo(verses.length));
      expect(entry.verseStart, greaterThanOrEqualTo(1));
    }
  });
}
