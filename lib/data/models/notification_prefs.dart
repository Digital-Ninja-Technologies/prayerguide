class NotificationPrefs {
  const NotificationPrefs({
    this.morningPrayer = true,
    this.morningPrayerTime = '06:30',
    this.eveningPrayer = true,
    this.eveningPrayerTime = '20:00',
    this.scriptureOfDay = true,
    this.streakProtection = false,
    this.companionCheckins = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '06:00',
  });

  final bool morningPrayer;
  final String morningPrayerTime;
  final bool eveningPrayer;
  final String eveningPrayerTime;
  final bool scriptureOfDay;
  final bool streakProtection;
  final bool companionCheckins;
  final String quietHoursStart;
  final String quietHoursEnd;

  factory NotificationPrefs.fromMap(Map<String, dynamic> m) => NotificationPrefs(
        morningPrayer: m['morning_prayer'] as bool? ?? true,
        morningPrayerTime: _trimSeconds(m['morning_prayer_time'] as String?) ?? '06:30',
        eveningPrayer: m['evening_prayer'] as bool? ?? true,
        eveningPrayerTime: _trimSeconds(m['evening_prayer_time'] as String?) ?? '20:00',
        scriptureOfDay: m['scripture_of_day'] as bool? ?? true,
        streakProtection: m['streak_protection'] as bool? ?? false,
        companionCheckins: m['companion_checkins'] as bool? ?? true,
        quietHoursStart: _trimSeconds(m['quiet_hours_start'] as String?) ?? '22:00',
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

  NotificationPrefs copyWith({
    bool? morningPrayer,
    bool? eveningPrayer,
    bool? scriptureOfDay,
    bool? streakProtection,
    bool? companionCheckins,
  }) =>
      NotificationPrefs(
        morningPrayer: morningPrayer ?? this.morningPrayer,
        morningPrayerTime: morningPrayerTime,
        eveningPrayer: eveningPrayer ?? this.eveningPrayer,
        eveningPrayerTime: eveningPrayerTime,
        scriptureOfDay: scriptureOfDay ?? this.scriptureOfDay,
        streakProtection: streakProtection ?? this.streakProtection,
        companionCheckins: companionCheckins ?? this.companionCheckins,
        quietHoursStart: quietHoursStart,
        quietHoursEnd: quietHoursEnd,
      );
}
