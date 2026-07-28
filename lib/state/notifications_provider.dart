import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/notification_prefs.dart';
import '../data/repositories/notifications_repository.dart';
import 'repo_providers.dart';

final notificationsRepositoryProvider = Provider((ref) => NotificationsRepository());

class NotificationsNotifier extends AsyncNotifier<NotificationPrefs> {
  @override
  Future<NotificationPrefs> build() async {
    ref.watch(currentUserIdProvider);
    return ref.read(notificationsRepositoryProvider).fetch();
  }

  Future<void> _patch(Map<String, dynamic> patch, NotificationPrefs Function(NotificationPrefs) apply) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(apply(current));
    try {
      await ref.read(notificationsRepositoryProvider).update(patch);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> setMorningPrayer(bool v) =>
      _patch({'morning_prayer': v}, (p) => p.copyWith(morningPrayer: v));

  Future<void> setEveningPrayer(bool v) =>
      _patch({'evening_prayer': v}, (p) => p.copyWith(eveningPrayer: v));

  Future<void> setScriptureOfDay(bool v) =>
      _patch({'scripture_of_day': v}, (p) => p.copyWith(scriptureOfDay: v));

  Future<void> setStreakProtection(bool v) =>
      _patch({'streak_protection': v}, (p) => p.copyWith(streakProtection: v));

  Future<void> setCompanionCheckins(bool v) =>
      _patch({'companion_checkins': v}, (p) => p.copyWith(companionCheckins: v));
}

final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier, NotificationPrefs>(
  NotificationsNotifier.new,
);
