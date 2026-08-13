import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/custom_channel.dart';
import 'repo_providers.dart';

class CustomChannelsNotifier extends AsyncNotifier<List<CustomChannel>> {
  @override
  Future<List<CustomChannel>> build() {
    ref.watch(currentUserIdProvider);
    return ref.read(customChannelsRepositoryProvider).fetchAll();
  }

  Future<void> add({required String name, required String url}) async {
    final repo = ref.read(customChannelsRepositoryProvider);
    final added = await repo.add(name: name, url: url);
    state = AsyncData([added, ...state.value ?? []]);
  }

  Future<void> remove(String id) async {
    final repo = ref.read(customChannelsRepositoryProvider);
    final current = state.value ?? [];
    state = AsyncData([
      for (final c in current)
        if (c.id != id) c
    ]);
    await repo.remove(id);
  }
}

final customChannelsProvider =
    AsyncNotifierProvider<CustomChannelsNotifier, List<CustomChannel>>(
  CustomChannelsNotifier.new,
);
