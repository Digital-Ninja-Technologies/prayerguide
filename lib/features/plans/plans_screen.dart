import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../data/bible/reading_plan_schedule.dart';
import '../../data/models/reading_plan_progress.dart';
import '../../state/reading_plan_provider.dart';
import '../../widgets/pg_card.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_icon_badge.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final progressAsync = ref.watch(readingPlanProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
            child:
                PgHeader(title: 'Reading Plans', onBack: () => context.pop()),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                        'Read through Scripture at a pace that fits your life.',
                        style: TextStyle(fontSize: 14.5, color: c.dim)),
                  ),
                  for (final def in readingPlanDefs.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: PgCard(
                        radius: 16,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                        onTap: () => context.push('/plans/${def.key}'),
                        child: Row(
                          children: [
                            PgIconBadge(
                                icon: Icons.menu_book_outlined,
                                color: c.teal,
                                background: c.tealSoft,
                                size: 44,
                                radius: 13),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(def.name,
                                      style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700)),
                                  Text(def.sub,
                                      style: TextStyle(
                                          fontSize: 12.5, color: c.dim)),
                                ],
                              ),
                            ),
                            Text(
                              _label(progressAsync, def),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: c.teal),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _label(
      AsyncValue<List<ReadingPlanProgress>> progressAsync, ReadingPlanDef def) {
    final entries = progressAsync.valueOrNull;
    if (entries == null) return '';
    for (final p in entries) {
      if (p.planKey == def.key) {
        if (p.daysCompleted <= 0) return 'Start';
        if (p.daysCompleted >= def.totalDays) return 'Done';
        return '${((p.daysCompleted / def.totalDays) * 100).round()}%';
      }
    }
    return 'Start';
  }
}
