import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/supabase/supabase_config.dart';
import '../data/models/companion.dart';
import '../data/repositories/companion_repository.dart';
import 'repo_providers.dart';

final companionRepositoryProvider = Provider((ref) => CompanionRepository());

/// All of the current user's companion pairs.
final companionsProvider = FutureProvider<List<Companion>>((ref) async {
  ref.watch(currentUserIdProvider);
  return ref.read(companionRepositoryProvider).fetchCompanions();
});

class CompanionDetailState {
  const CompanionDetailState({
    required this.companion,
    this.monthCheckins = const [],
    this.myTodayCheckin,
    this.sharedRequests = const [],
  });

  final Companion companion;
  final List<CompanionCheckinEntry> monthCheckins;
  final String? myTodayCheckin;
  final List<SharedRequest> sharedRequests;
}

/// Check-ins and shared requests for one specific companion pair, keyed by
/// its `companions` row id — lets two people looking at the same pair see
/// the same detail page regardless of which of them opened it.
class CompanionDetailNotifier
    extends FamilyAsyncNotifier<CompanionDetailState, String> {
  @override
  Future<CompanionDetailState> build(String companionRowId) async {
    final repo = ref.read(companionRepositoryProvider);
    final companion = await repo.fetchCompanionByRowId(companionRowId);
    if (companion == null) {
      throw StateError('That companion could not be found.');
    }

    final uid = supa.auth.currentUser!.id;
    final now = DateTime.now();
    final checkins = await repo.fetchCheckinsForMonth(companionRowId, now);
    final sharedRequests = await repo.fetchSharedRequests(
        myUserId: uid, otherUserId: companion.otherUserId);

    String? myToday;
    for (final entry in checkins) {
      if (entry.userId == uid && _isSameDay(entry.createdAt, now)) {
        myToday = entry.status;
        break;
      }
    }
    return CompanionDetailState(
      companion: companion,
      monthCheckins: checkins,
      myTodayCheckin: myToday,
      sharedRequests: sharedRequests,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> setCheckin(String status) async {
    final repo = ref.read(companionRepositoryProvider);
    await repo.checkin(companionId: arg, status: status);
    ref.invalidateSelf();
    await future;
  }

  Future<void> unshareRequest(String requestId) async {
    final repo = ref.read(companionRepositoryProvider);
    await repo.unshareRequest(requestId);
    ref.invalidateSelf();
    await future;
  }

  /// Ends this pairing. The companion list refreshes too, since it no
  /// longer includes this pair either.
  Future<void> removeCompanion() async {
    final repo = ref.read(companionRepositoryProvider);
    await repo.removeCompanion(arg);
    ref.invalidate(companionsProvider);
  }
}

final companionDetailProvider = AsyncNotifierProvider.family<
    CompanionDetailNotifier, CompanionDetailState, String>(
  CompanionDetailNotifier.new,
);

/// Navigates to the invite screen.
void pushInviteCompanion(BuildContext context) {
  context.push('/companion/invite');
}
