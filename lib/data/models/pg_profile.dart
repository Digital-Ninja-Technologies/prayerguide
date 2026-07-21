class PgProfile {
  PgProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.streakCount,
    required this.longestStreak,
    required this.lastPrayedOn,
    required this.streakFreezesAvailable,
    required this.hideStreakCount,
    required this.themePreference,
    required this.premium,
  });

  final String id;
  final String name;
  final String? email;
  final int streakCount;
  final int longestStreak;
  final DateTime? lastPrayedOn;
  final int streakFreezesAvailable;
  final bool hideStreakCount;
  final String themePreference;
  final bool premium;

  factory PgProfile.fromMap(Map<String, dynamic> m) => PgProfile(
        id: m['id'] as String,
        name: (m['name'] as String?) ?? '',
        email: m['email'] as String?,
        streakCount: (m['streak_count'] as num?)?.toInt() ?? 0,
        longestStreak: (m['longest_streak'] as num?)?.toInt() ?? 0,
        lastPrayedOn: m['last_prayed_on'] == null
            ? null
            : DateTime.tryParse(m['last_prayed_on'] as String),
        streakFreezesAvailable: (m['streak_freezes_available'] as num?)?.toInt() ?? 0,
        hideStreakCount: (m['hide_streak_count'] as bool?) ?? false,
        themePreference: (m['theme_preference'] as String?) ?? 'dark',
        premium: (m['premium'] as bool?) ?? false,
      );

  static PgProfile empty(String id, {String? email}) => PgProfile(
        id: id,
        name: '',
        email: email,
        streakCount: 0,
        longestStreak: 0,
        lastPrayedOn: null,
        streakFreezesAvailable: 1,
        hideStreakCount: false,
        themePreference: 'dark',
        premium: false,
      );
}
