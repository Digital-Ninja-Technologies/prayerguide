import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/scripture/scripture_of_day_library.dart';
import '../../state/bible_library_provider.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_header.dart';

class ScriptureScreen extends ConsumerWidget {
  const ScriptureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final today = DateTime.now();
    final entry = scriptureOfDayForDate(today);
    final libraryAsync = ref.watch(bibleLibraryProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 6, 26, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(eyebrow: DateFormat('MMMM d').format(today).toUpperCase(), onBack: () => context.pop()),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Text('SCRIPTURE OF THE DAY',
                      textAlign: TextAlign.center,
                      style: PgText.serif(size: 11, letterSpacing: 3, color: c.teal)),
                  const SizedBox(height: 20),
                  libraryAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (e, st) => Text('Could not load scripture text.', style: TextStyle(color: c.danger)),
                    data: (library) {
                      final verses = library.versesFor(entry.book, entry.chapter);
                      final text = verses.isEmpty ? '' : verses.sublist(entry.verseStart - 1, entry.verseEnd).join(' ');
                      return Text(
                        '"$text"',
                        textAlign: TextAlign.center,
                        style: PgText.serif(size: 27, weight: FontWeight.w500, height: 1.5),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Text('${entry.reference} · KJV', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.amber)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Block(label: 'EXPLANATION', labelColor: c.teal, body: entry.explanation),
            const SizedBox(height: 14),
            _Block(label: 'PRAYER FOCUS', labelColor: c.amber, body: entry.prayerFocus),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.surface2,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REFLECTION QUESTION',
                      style: PgText.sans(size: 12, weight: FontWeight.w700, color: c.dim, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Text(entry.question, style: PgText.serif(size: 18, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            PgButton(label: 'Pray on this', onPressed: () => context.push('/timer?category=Scripture')),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.label, required this.labelColor, required this.body});

  final String label;
  final Color labelColor;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: PgText.sans(size: 12, weight: FontWeight.w700, color: labelColor, letterSpacing: 1)),
          const SizedBox(height: 10),
          Text(body, style: TextStyle(fontSize: 15, height: 1.65, color: c.text)),
        ],
      ),
    );
  }
}
