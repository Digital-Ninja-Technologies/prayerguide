import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../widgets/pg_pill.dart';

const _verses = [
  (1, 'The LORD is my shepherd; I shall not want.', false),
  (2, 'He maketh me to lie down in green pastures: he leadeth me beside the still waters.', false),
  (3, "He restoreth my soul: he leadeth me in the paths of righteousness for his name's sake.", true),
  (4, 'Yea, though I walk through the valley of the shadow of death, I will fear no evil: for thou art with me; thy rod and thy staff they comfort me.', false),
  (5, 'Thou preparest a table before me in the presence of mine enemies: thou anointest my head with oil; my cup runneth over.', false),
  (6, 'Surely goodness and mercy shall follow me all the days of my life: and I will dwell in the house of the LORD for ever.', false),
];

class BibleScreen extends StatelessWidget {
  const BibleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 6, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              children: [
                PgPill(label: 'Read', active: true),
                const SizedBox(width: 8),
                PgPill(label: 'Reading plans', onTap: () => context.push('/plans')),
                const SizedBox(width: 8),
                PgPill(label: 'Devotional', onTap: () => context.push('/devotional')),
                const SizedBox(width: 8),
                PgPill(label: 'Notes', onTap: () => context.push('/bible-notes')),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Psalm 23', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(width: 6),
                      Icon(Icons.expand_more_rounded, size: 15, color: c.text),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _RoundIcon(icon: Icons.bookmark_border_rounded, onTap: () => context.push('/bible-notes')),
                    const SizedBox(width: 6),
                    _RoundIcon(icon: Icons.format_list_bulleted_rounded),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Psalm 23', style: PgText.serif(size: 26, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('A Psalm of David · KJV', style: TextStyle(fontSize: 13, color: c.dim, fontWeight: FontWeight.w600)),
                const SizedBox(height: 22),
                for (final v in _verses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${v.$1} ',
                            style: TextStyle(
                              color: v.$3 ? c.amber : c.teal,
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: v.$2,
                            style: PgText.serif(size: 18.5, height: 1.85, color: c.text),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11), side: BorderSide(color: c.line)),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: SizedBox(width: 38, height: 38, child: Icon(icon, size: 18, color: c.dim)),
      ),
    );
  }
}
