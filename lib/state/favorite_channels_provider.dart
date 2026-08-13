import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/favorite_channel.dart';
import 'repo_providers.dart';

class FavoriteChannelsNotifier extends AsyncNotifier<List<FavoriteChannel>> {
  @override
  Future<List<FavoriteChannel>> build() {
    ref.watch(currentUserIdProvider);
    return ref.read(favoriteChannelsRepositoryProvider).fetchAll();
  }

  bool isFavorite(String url) =>
      (state.value ?? []).any((f) => f.url == url);

  Future<void> toggle({required String name, required String url}) async {
    final repo = ref.read(favoriteChannelsRepositoryProvider);
    final current = state.value ?? [];
    if (isFavorite(url)) {
      state = AsyncData([
        for (final f in current)
          if (f.url != url) f
      ]);
      await repo.remove(url);
    } else {
      state = AsyncData([FavoriteChannel(name: name, url: url), ...current]);
      await repo.add(name: name, url: url);
    }
  }
}

final favoriteChannelsProvider =
    AsyncNotifierProvider<FavoriteChannelsNotifier, List<FavoriteChannel>>(
  FavoriteChannelsNotifier.new,
);
