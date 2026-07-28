import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_config.dart';
import '../data/models/companion.dart';
import '../data/repositories/companion_repository.dart';
import 'repo_providers.dart';

final companionRepositoryProvider = Provider((ref) => CompanionRepository());

class CompanionState {
  const CompanionState({this.companion, this.recentCheckins = const [], this.myTodayCheckin});

  final Companion? companion;
  final List<CompanionCheckinEntry> recentCheckins;
  final String? myTodayCheckin;
}

class CompanionNotifier extends AsyncNotifier<CompanionState> {
  @override
  Future<CompanionState> build() async {
    ref.watch(currentUserIdProvider);
    final repo = ref.read(companionRepositoryProvider);
    final companion = await repo.fetchCompanion();
    if (companion == null) return const CompanionState();

    final checkins = await repo.fetchRecentCheckins(companion.companionRowId);
    final uid = supa.auth.currentUser!.id;
    final now = DateTime.now();
    String? myToday;
    for (final entry in checkins) {
      if (entry.userId == uid && _isSameDay(entry.createdAt, now)) {
        myToday = entry.status;
        break;
      }
    }
    return CompanionState(companion: companion, recentCheckins: checkins, myTodayCheckin: myToday);
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> setCheckin(String status) async {
    final companion = state.value?.companion;
    if (companion == null) return;
    final repo = ref.read(companionRepositoryProvider);
    await repo.checkin(companionId: companion.companionRowId, status: status);
    ref.invalidateSelf();
    await future;
  }
}

final companionProvider = AsyncNotifierProvider<CompanionNotifier, CompanionState>(CompanionNotifier.new);
