import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../data/models/insights_summary.dart';
import '../../state/insights_provider.dart';
import '../../state/profile_provider.dart';
import '../../widgets/pg_header.dart';

const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final streak = ref.watch(profileProvider).valueOrNull?.streakCount ?? 0;
    final insightsAsync = ref.watch(insightsProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(title: 'Growth', onBack: () => context.pop()),
            insightsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text('Could not load your growth data.\n$e', style: TextStyle(color: c.danger)),
              ),
              data: (insights) => _Content(insights: insights, streak: streak),
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.insights, required this.streak});
  final InsightsSummary insights;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxMin = insights.dailyMinutes.fold(1, (m, v) => v > m ? v : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(value: insights.totalTimeLabel, label: 'Prayed this week')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(value: '$streak', label: 'Day streak')),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Daily prayer time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              SizedBox(
                height: 110,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < insights.dailyMinutes.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: (insights.dailyMinutes[i] / maxMin * 84).clamp(4, 84).toDouble(),
                                decoration: BoxDecoration(
                                  color: insights.dailyMinutes[i] > 0 ? c.teal : c.line2,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(_dayLabels[i], style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: c.faint)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: c.tealSoft, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(20)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_outlined, size: 22, color: c.teal),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('A gentle insight', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Text(insights.gentleInsight, style: TextStyle(fontSize: 13.5, height: 1.6, color: c.dim)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 11.5, color: c.dim)),
        ],
      ),
    );
  }
}
