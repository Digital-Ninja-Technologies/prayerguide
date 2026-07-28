import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../data/models/notification_prefs.dart';
import '../../state/notifications_provider.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_section_label.dart';
import '../../widgets/pg_toggle.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final prefsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(title: 'Notifications', onBack: () => context.pop()),
            prefsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text('Could not load notification settings.\n$e', style: TextStyle(color: c.danger)),
              ),
              data: (prefs) => _NotificationsContent(prefs: prefs),
            ),
          ],
        ),
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
          _Row('Morning prayer', prefs.formatted(prefs.morningPrayerTime), prefs.morningPrayer,
              notifier.setMorningPrayer),
          _Row('Evening prayer', prefs.formatted(prefs.eveningPrayerTime), prefs.eveningPrayer,
              notifier.setEveningPrayer, isLast: true),
        ]),
        const SizedBox(height: 20),
        const PgSectionLabel('Gentle nudges'),
        _Group([
          _Row('Scripture of the day', null, prefs.scriptureOfDay, notifier.setScriptureOfDay),
          _Row('Streak protection', "Only if you're about to miss a day", prefs.streakProtection,
              notifier.setStreakProtection),
          _Row('Companion check-ins', null, prefs.companionCheckins, notifier.setCompanionCheckins, isLast: true),
        ]),
        const SizedBox(height: 20),
        const PgSectionLabel('Quiet hours'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              Icon(Icons.dark_mode_outlined, size: 19, color: c.teal),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  '${prefs.formatted(prefs.quietHoursStart)} – ${prefs.formatted(prefs.quietHoursEnd)}',
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
              ),
              Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.teal)),
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
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(18)),
      child: Column(children: rows),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.sub, this.value, this.onChanged, {this.isLast = false});
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
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: c.line))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                if (sub != null) Text(sub!, style: TextStyle(fontSize: 11.5, color: c.faint)),
              ],
            ),
          ),
          PgToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
