import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../state/favorite_videos_provider.dart';
import '../../widgets/pg_card.dart';
import '../../widgets/pg_error_state.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_icon_badge.dart';

/// Full-page list of every video favorited from inside `ChannelWebviewScreen`
/// — reached via the icon in front of "Channel" on the directory screen,
/// rather than living inline there.
class FavoriteVideosScreen extends ConsumerWidget {
  const FavoriteVideosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final videosAsync = ref.watch(favoriteVideosProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
            child:
                PgHeader(title: 'Favorite videos', onBack: () => context.pop()),
          ),
          Expanded(
            child: videosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: PgErrorState(
                    error: e,
                    onRetry: () => ref.invalidate(favoriteVideosProvider)),
              ),
              data: (videos) {
                if (videos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                                color: c.tealSoft,
                                borderRadius: BorderRadius.circular(20)),
                            child: Icon(Icons.favorite_border_rounded,
                                size: 30, color: c.teal),
                          ),
                          const SizedBox(height: 16),
                          const Text('No favorite videos yet',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                            'While watching a video on a channel, tap the heart in the top corner to save it here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13.5, color: c.dim, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
                  children: [
                    for (final v in videos) ...[
                      PgCard(
                        radius: 16,
                        padding: const EdgeInsets.all(14),
                        onTap: () => context.push(
                            '/channel/view?name=${Uri.encodeComponent(v.title)}&url=${Uri.encodeComponent(v.url)}'),
                        child: Row(
                          children: [
                            PgIconBadge(
                                icon: Icons.play_circle_fill_rounded,
                                color: c.teal,
                                background: c.tealSoft),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(v.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700)),
                            ),
                            IconButton(
                              onPressed: () => ref
                                  .read(favoriteVideosProvider.notifier)
                                  .toggle(title: v.title, url: v.url),
                              icon: Icon(Icons.favorite_rounded,
                                  color: c.danger, size: 20),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
