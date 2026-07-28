import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/bible/reading_plan_schedule.dart';
import '../../state/bible_library_provider.dart';
import '../../state/reading_plan_provider.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_header.dart';

class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({super.key, required this.planKey});
  final String planKey;

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  bool _marking = false;

  Future<void> _markDayComplete(int totalDays) async {
    setState(() => _marking = true);
    try {
      await ref.read(readingPlanProvider.notifier).markDayComplete(
            planKey: widget.planKey,
            totalDays: totalDays,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update your progress: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planKey = widget.planKey;
    final c = context.colors;
    final def = readingPlanDefs[planKey] ?? readingPlanDefs['oneYear']!;
    final libraryAsync = ref.watch(bibleLibraryProvider);
    final progressAsync = ref.watch(readingPlanProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(eyebrow: def.sub, onBack: () => context.pop()),
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Text(def.name,
                  style: PgText.serif(size: 27, weight: FontWeight.w600)),
            ),
            libraryAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => Text('Could not load the Bible text.\n$e',
                  style: TextStyle(color: c.danger)),
              data: (library) {
                final schedule = ReadingPlanSchedule.build(def, library);
                var daysCompleted = 0;
                for (final p in progressAsync.valueOrNull ?? const []) {
                  if (p.planKey == planKey) daysCompleted = p.daysCompleted;
                }
                final finished = daysCompleted >= def.totalDays;
                final nextDay = finished ? def.totalDays : daysCompleted + 1;
                final readingLabel = schedule.label(nextDay);
                final firstReading = schedule.firstOf(nextDay);
                final pct =
                    def.totalDays == 0 ? 0.0 : daysCompleted / def.totalDays;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                          color: c.surface,
                          border: Border.all(color: c.line),
                          borderRadius: BorderRadius.circular(18)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Progress',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: c.dim)),
                              Text('Day $daysCompleted of ${def.totalDays}',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: c.teal)),
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
                      decoration: BoxDecoration(
                          color: c.tealSoft,
                          border: Border.all(color: c.line),
                          borderRadius: BorderRadius.circular(18)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            finished
                                ? "YOU'VE FINISHED THIS PLAN"
                                : "DAY $nextDay'S READING",
                            style: PgText.sans(
                                size: 11,
                                weight: FontWeight.w800,
                                color: c.teal,
                                letterSpacing: 1),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            finished
                                ? 'Every chapter, read. Consider starting again, or pick a new plan.'
                                : readingLabel,
                            style: PgText.serif(size: 18),
                          ),
                        ],
                      ),
                    ),
                    if (!finished) ...[
                      PgButton(
                        label: daysCompleted == 0
                            ? 'Read Day 1'
                            : 'Read Day $nextDay',
                        icon: const Icon(Icons.menu_book_outlined, size: 18),
                        onPressed: firstReading == null
                            ? null
                            : () => context.go(
                                '/bible?book=${Uri.encodeComponent(firstReading.$1)}&chapter=${firstReading.$2}'),
                      ),
                      const SizedBox(height: 11),
                      PgButton(
                        label: _marking
                            ? 'Updating…'
                            : 'Mark Day $nextDay as read',
                        variant: PgButtonVariant.outline,
                        onPressed: _marking
                            ? null
                            : () => _markDayComplete(def.totalDays),
                      ),
                    ] else
                      PgButton(
                        label: 'Read again from Day 1',
                        onPressed: firstReading == null
                            ? null
                            : () {
                                final first = schedule.firstOf(1)!;
                                context.go(
                                    '/bible?book=${Uri.encodeComponent(first.$1)}&chapter=${first.$2}');
                              },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
