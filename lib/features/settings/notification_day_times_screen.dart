import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../data/models/notification_prefs.dart';
import '../../state/notifications_provider.dart';
import '../../widgets/pg_header.dart';

/// Lets a user set a different morning or evening prayer reminder time for
/// each day of the week, instead of one time that applies every day.
class NotificationDayTimesScreen extends ConsumerWidget {
  const NotificationDayTimesScreen({super.key, required this.kind});

  /// 'morning' or 'evening' — which set of per-day times this edits.
  final String kind;

  bool get _isMorning => kind == 'morning';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final prefsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
            child: PgHeader(
              title:
                  _isMorning ? 'Morning prayer times' : 'Evening prayer times',
              onBack: () => context.pop(),
            ),
          ),
          Expanded(
            child: prefsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load your settings.\n$e',
                      style: TextStyle(color: c.danger)),
                ),
              ),
              data: (prefs) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Set a separate reminder time for each day — e.g. later on weekends.',
                        style: TextStyle(
                            fontSize: 13.5, height: 1.5, color: c.dim),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                          color: c.surface,
                          border: Border.all(color: c.line),
                          borderRadius: BorderRadius.circular(18)),
                      child: Column(
                        children: [
                          for (final weekday in weekdayLabels.keys)
                            _DayRow(
                              label: weekdayLabels[weekday]!,
                              hhmm: (_isMorning
                                  ? prefs.morningTimes
                                  : prefs.eveningTimes)[weekday]!,
                              formatted: prefs.formatted((_isMorning
                                  ? prefs.morningTimes
                                  : prefs.eveningTimes)[weekday]!),
                              showBorder: weekday != 7,
                              onTap: () async {
                                final current = (_isMorning
                                    ? prefs.morningTimes
                                    : prefs.eveningTimes)[weekday]!;
                                final parts = current.split(':');
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(
                                      hour: int.parse(parts[0]),
                                      minute: int.parse(parts[1])),
                                );
                                if (picked == null) return;
                                final hhmm =
                                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                final notifier =
                                    ref.read(notificationsProvider.notifier);
                                if (_isMorning) {
                                  await notifier.setMorningTime(weekday, hhmm);
                                } else {
                                  await notifier.setEveningTime(weekday, hhmm);
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.label,
    required this.hhmm,
    required this.formatted,
    required this.showBorder,
    required this.onTap,
  });
  final String label;
  final String hhmm;
  final String formatted;
  final bool showBorder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            border:
                showBorder ? Border(bottom: BorderSide(color: c.line)) : null),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w600)),
            ),
            Text(formatted,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: c.teal)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 17, color: c.faint),
          ],
        ),
      ),
    );
  }
}
