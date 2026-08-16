import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/pg_profile.dart';
import 'notifications_provider.dart';
import 'repo_providers.dart';

const _kAppOpenLoggedDateKey = 'app_open_logged_date';

class ProfileNotifier extends AsyncNotifier<PgProfile> {
  @override
  Future<PgProfile> build() {
    ref.watch(currentUserIdProvider);
    return ref.read(profileRepositoryProvider).fetch();
  }

  Future<void> setHideStreak(bool hide) async {
    final repo = ref.read(profileRepositoryProvider);
    final p = state.value;
    if (p == null) return;
    await repo.update({'hide_streak_count': hide});
    ref.invalidateSelf();
  }

  Future<void> setThemePreference(String pref) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.update({'theme_preference': pref});
  }

  /// Throws on failure (e.g. a race where someone else just took the same
  /// username) — the calling screen's try/catch surfaces that.
  Future<void> setUsername(String username) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.update({'username': username});
    ref.invalidateSelf();
    await future;
  }

  /// Logs a completed prayer session (feeds the streak via DB trigger), then
  /// refreshes the profile so `streak_count` reflects the new value.
  Future<void> completeSession(
      {required int durationSeconds, String? category}) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.logSession(durationSeconds: durationSeconds, category: category);
    ref.invalidateSelf();
    await future;
    await ref.read(notificationsProvider.notifier).reapply();
  }

  /// Logs today's app open (feeds the separate app-open streak via DB
  /// trigger) at most once per calendar day — gated locally so repeated
  /// screen rebuilds within the same session/day don't insert repeatedly.
  Future<void> recordAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (prefs.getString(_kAppOpenLoggedDateKey) == todayKey) return;
    final repo = ref.read(profileRepositoryProvider);
    await repo.logAppOpen();
    // Only remember "already logged today" once the insert actually
    // succeeds — otherwise a transient failure (e.g. a network error) would
    // silently skip logging for the rest of the day.
    await prefs.setString(_kAppOpenLoggedDateKey, todayKey);
    ref.invalidateSelf();
    await future;
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, PgProfile>(ProfileNotifier.new);
