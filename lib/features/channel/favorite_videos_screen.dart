import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../state/favorite_videos_provider.dart';
import '../../widgets/pg_error_state.dart';
import '../../widgets/pg_header.dart';

/// Full-page list of every video favorited from inside `ChannelWebviewScreen`
/// — reached via the heart icon on the Channel tab, rather than living
/// inline there.
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
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 2),
            child:
                PgHeader(title: 'Favorite videos', onBack: () => context.pop()),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
            child: videosAsync.maybeWhen(
              data: (videos) => Text(
                videos.isEmpty
                    ? 'Videos you save while watching show up here'
                    : '${videos.length} saved ${videos.length == 1 ? 'video' : 'videos'}',
                style: TextStyle(fontSize: 13.5, color: c.dim),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 34),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [c.tealSoft, c.amberSoft],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.favorite_rounded,
                                size: 36, color: c.teal),
                          ),
                          const SizedBox(height: 20),
                          Text('No favorite videos yet',
                              textAlign: TextAlign.center,
                              style: PgText.serif(
                                  size: 19, weight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(
                            'While watching a video on a channel, tap the heart in the top corner to save it here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13.5, color: c.dim, height: 1.55),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
                  itemCount: videos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final v = videos[i];
                    return _VideoCard(
                      title: v.title,
                      onTap: () => context.push(
                          '/channel/view?name=${Uri.encodeComponent(v.title)}&url=${Uri.encodeComponent(v.url)}'),
                      onUnfavorite: () => ref
                          .read(favoriteVideosProvider.notifier)
                          .toggle(title: v.title, url: v.url),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({
    required this.title,
    required this.onTap,
    required this.onUnfavorite,
  });

  final String title;
  final VoidCallback onTap;
  final VoidCallback onUnfavorite;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.line),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: c.tealSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.play_arrow_rounded, size: 32, color: c.teal),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.35),
                  ),
                ),
              ),
              IconButton(
                onPressed: onUnfavorite,
                tooltip: 'Remove from favorites',
                icon: Icon(Icons.favorite_rounded, color: c.danger, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
