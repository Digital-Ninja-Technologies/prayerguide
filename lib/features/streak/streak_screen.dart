import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/static/pg_content.dart';
import '../../state/profile_provider.dart';
import '../../state/repo_providers.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_toggle.dart';

final _monthDaysProvider = FutureProvider<Set<int>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref
      .read(profileRepositoryProvider)
      .fetchQualifyingDaysInMonth(DateTime.now());
});

class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.valueOrNull;
    final streak = profile?.streakCount ?? 0;
    final appOpenStreak = profile?.appOpenStreakCount ?? 0;
    final daysAsync = ref.watch(_monthDaysProvider);
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday % 7; // 0=Sun

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(title: 'Your rhythm', onBack: () => context.pop()),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StreakHero(
                    icon: Icons.local_fire_department_rounded,
                    color: c.amber,
                    value: streak,
                    label: 'prayer streak',
                    message: streak > 0
                        ? "$streak day${streak == 1 ? '' : 's'} of prayer. A freeze keeps it safe if you need to rest."
                        : 'Every rhythm begins with one day.',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StreakHero(
                    icon: Icons.calendar_month_rounded,
                    color: c.teal,
                    value: appOpenStreak,
                    label: 'day streak',
                    message: appOpenStreak > 0
                        ? "$appOpenStreak day${appOpenStreak == 1 ? '' : 's'} showing up, whether or not you prayed."
                        : 'Opening the app today starts this one.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(22)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(monthName,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      Row(
                        children: [
                          _Legend(color: c.teal, label: 'Prayed', filled: true),
                          const SizedBox(width: 14),
                          _Legend(
                              color: c.amber, label: 'Frozen', filled: false),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                    children: [
                      for (final d in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                        Center(
                            child: Text(d,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: c.faint))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  daysAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, st) => const SizedBox.shrink(),
                    data: (qualifyingDays) => GridView.count(
                      crossAxisCount: 7,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: [
                        for (var i = 0; i < firstWeekday; i++) const SizedBox(),
                        for (var day = 1; day <= daysInMonth; day++)
                          _DayCell(
                            day: day,
                            active: qualifyingDays.contains(day),
                            future: day > now.day,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('MILESTONES',
                style: PgText.sans(
                    size: 12,
                    weight: FontWeight.w700,
                    color: c.dim,
                    letterSpacing: 1)),
            const SizedBox(height: 14),
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 128,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: milestoneDays.length,
              itemBuilder: (context, i) {
                final days = milestoneDays[i];
                return _MilestoneCard(days: days, achieved: streak >= days);
              },
            ),
            const SizedBox(height: 22),
            _HideStreakRow(hidden: profile?.hideStreakCount ?? false),
          ],
        ),
      ),
    );
  }
}

class _StreakHero extends StatelessWidget {
  const _StreakHero({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.message,
  });
  final IconData icon;
  final Color color;
  final int value;
  final String label;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.surface2, c.surface]),
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, size: 26, color: color),
          const SizedBox(height: 6),
          Text('$value',
              style: const TextStyle(
                  fontSize: 40, fontWeight: FontWeight.w800, height: 1)),
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: c.dim)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.5, color: c.dim),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(
      {required this.color, required this.label, required this.filled});
  final Color color;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : null,
            border: filled ? null : Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w600, color: c.dim)),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell(
      {required this.day, required this.active, required this.future});
  final int day;
  final bool active;
  final bool future;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Color bg = Colors.transparent;
    Color fg = c.faint;
    if (active) {
      bg = c.teal;
      fg = c.onTeal;
    } else if (future) {
      fg = c.line2;
    }
    return Container(
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
      alignment: Alignment.center,
      child: Text('$day',
          style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.days, required this.achieved});
  final int days;
  final bool achieved;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Opacity(
      opacity: achieved ? 1 : .5,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: achieved ? c.amber : c.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: achieved ? c.amberSoft : c.surface2,
              ),
              child: Icon(Icons.emoji_events_outlined,
                  size: 20, color: achieved ? c.amber : c.faint),
            ),
            const SizedBox(height: 8),
            Text('$days',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text('days',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: c.dim)),
          ],
        ),
      ),
    );
  }
}

class _HideStreakRow extends ConsumerWidget {
  const _HideStreakRow({required this.hidden});
  final bool hidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(Icons.visibility_off_outlined, size: 20, color: c.dim),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hide streak count',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text('If numbers ever add pressure, tuck them away.',
                    style: TextStyle(fontSize: 12, color: c.faint)),
              ],
            ),
          ),
          PgToggle(
              value: hidden,
              onChanged: (v) =>
                  ref.read(profileProvider.notifier).setHideStreak(v)),
        ],
      ),
    );
  }
}
