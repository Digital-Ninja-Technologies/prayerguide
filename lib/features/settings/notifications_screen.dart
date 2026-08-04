import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../data/models/notification_prefs.dart';
import '../../state/notifications_provider.dart';
import '../../widgets/pg_error_state.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_section_label.dart';
import '../../widgets/pg_toggle.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
            child:
                PgHeader(title: 'Notifications', onBack: () => context.pop()),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  prefsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, st) => PgErrorState(
                        error: e,
                        onRetry: () => ref.invalidate(notificationsProvider)),
                    data: (prefs) => _NotificationsContent(prefs: prefs),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsContent extends ConsumerWidget {
  const _NotificationsContent({required this.prefs});
  final NotificationPrefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final notifier = ref.read(notificationsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PgSectionLabel('Prayer reminders'),
        _Group([
          _PrayerTimeRow(
            label: 'Morning prayer',
            times: prefs.morningTimes,
            uniform: prefs.morningTimesUniform,
            formatted: prefs.formatted,
            value: prefs.morningPrayer,
            onChanged: notifier.setMorningPrayer,
            onEditTimes: () => context.push('/notifications/times/morning'),
          ),
          _PrayerTimeRow(
            label: 'Evening prayer',
            times: prefs.eveningTimes,
            uniform: prefs.eveningTimesUniform,
            formatted: prefs.formatted,
            value: prefs.eveningPrayer,
            onChanged: notifier.setEveningPrayer,
            onEditTimes: () => context.push('/notifications/times/evening'),
            isLast: true,
          ),
        ]),
        const SizedBox(height: 20),
        const PgSectionLabel('Gentle nudges'),
        _Group([
          _Row('Scripture of the day', null, prefs.scriptureOfDay,
              notifier.setScriptureOfDay),
          _Row('Streak protection', "Only if you're about to miss a day",
              prefs.streakProtection, notifier.setStreakProtection),
          _Row('Companion check-ins', null, prefs.companionCheckins,
              notifier.setCompanionCheckins),
          _Row(
              'Challenge reminders',
              "If you're taking on a challenge and haven't done today's session",
              prefs.challengeReminders,
              notifier.setChallengeReminders,
              isLast: true),
        ]),
        const SizedBox(height: 20),
        const PgSectionLabel('Quiet hours'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              Icon(Icons.dark_mode_outlined, size: 19, color: c.teal),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  '${prefs.formatted(prefs.quietHoursStart)} – ${prefs.formatted(prefs.quietHoursEnd)}',
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
              ),
              Text('Edit',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.teal)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.rows);
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(18)),
      child: Column(children: rows),
    );
  }
}

class _PrayerTimeRow extends StatelessWidget {
  const _PrayerTimeRow({
    required this.label,
    required this.times,
    required this.uniform,
    required this.formatted,
    required this.value,
    required this.onChanged,
    required this.onEditTimes,
    this.isLast = false,
  });
  final String label;
  final Map<int, String> times;
  final bool uniform;
  final String Function(String) formatted;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEditTimes;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sub = uniform ? formatted(times[1]!) : 'Varies by day';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: c.line))),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: value ? onEditTimes : null,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontSize: 14.5, fontWeight: FontWeight.w600)),
                        Text(sub,
                            style: TextStyle(fontSize: 11.5, color: c.faint)),
                      ],
                    ),
                  ),
                  if (value) ...[
                    Text('Edit',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: c.teal)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 16, color: c.teal),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          PgToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.sub, this.value, this.onChanged,
      {this.isLast = false});
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: c.line))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600)),
                if (sub != null)
                  Text(sub!, style: TextStyle(fontSize: 11.5, color: c.faint)),
              ],
            ),
          ),
          PgToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
