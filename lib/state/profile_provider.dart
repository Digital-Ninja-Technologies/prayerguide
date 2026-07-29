import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/pg_profile.dart';
import 'notifications_provider.dart';
import 'repo_providers.dart';

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

  /// Logs a completed prayer session (feeds the streak via DB trigger), then
  /// refreshes the profile so `streak_count` reflects the new value.
  Future<void> completeSession({required int durationSeconds, String? category}) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.logSession(durationSeconds: durationSeconds, category: category);
    ref.invalidateSelf();
    await future;
    await ref.read(notificationsProvider.notifier).reapply();
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, PgProfile>(ProfileNotifier.new);
