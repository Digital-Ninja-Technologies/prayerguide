import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/favorite_video.dart';
import 'repo_providers.dart';

class FavoriteVideosNotifier extends AsyncNotifier<List<FavoriteVideo>> {
  @override
  Future<List<FavoriteVideo>> build() {
    ref.watch(currentUserIdProvider);
    return ref.read(favoriteVideosRepositoryProvider).fetchAll();
  }

  bool isFavorite(String url) => (state.value ?? []).any((f) => f.url == url);

  Future<void> toggle({required String title, required String url}) async {
    final repo = ref.read(favoriteVideosRepositoryProvider);
    final current = state.value ?? [];
    if (isFavorite(url)) {
      state = AsyncData([
        for (final f in current)
          if (f.url != url) f
      ]);
      await repo.remove(url);
    } else {
      state = AsyncData([FavoriteVideo(title: title, url: url), ...current]);
      await repo.add(title: title, url: url);
    }
  }
}

final favoriteVideosProvider =
    AsyncNotifierProvider<FavoriteVideosNotifier, List<FavoriteVideo>>(
  FavoriteVideosNotifier.new,
);
