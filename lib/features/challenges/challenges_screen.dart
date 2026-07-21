import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/static/pg_content.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_card.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_icon_badge.dart';
import '../../widgets/pg_section_label.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final inProgress = challengeCatalog['growth40']!;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(
              title: 'Challenges',
              onBack: () => context.pop(),
              trailing: TextButton.icon(
                onPressed: () => context.push('/challenges/new'),
                style: TextButton.styleFrom(
                  backgroundColor: c.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                ),
                icon: Icon(Icons.add_rounded, size: 16, color: c.onTeal),
                label: Text('Create', style: TextStyle(color: c.onTeal, fontSize: 13.5, fontWeight: FontWeight.w800)),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [c.tealSoft, c.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
                border: Border.all(color: c.teal),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('IN PROGRESS', style: PgText.sans(size: 11, weight: FontWeight.w800, color: c.teal, letterSpacing: 1)),
                      Text('Day 12 / 40', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.teal)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(inProgress.name, style: PgText.serif(size: 20, weight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: 0.3,
                      minHeight: 8,
                      backgroundColor: c.surface2,
                      valueColor: AlwaysStoppedAnimation(c.teal),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PgButton(label: 'Continue — Day 13', onPressed: () => context.push('/challenges/growth40')),
                ],
              ),
            ),
            const PgSectionLabel('Start a new challenge'),
            for (final ch in challengeCatalog.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: PgCard(
                  radius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  onTap: () => context.push('/challenges/${ch.key}'),
                  child: Row(
                    children: [
                      PgIconBadge(icon: Icons.emoji_events_outlined, color: c.teal, background: c.tealSoft, size: 44, radius: 13),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ch.name, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                            Text('${ch.lengthDays} days', style: TextStyle(fontSize: 12.5, color: c.dim)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: c.faint),
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
