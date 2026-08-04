import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/notification_scheduler.dart';
import '../data/models/notification_prefs.dart';
import '../data/repositories/notifications_repository.dart';
import 'profile_provider.dart';
import 'repo_providers.dart';

final notificationsRepositoryProvider =
    Provider((ref) => NotificationsRepository());

class NotificationsNotifier extends AsyncNotifier<NotificationPrefs> {
  @override
  Future<NotificationPrefs> build() async {
    ref.watch(currentUserIdProvider);
    final prefs = await ref.read(notificationsRepositoryProvider).fetch();
    unawaited(_applyToScheduler(prefs));
    return prefs;
  }

  Future<void> _applyToScheduler(NotificationPrefs prefs) async {
    final lastPrayedOn = ref.read(profileProvider).valueOrNull?.lastPrayedOn;
    await NotificationScheduler.instance
        .applyPrefs(prefs, lastPrayedOn: lastPrayedOn);
  }

  /// Re-applies the current prefs to the scheduler — e.g. after a prayer
  /// session completes, so today's streak-protection nudge is cancelled.
  Future<void> reapply() async {
    final prefs = state.value;
    if (prefs != null) await _applyToScheduler(prefs);
  }

  Future<void> _patch(Map<String, dynamic> patch,
      NotificationPrefs Function(NotificationPrefs) apply) async {
    final current = state.value;
    if (current == null) return;
    final next = apply(current);
    state = AsyncData(next);
    try {
      await ref.read(notificationsRepositoryProvider).update(patch);
      await _applyToScheduler(next);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> setMorningPrayer(bool v) =>
      _patch({'morning_prayer': v}, (p) => p.copyWith(morningPrayer: v));

  Future<void> setEveningPrayer(bool v) =>
      _patch({'evening_prayer': v}, (p) => p.copyWith(eveningPrayer: v));

  Future<void> setMorningTime(int weekday, String hhmm) => _patch(
        {NotificationPrefs.morningColumn(weekday): hhmm},
        (p) => p.copyWith(morningTimes: {...p.morningTimes, weekday: hhmm}),
      );

  Future<void> setEveningTime(int weekday, String hhmm) => _patch(
        {NotificationPrefs.eveningColumn(weekday): hhmm},
        (p) => p.copyWith(eveningTimes: {...p.eveningTimes, weekday: hhmm}),
      );

  Future<void> setScriptureOfDay(bool v) =>
      _patch({'scripture_of_day': v}, (p) => p.copyWith(scriptureOfDay: v));

  Future<void> setStreakProtection(bool v) =>
      _patch({'streak_protection': v}, (p) => p.copyWith(streakProtection: v));

  Future<void> setCompanionCheckins(bool v) => _patch(
      {'companion_checkins': v}, (p) => p.copyWith(companionCheckins: v));

  Future<void> setChallengeReminders(bool v) => _patch(
      {'challenge_reminders': v}, (p) => p.copyWith(challengeReminders: v));
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, NotificationPrefs>(
  NotificationsNotifier.new,
);
