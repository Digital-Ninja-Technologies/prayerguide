import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/notification_prefs.dart';

/// Schedules the real local (on-device) notifications backing the toggles on
/// the Notifications screen. Each notification kind gets a fixed id so
/// re-scheduling (a toggle flip, a time change, a completed prayer session)
/// just cancels and re-creates it — never accumulates duplicates.
class NotificationScheduler {
  NotificationScheduler._();
  static final instance = NotificationScheduler._();

  static const _morningId = 1001;
  static const _eveningId = 1002;
  static const _scriptureId = 1003;
  static const _streakId = 1004;

  /// No time field exists for this one in notification_prefs — a single
  /// fixed daily time is a reasonable default for a "scripture of the day"
  /// nudge.
  static const _scriptureTime = '09:00';

  /// How late in the evening we're still willing to warn about today's
  /// streak before giving up and waiting for tomorrow's reschedule.
  static const _streakCutoff = '20:30';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Falls back to UTC if the platform can't report a timezone (e.g. web
      // in some browsers) — reminders will fire, just not necessarily at the
      // intended local wall-clock time until this resolves.
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    _ready = true;
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required String hhmm,
  }) async {
    await init();
    final parts = hhmm.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: scheduled,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_reminders',
          'Prayer reminders',
          channelDescription: 'Daily prayer and scripture reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }

  /// Applies [prefs] to real scheduled notifications. [lastPrayedOn], when
  /// today's date, cancels the streak-protection nudge for today (the user
  /// already prayed, so there's nothing to protect).
  Future<void> applyPrefs(NotificationPrefs prefs, {DateTime? lastPrayedOn}) async {
    if (kIsWeb) return; // local_notifications' web target can't background-schedule reliably; skip rather than pretend.
    await init();

    if (prefs.morningPrayer) {
      await _scheduleDaily(
        id: _morningId,
        title: 'Morning prayer',
        body: 'Take a few quiet minutes with God before the day gets loud.',
        hhmm: prefs.morningPrayerTime,
      );
    } else {
      await cancel(_morningId);
    }

    if (prefs.eveningPrayer) {
      await _scheduleDaily(
        id: _eveningId,
        title: 'Evening prayer',
        body: 'Close the day the way you started it — in prayer.',
        hhmm: prefs.eveningPrayerTime,
      );
    } else {
      await cancel(_eveningId);
    }

    if (prefs.scriptureOfDay) {
      await _scheduleDaily(
        id: _scriptureId,
        title: "Today's scripture",
        body: 'A new verse is ready for you in Prayer Guide.',
        hhmm: _scriptureTime,
      );
    } else {
      await cancel(_scriptureId);
    }

    await _applyStreakProtection(prefs, lastPrayedOn: lastPrayedOn);
  }

  Future<void> _applyStreakProtection(NotificationPrefs prefs, {DateTime? lastPrayedOn}) async {
    if (!prefs.streakProtection) {
      await cancel(_streakId);
      return;
    }
    final now = DateTime.now();
    final prayedToday = lastPrayedOn != null &&
        lastPrayedOn.year == now.year &&
        lastPrayedOn.month == now.month &&
        lastPrayedOn.day == now.day;
    if (prayedToday) {
      await cancel(_streakId);
      return;
    }
    await _scheduleDaily(
      id: _streakId,
      title: "Don't lose your streak",
      body: "You haven't prayed yet today — a few minutes keeps it going.",
      hhmm: _streakCutoff,
    );
  }
}
