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
    required this.appOpenStreakCount,
    required this.appOpenLongestStreak,
    required this.lastOpenedOn,
    this.username,
  });

  final String id;
  final String name;
  final String? email;

  /// The public @handle other users find/share with — null until the user
  /// picks one, either at signup or via the forced one-time gate
  /// (ChooseUsernameScreen) for pre-existing accounts.
  final String? username;

  /// Consecutive days with a qualifying prayer session.
  final int streakCount;
  final int longestStreak;
  final DateTime? lastPrayedOn;
  final int streakFreezesAvailable;
  final bool hideStreakCount;
  final String themePreference;

  /// Consecutive days the app was opened, whether or not the user prayed —
  /// a separate, distinct streak from [streakCount].
  final int appOpenStreakCount;
  final int appOpenLongestStreak;
  final DateTime? lastOpenedOn;

  factory PgProfile.fromMap(Map<String, dynamic> m) => PgProfile(
        id: m['id'] as String,
        name: (m['name'] as String?) ?? '',
        email: m['email'] as String?,
        streakCount: (m['streak_count'] as num?)?.toInt() ?? 0,
        longestStreak: (m['longest_streak'] as num?)?.toInt() ?? 0,
        lastPrayedOn: m['last_prayed_on'] == null
            ? null
            : DateTime.tryParse(m['last_prayed_on'] as String),
        streakFreezesAvailable:
            (m['streak_freezes_available'] as num?)?.toInt() ?? 0,
        hideStreakCount: (m['hide_streak_count'] as bool?) ?? false,
        themePreference: (m['theme_preference'] as String?) ?? 'dark',
        appOpenStreakCount: (m['app_open_streak_count'] as num?)?.toInt() ?? 0,
        appOpenLongestStreak:
            (m['app_open_longest_streak'] as num?)?.toInt() ?? 0,
        lastOpenedOn: m['last_opened_on'] == null
            ? null
            : DateTime.tryParse(m['last_opened_on'] as String),
        username: m['username'] as String?,
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
        appOpenStreakCount: 0,
        appOpenLongestStreak: 0,
        lastOpenedOn: null,
        username: null,
      );
}
