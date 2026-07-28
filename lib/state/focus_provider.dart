import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/focus_session.dart';
import '../data/repositories/focus_repository.dart';
import 'repo_providers.dart';

final focusRepositoryProvider = Provider((ref) => FocusRepository());

class FocusNotifier extends AsyncNotifier<FocusSession?> {
  @override
  Future<FocusSession?> build() {
    ref.watch(currentUserIdProvider);
    return ref.read(focusRepositoryProvider).fetchActive();
  }

  Future<void> start(String mode) async {
    final repo = ref.read(focusRepositoryProvider);
    final session = await repo.start(mode);
    state = AsyncData(session);
  }

  Future<void> end() async {
    final repo = ref.read(focusRepositoryProvider);
    final session = state.value;
    if (session == null) return;
    await repo.end(session.id);
    state = const AsyncData(null);
  }
}

final focusProvider = AsyncNotifierProvider<FocusNotifier, FocusSession?>(FocusNotifier.new);
