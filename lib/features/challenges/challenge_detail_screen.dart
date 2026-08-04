import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/static/pg_content.dart';
import '../../state/challenge_provider.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_header.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  const ChallengeDetailScreen({super.key, required this.challengeKey});
  final String challengeKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final catalogEntry = challengeCatalog[challengeKey];
    final challengesAsync = ref.watch(challengeProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
            child: PgHeader(
                title: catalogEntry?.name, onBack: () => context.pop()),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
              child: challengesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, st) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text('Could not load this challenge.\n$e',
                      style: TextStyle(color: c.danger)),
                ),
                data: (_) {
                  final progress =
                      ref.read(challengeProvider.notifier).forKey(challengeKey);

                  if (progress == null && catalogEntry == null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          Text("Challenge not found",
                              style: PgText.serif(
                                  size: 20, weight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          PgButton(
                              label: 'Back to Challenges',
                              expand: false,
                              onPressed: () => context.pop()),
                        ],
                      ),
                    );
                  }

                  final name = progress?.name ?? catalogEntry!.name;
                  final totalDays =
                      progress?.totalDays ?? catalogEntry!.lengthDays;
                  final currentDay = progress?.currentDay ?? 0;
                  final description = catalogEntry?.description ??
                      'A personal challenge — stay consistent and keep showing up.';
                  final focusToday = catalogEntry?.focusToday;
                  final pct = totalDays == 0 ? 0.0 : currentDay / totalDays;
                  final finished = currentDay >= totalDays;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('$totalDays days',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: c.dim)),
                      ),
                      const SizedBox(height: 10),
                      Text(name,
                          style:
                              PgText.serif(size: 29, weight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: Text(description,
                            style: TextStyle(
                                fontSize: 14.5, height: 1.6, color: c.dim)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('PROGRESS',
                              style: PgText.sans(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: c.teal,
                                  letterSpacing: 1)),
                          Text('${(pct * 100).round()}%',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: c.dim)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(18),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                            color: c.surface,
                            border: Border.all(color: c.line),
                            borderRadius: BorderRadius.circular(18)),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: totalDays,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 10,
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6),
                          itemBuilder: (context, i) => Container(
                            decoration: BoxDecoration(
                              color: i < currentDay ? c.teal : c.surface2,
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ),
                      ),
                      if (focusToday != null || !finished)
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
                              Text("TODAY'S FOCUS",
                                  style: PgText.sans(
                                      size: 11,
                                      weight: FontWeight.w800,
                                      color: c.teal,
                                      letterSpacing: 1)),
                              const SizedBox(height: 8),
                              Text(
                                finished
                                    ? 'Every day, complete.'
                                    : (focusToday ??
                                        'Day ${currentDay + 1} of $totalDays'),
                                style: PgText.serif(size: 17),
                              ),
                            ],
                          ),
                        ),
                      if (!finished)
                        PgButton(
                          label: currentDay > 0
                              ? 'Continue — Day ${currentDay + 1}'
                              : 'Start challenge',
                          onPressed: () async {
                            await ref
                                .read(challengeProvider.notifier)
                                .startOrAdvance(
                                  challengeKey: challengeKey,
                                  name: name,
                                  totalDays: totalDays,
                                );
                            if (context.mounted) context.push('/guide');
                          },
                        )
                      else
                        PgButton(
                            label: 'Challenge complete',
                            onPressed: () => context.pop()),
                      const SizedBox(height: 11),
                      PgButton(
                        label: 'Invite a companion',
                        variant: PgButtonVariant.outline,
                        icon: Icon(Icons.person_add_alt_1_outlined,
                            size: 18, color: c.teal),
                        onPressed: () => context.push('/companion/invite'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
