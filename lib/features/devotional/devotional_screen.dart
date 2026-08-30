import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/devotional/devotional_library.dart';
import '../../state/bible_library_provider.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_header.dart';
import 'devotional_share.dart';

class DevotionalScreen extends ConsumerWidget {
  const DevotionalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final today = DateTime.now();
    final entry = devotionalForDate(today);
    final libraryAsync = ref.watch(bibleLibraryProvider);
    final reflectionParagraphs = entry.reflection.split('\n\n');

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
            child: PgHeader(
              eyebrow:
                  'DEVOTIONAL · ${DateFormat('MMMM d').format(today).toUpperCase()}',
              onBack: () => context.pop(),
              trailing: IconButton(
                onPressed: () => shareDevotionalCard(
                  context: context,
                  title: entry.title,
                  question: entry.question,
                  reference: entry.reference,
                  dateLabel: DateFormat('MMMM d').format(today),
                ),
                icon: Icon(Icons.ios_share_rounded, color: c.dim),
                tooltip: 'Share',
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title,
                      style: PgText.serif(size: 30, weight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(entry.reference,
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: c.amber)),
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 16),
                    margin: const EdgeInsets.only(bottom: 22),
                    decoration: BoxDecoration(
                        border:
                            Border(left: BorderSide(color: c.amber, width: 2))),
                    child: libraryAsync.when(
                      loading: () => const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (e, st) => Text('Could not load scripture text.',
                          style: TextStyle(color: c.danger)),
                      data: (library) {
                        final verses =
                            library.versesFor(entry.book, entry.chapter);
                        final text = verses.isEmpty
                            ? ''
                            : verses
                                .sublist(entry.verseStart - 1, entry.verseEnd)
                                .join(' ');
                        return Text(
                          '"$text"',
                          style: PgText.serif(
                              size: 17, style: FontStyle.italic, height: 1.55),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final p in reflectionParagraphs)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Text(p,
                                style: TextStyle(
                                    fontSize: 15.5,
                                    height: 1.75,
                                    color: c.text)),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: c.surface2,
                        border: Border.all(color: c.line),
                        borderRadius: BorderRadius.circular(18)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('REFLECT',
                            style: PgText.sans(
                                size: 11,
                                weight: FontWeight.w800,
                                color: c.dim,
                                letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Text(entry.question,
                            style: PgText.serif(size: 17, height: 1.5)),
                      ],
                    ),
                  ),
                  PgButton(
                      label: 'Pray & mark complete',
                      onPressed: () =>
                          context.push('/timer?category=Devotional')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
