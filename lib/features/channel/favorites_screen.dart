import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../state/favorite_channels_provider.dart';
import '../../state/favorite_videos_provider.dart';
import '../../widgets/pg_card.dart';
import '../../widgets/pg_error_state.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_icon_badge.dart';

/// Everything a user has favorited, reached via the heart icon on the
/// Channel tab's header — favorite channels first (the primary content),
/// favorite videos below. Replaces the old channels-only ("FAVORITE
/// CHANNELS") inline section on the directory screen and the earlier
/// videos-only FavoriteVideosScreen with one combined page.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  void _open(BuildContext context,
      {required String name, required String url}) {
    context.push(
        '/channel/view?name=${Uri.encodeComponent(name)}&url=${Uri.encodeComponent(url)}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(favoriteChannelsProvider);
    final videosAsync = ref.watch(favoriteVideosProvider);
    final channels = channelsAsync.valueOrNull ?? [];
    final videos = videosAsync.valueOrNull ?? [];
    final loading = channelsAsync.isLoading || videosAsync.isLoading;
    final error = channelsAsync.error ?? videosAsync.error;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 16),
              child: PgHeader(title: 'Favorites', onBack: () => context.pop()),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(
                          child: PgErrorState(
                            error: error,
                            onRetry: () {
                              ref.invalidate(favoriteChannelsProvider);
                              ref.invalidate(favoriteVideosProvider);
                            },
                          ),
                        )
                      : (channels.isEmpty && videos.isEmpty)
                          ? const _EmptyState()
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
                              children: [
                                if (channels.isNotEmpty) ...[
                                  const _SectionLabel('CHANNELS'),
                                  const SizedBox(height: 10),
                                  for (final ch in channels) ...[
                                    _FavoriteTile(
                                      icon: Icons.smart_display_rounded,
                                      title: ch.name,
                                      subtitle: 'Favorited channel',
                                      onTap: () => _open(context,
                                          name: ch.name, url: ch.url),
                                      onUnfavorite: () => ref
                                          .read(
                                              favoriteChannelsProvider.notifier)
                                          .toggle(name: ch.name, url: ch.url),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  const SizedBox(height: 16),
                                ],
                                if (videos.isNotEmpty) ...[
                                  const _SectionLabel('VIDEOS'),
                                  const SizedBox(height: 10),
                                  for (final v in videos) ...[
                                    _FavoriteTile(
                                      icon: Icons.play_circle_fill_rounded,
                                      title: v.title,
                                      subtitle: 'Favorited video',
                                      onTap: () => _open(context,
                                          name: v.title, url: v.url),
                                      onUnfavorite: () => ref
                                          .read(favoriteVideosProvider.notifier)
                                          .toggle(title: v.title, url: v.url),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ],
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text(label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: c.dim));
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onUnfavorite,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onUnfavorite;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PgCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      onTap: onTap,
      child: Row(
        children: [
          PgIconBadge(icon: icon, color: c.teal, background: c.tealSoft),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: c.dim)),
              ],
            ),
          ),
          IconButton(
            onPressed: onUnfavorite,
            tooltip: 'Remove from favorites',
            icon: Icon(Icons.favorite_rounded, color: c.danger, size: 20),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
              child: Icon(Icons.favorite_rounded, size: 36, color: c.teal),
            ),
            const SizedBox(height: 20),
            Text('No favorites yet',
                textAlign: TextAlign.center,
                style: PgText.serif(size: 19, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Tap the heart on a church, or on a video while watching, to save it here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: c.dim, height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}
