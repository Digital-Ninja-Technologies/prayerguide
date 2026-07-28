import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_pill.dart';

const _notes = [
  (
    'Psalm 23:3',
    'He restoreth my soul: he leadeth me in the paths of righteousness.',
    null,
    true
  ),
  (
    'Philippians 4:6',
    'Be careful for nothing; but in every thing by prayer…',
    'Note: memorize this week.',
    false
  ),
  (
    'Isaiah 40:31',
    'They that wait upon the LORD shall renew their strength.',
    null,
    true
  ),
];

class BibleNotesScreen extends StatelessWidget {
  const BibleNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(title: 'Bookmarks & Notes', onBack: () => context.pop()),
            const Padding(
              padding: EdgeInsets.only(bottom: 18),
              child: Row(
                children: [
                  PgPill(label: 'Highlights', active: true),
                  SizedBox(width: 8),
                  PgPill(label: 'Bookmarks'),
                  SizedBox(width: 8),
                  PgPill(label: 'Notes'),
                ],
              ),
            ),
            for (final n in _notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: 3, height: 40, color: n.$4 ? c.amber : c.teal),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.$1,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: n.$4 ? c.amber : c.teal)),
                            const SizedBox(height: 6),
                            Text(n.$2,
                                style: PgText.serif(size: 15.5, height: 1.5)),
                            if (n.$3 != null) ...[
                              const SizedBox(height: 8),
                              Text(n.$3!,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: c.dim,
                                      fontStyle: FontStyle.italic)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
