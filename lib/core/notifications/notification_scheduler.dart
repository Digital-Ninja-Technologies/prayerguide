import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/challenge_progress.dart';
import '../../data/models/notification_prefs.dart';

/// Schedules the real local (on-device) notifications backing the toggles on
/// the Notifications screen. Each notification kind gets a fixed id so
/// re-scheduling (a toggle flip, a time change, a completed prayer session)
/// just cancels and re-creates it — never accumulates duplicates.
class NotificationScheduler {
  NotificationScheduler._();
  static final instance = NotificationScheduler._();

  static const _morningIdBase = 1100; // + weekday (1..7) => 1101..1107
  static const _eveningIdBase = 1200; // + weekday (1..7) => 1201..1207
  static const _scriptureId = 1003;
  static const _streakId = 1004;

  /// No time field exists for this one in notification_prefs — a single
  /// fixed daily time is a reasonable default for a "scripture of the day"
  /// nudge.
  static const _scriptureTime = '09:00';

  /// How late in the evening we're still willing to warn about today's
  /// streak before giving up and waiting for tomorrow's reschedule.
  static const _streakCutoff = '20:30';

  /// When the "haven't done today's challenge session yet" nudge fires,
  /// same reasoning as [_streakCutoff] — evening, but with time left in
  /// the day to still act on it.
  static const _challengeCutoff = '19:30';

  /// Notification ids for challenge reminders are derived per challenge
  /// row (there's no fixed count of them), offset well clear of every
  /// other fixed id range above so they can never collide.
  static const _challengeIdBase = 2000000;
  static int _challengeNotificationId(String challengeProgressId) =>
      _challengeIdBase + (challengeProgressId.hashCode.abs() % 1000000);

  final _plugin = FlutterLocalNotificationsPlugin();

  /// The in-flight initialization, if any — [NotificationsNotifier] and
  /// [ChallengeNotifier] (among others) each call [init] independently
  /// around login time, and without this, two concurrent callers could
  /// both see initialization as not-yet-started and race to request the
  /// Android notification permission at the same time, which Android
  /// rejects with `PlatformException(permissionRequestInProgress, ...)`.
  /// Every caller now awaits the same underlying Future instead. Cleared on
  /// failure so a transient error doesn't permanently wedge this for the
  /// rest of the session.
  Future<void>? _initFuture;

  Future<void> init() {
    return _initFuture ??=
        _doInit().catchError((Object error, StackTrace stack) {
      _initFuture = null;
      Error.throwWithStackTrace(error, stack);
    });
  }

  Future<void> _doInit() async {
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Falls back to UTC if the platform can't report a timezone (e.g. web
      // in some browsers) — reminders will fire, just not necessarily at the
      // intended local wall-clock time until this resolves.
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
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
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

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

  /// Like [_scheduleDaily], but repeats weekly on [weekday] ([DateTime.weekday]
  /// — 1=Monday..7=Sunday) instead of every day, since morning/evening
  /// reminders now have an independent time per day of the week.
  Future<void> _scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required String hhmm,
  }) async {
    await init();
    final parts = hhmm.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

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
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }

  /// Applies [prefs] to real scheduled notifications. [lastPrayedOn], when
  /// today's date, cancels the streak-protection nudge for today (the user
  /// already prayed, so there's nothing to protect).
  Future<void> applyPrefs(NotificationPrefs prefs,
      {DateTime? lastPrayedOn}) async {
    if (kIsWeb) {
      return; // local_notifications' web target can't background-schedule reliably; skip rather than pretend.
    }
    await init();

    for (final weekday in weekdayLabels.keys) {
      if (prefs.morningPrayer) {
        await _scheduleWeekly(
          id: _morningIdBase + weekday,
          title: 'Morning prayer',
          body: 'Take a few quiet minutes with God before the day gets loud.',
          weekday: weekday,
          hhmm: prefs.morningTimes[weekday] ?? '06:30',
        );
      } else {
        await cancel(_morningIdBase + weekday);
      }

      if (prefs.eveningPrayer) {
        await _scheduleWeekly(
          id: _eveningIdBase + weekday,
          title: 'Evening prayer',
          body: 'Close the day the way you started it — in prayer.',
          weekday: weekday,
          hhmm: prefs.eveningTimes[weekday] ?? '20:00',
        );
      } else {
        await cancel(_eveningIdBase + weekday);
      }
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

  Future<void> _applyStreakProtection(NotificationPrefs prefs,
      {DateTime? lastPrayedOn}) async {
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

  /// One reminder per active, not-yet-finished challenge that hasn't been
  /// engaged with today — cancelled the moment [ChallengeProgress.engagedToday]
  /// is true, so it stops nagging for that challenge until tomorrow. Call
  /// this again after any challenge is started/advanced, and whenever the
  /// challenge list is refetched, so it stays in sync with real progress.
  Future<void> applyChallengeReminders(
    List<ChallengeProgress> challenges, {
    required bool enabled,
  }) async {
    if (kIsWeb) return;
    await init();
    for (final challenge in challenges) {
      final id = _challengeNotificationId(challenge.id);
      final finished = challenge.currentDay >= challenge.totalDays;
      if (!enabled || !challenge.active || finished || challenge.engagedToday) {
        await cancel(id);
        continue;
      }
      await _scheduleDaily(
        id: id,
        title: challenge.name,
        body:
            "You haven't done today's session yet — a few minutes keeps it going.",
        hhmm: _challengeCutoff,
      );
    }
  }
}
