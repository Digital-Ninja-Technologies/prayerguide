import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repo_providers.dart';

class HiddenChannelsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() {
    ref.watch(currentUserIdProvider);
    return ref.read(hiddenChannelsRepositoryProvider).fetchAll();
  }

  Future<void> hide(String url) async {
    final repo = ref.read(hiddenChannelsRepositoryProvider);
    state = AsyncData({...state.value ?? {}, url});
    await repo.hide(url);
  }
}

final hiddenChannelsProvider =
    AsyncNotifierProvider<HiddenChannelsNotifier, Set<String>>(
  HiddenChannelsNotifier.new,
);
