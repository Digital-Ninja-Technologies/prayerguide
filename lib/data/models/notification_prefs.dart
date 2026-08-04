/// Column suffix for each weekday, keyed by [DateTime.weekday] (1=Monday .. 7=Sunday).
const Map<int, String> _daySuffix = {
  1: 'mon',
  2: 'tue',
  3: 'wed',
  4: 'thu',
  5: 'fri',
  6: 'sat',
  7: 'sun',
};

/// Full weekday name, keyed by [DateTime.weekday] (1=Monday .. 7=Sunday) —
/// used to label each day's time picker.
const Map<int, String> weekdayLabels = {
  1: 'Monday',
  2: 'Tuesday',
  3: 'Wednesday',
  4: 'Thursday',
  5: 'Friday',
  6: 'Saturday',
  7: 'Sunday',
};

class NotificationPrefs {
  const NotificationPrefs({
    this.morningPrayer = true,
    this.morningTimes = _defaultMorningTimes,
    this.eveningPrayer = true,
    this.eveningTimes = _defaultEveningTimes,
    this.scriptureOfDay = true,
    this.streakProtection = false,
    this.companionCheckins = true,
    this.challengeReminders = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '06:00',
  });

  static const _defaultMorningTimes = <int, String>{
    1: '06:30',
    2: '06:30',
    3: '06:30',
    4: '06:30',
    5: '06:30',
    6: '06:30',
    7: '06:30',
  };
  static const _defaultEveningTimes = <int, String>{
    1: '20:00',
    2: '20:00',
    3: '20:00',
    4: '20:00',
    5: '20:00',
    6: '20:00',
    7: '20:00',
  };

  final bool morningPrayer;

  /// This weekday's morning reminder time, keyed by [DateTime.weekday].
  final Map<int, String> morningTimes;
  final bool eveningPrayer;

  /// This weekday's evening reminder time, keyed by [DateTime.weekday].
  final Map<int, String> eveningTimes;
  final bool scriptureOfDay;
  final bool streakProtection;
  final bool companionCheckins;
  final bool challengeReminders;
  final String quietHoursStart;
  final String quietHoursEnd;

  factory NotificationPrefs.fromMap(Map<String, dynamic> m) =>
      NotificationPrefs(
        morningPrayer: m['morning_prayer'] as bool? ?? true,
        morningTimes: {
          for (final e in _daySuffix.entries)
            e.key: _trimSeconds(m['morning_time_${e.value}'] as String?) ??
                '06:30',
        },
        eveningPrayer: m['evening_prayer'] as bool? ?? true,
        eveningTimes: {
          for (final e in _daySuffix.entries)
            e.key: _trimSeconds(m['evening_time_${e.value}'] as String?) ??
                '20:00',
        },
        scriptureOfDay: m['scripture_of_day'] as bool? ?? true,
        streakProtection: m['streak_protection'] as bool? ?? false,
        companionCheckins: m['companion_checkins'] as bool? ?? true,
        challengeReminders: m['challenge_reminders'] as bool? ?? true,
        quietHoursStart:
            _trimSeconds(m['quiet_hours_start'] as String?) ?? '22:00',
        quietHoursEnd: _trimSeconds(m['quiet_hours_end'] as String?) ?? '06:00',
      );

  static String? _trimSeconds(String? t) => t?.substring(0, 5);

  /// Formats a "HH:mm" 24h string as "6:30 AM" for display.
  String formatted(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = parts[1];
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $period';
  }

  /// The Supabase column name for [weekday]'s morning/evening time — used
  /// when building a patch to send to [NotificationsRepository.update].
  static String morningColumn(int weekday) =>
      'morning_time_${_daySuffix[weekday]}';
  static String eveningColumn(int weekday) =>
      'evening_time_${_daySuffix[weekday]}';

  /// True when every day shares the same time — lets the summary row show
  /// a single time instead of "Varies by day".
  bool get morningTimesUniform => morningTimes.values.toSet().length <= 1;
  bool get eveningTimesUniform => eveningTimes.values.toSet().length <= 1;

  NotificationPrefs copyWith({
    bool? morningPrayer,
    Map<int, String>? morningTimes,
    bool? eveningPrayer,
    Map<int, String>? eveningTimes,
    bool? scriptureOfDay,
    bool? streakProtection,
    bool? companionCheckins,
    bool? challengeReminders,
  }) =>
      NotificationPrefs(
        morningPrayer: morningPrayer ?? this.morningPrayer,
        morningTimes: morningTimes ?? this.morningTimes,
        eveningPrayer: eveningPrayer ?? this.eveningPrayer,
        eveningTimes: eveningTimes ?? this.eveningTimes,
        scriptureOfDay: scriptureOfDay ?? this.scriptureOfDay,
        streakProtection: streakProtection ?? this.streakProtection,
        companionCheckins: companionCheckins ?? this.companionCheckins,
        challengeReminders: challengeReminders ?? this.challengeReminders,
        quietHoursStart: quietHoursStart,
        quietHoursEnd: quietHoursEnd,
      );
}
