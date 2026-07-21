import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/static/pg_content.dart';
import '../../widgets/pg_button.dart';

class ChallengeDetailScreen extends StatelessWidget {
  const ChallengeDetailScreen({super.key, required this.challengeKey});
  final String challengeKey;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ch = challengeCatalog[challengeKey] ?? challengeCatalog['growth40']!;
    final day = ch.key == 'growth40' ? 12 : 0;
    final pct = ch.lengthDays == 0 ? 0.0 : day / ch.lengthDays;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Back(onTap: () => context.pop()),
                const SizedBox(width: 12),
                Text('${ch.lengthDays} days', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.dim)),
              ],
            ),
            const SizedBox(height: 14),
            Text(ch.name, style: PgText.serif(size: 29, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Text(ch.description, style: TextStyle(fontSize: 14.5, height: 1.6, color: c.dim)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PROGRESS', style: PgText.sans(size: 12, weight: FontWeight.w700, color: c.teal, letterSpacing: 1)),
                Text('${(pct * 100).round()}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.dim)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(18)),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ch.lengthDays,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10, mainAxisSpacing: 6, crossAxisSpacing: 6),
                itemBuilder: (context, i) => Container(
                  decoration: BoxDecoration(
                    color: i < day ? c.teal : c.surface2,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: c.tealSoft, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TODAY'S FOCUS", style: PgText.sans(size: 11, weight: FontWeight.w800, color: c.teal, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(ch.focusToday, style: PgText.serif(size: 17)),
                ],
              ),
            ),
            PgButton(
              label: day > 0 ? 'Continue — Day ${day + 1}' : 'Start challenge',
              onPressed: () => context.push('/guide'),
            ),
            const SizedBox(height: 11),
            PgButton(
              label: 'Invite a companion',
              variant: PgButtonVariant.outline,
              icon: Icon(Icons.person_add_alt_1_outlined, size: 18, color: c.teal),
              onPressed: () => context.push('/companion/invite'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: c.line)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(width: 38, height: 38, child: Icon(Icons.arrow_back_ios_new_rounded, size: 17, color: c.text)),
      ),
    );
  }
}
