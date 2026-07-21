import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/static/pg_content.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_header.dart';

class PlanDetailScreen extends StatelessWidget {
  const PlanDetailScreen({super.key, required this.planKey});
  final String planKey;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final plan = readingPlanCatalog[planKey] ?? readingPlanCatalog['oneYear']!;
    final pct = planKey == 'oneYear' ? 0.18 : 0.0;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(eyebrow: plan.sub, onBack: () => context.pop()),
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Text(plan.name, style: PgText.serif(size: 27, weight: FontWeight.w600)),
            ),
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(18)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progress', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.dim)),
                      Text('${(pct * 100).round()}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.teal)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: c.surface2,
                      valueColor: AlwaysStoppedAnimation(c.teal),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: c.tealSoft, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TODAY'S READING", style: PgText.sans(size: 11, weight: FontWeight.w800, color: c.teal, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(plan.today, style: PgText.serif(size: 18)),
                ],
              ),
            ),
            PgButton(label: 'Read now', onPressed: () => context.push('/bible')),
          ],
        ),
      ),
    );
  }
}
