import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/sermon_share.dart';
import '../data/repositories/sermon_shares_repository.dart';
import 'repo_providers.dart';
import 'sermon_notes_provider.dart';

final sermonSharesRepositoryProvider = Provider((ref) => SermonSharesRepository());

class SermonSharesNotifier extends AsyncNotifier<List<SermonShare>> {
  @override
  Future<List<SermonShare>> build() {
    ref.watch(currentUserIdProvider);
    return ref.read(sermonSharesRepositoryProvider).fetchPendingForMe();
  }

  Future<void> accept(String shareId) async {
    final repo = ref.read(sermonSharesRepositoryProvider);
    await repo.accept(shareId);
    state = AsyncData((state.value ?? []).where((s) => s.id != shareId).toList());
    ref.invalidate(sermonNotesProvider);
  }

  Future<void> decline(String shareId) async {
    final repo = ref.read(sermonSharesRepositoryProvider);
    await repo.decline(shareId);
    state = AsyncData((state.value ?? []).where((s) => s.id != shareId).toList());
  }
}

final sermonSharesProvider =
    AsyncNotifierProvider<SermonSharesNotifier, List<SermonShare>>(SermonSharesNotifier.new);

/// Drives the pending-shares badge on the Sermon Notes list — a live count
/// via Realtime rather than depending on [sermonSharesProvider] having been
/// fetched/refreshed already.
final pendingSermonSharesCountProvider = StreamProvider<int>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.read(sermonSharesRepositoryProvider).watchPendingCount();
});
