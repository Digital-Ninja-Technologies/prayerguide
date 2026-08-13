import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/static/nigerian_churches.dart';
import '../../state/favorite_channels_provider.dart';
import '../../widgets/pg_card.dart';
import '../../widgets/pg_icon_badge.dart';

/// Directory of church YouTube channels — a fixed search bar up top filters
/// a curated list of major Nigerian churches (see `nigerian_churches.dart`)
/// so a user can find one without scrolling through all of them. Tapping an
/// entry opens `ChannelWebviewScreen` with that church's real channel; the
/// heart on each row saves it to `favoriteChannelsProvider` (real Supabase
/// row, not local-only) so it shows up in the "Favorites" section here on
/// any device.
///
/// If `CHURCH_YOUTUBE_CHANNEL_URL` is set in `.env` (see SETUP.md), that
/// channel is pinned above the directory as "Your church" — this repo's
/// existing single-channel config still works, it just now sits alongside
/// the built-in directory instead of replacing it.
class ChannelScreen extends ConsumerStatefulWidget {
  const ChannelScreen({super.key});

  @override
  ConsumerState<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends ConsumerState<ChannelScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String? get _customChannelUrl {
    final url = dotenv.env['CHURCH_YOUTUBE_CHANNEL_URL']?.trim();
    return (url == null || url.isEmpty) ? null : url;
  }

  List<NigerianChurch> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return kNigerianChurches;
    return kNigerianChurches.where((ch) => ch.searchText.contains(q)).toList();
  }

  void _open(BuildContext context, {required String name, required String url}) {
    context.push(
        '/channel/view?name=${Uri.encodeComponent(name)}&url=${Uri.encodeComponent(url)}');
  }

  Future<void> _toggleFavorite({required String name, required String url}) async {
    try {
      await ref
          .read(favoriteChannelsProvider.notifier)
          .toggle(name: name, url: url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't update favorites — $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final customUrl = _customChannelUrl;
    final results = _filtered;
    final favorites = ref.watch(favoriteChannelsProvider).valueOrNull ?? [];
    final favoriteUrls = favorites.map((f) => f.url).toSet();
    final showFavorites = favorites.isNotEmpty && _query.trim().isEmpty;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
            child: Text('Channel', style: PgText.serif(size: 26, weight: FontWeight.w600)),
          ),
          // Fixed search panel — stays put while the list below scrolls.
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
            child: Container(
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.line),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(fontSize: 14.5, color: c.text),
                decoration: InputDecoration(
                  hintText: 'Search for a church…',
                  hintStyle: TextStyle(color: c.faint, fontSize: 14.5),
                  prefixIcon: Icon(Icons.search_rounded, color: c.faint, size: 20),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Icons.close_rounded, color: c.faint, size: 18),
                          onPressed: () => setState(() {
                            _searchCtrl.clear();
                            _query = '';
                          }),
                        ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
              children: [
                if (showFavorites) ...[
                  Text('FAVORITES',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: c.dim)),
                  const SizedBox(height: 10),
                  for (final f in favorites) ...[
                    _ChurchTile(
                      name: f.name,
                      subtitle: 'Favorited',
                      isFavorite: true,
                      onTap: () => _open(context, name: f.name, url: f.url),
                      onToggleFavorite: () =>
                          _toggleFavorite(name: f.name, url: f.url),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 8),
                ],
                if (customUrl != null && _query.trim().isEmpty) ...[
                  _ChurchTile(
                    name: 'Your church',
                    subtitle: 'From this app\'s configuration',
                    isFavorite: favoriteUrls.contains(customUrl),
                    onTap: () => _open(context, name: 'Your church', url: customUrl),
                    onToggleFavorite: () =>
                        _toggleFavorite(name: 'Your church', url: customUrl),
                  ),
                  const SizedBox(height: 18),
                  Text('TOP CHURCHES IN NIGERIA',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: c.dim)),
                  const SizedBox(height: 10),
                ],
                if (results.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text('No churches match "${_query.trim()}"',
                          style: TextStyle(color: c.dim, fontSize: 13.5)),
                    ),
                  )
                else
                  for (final ch in results) ...[
                    _ChurchTile(
                      name: ch.name,
                      subtitle: '${ch.leader} · ${ch.city}',
                      isFavorite: favoriteUrls.contains(ch.youtubeUrl),
                      onTap: () => _open(context, name: ch.name, url: ch.youtubeUrl),
                      onToggleFavorite: () =>
                          _toggleFavorite(name: ch.name, url: ch.youtubeUrl),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChurchTile extends StatelessWidget {
  const _ChurchTile({
    required this.name,
    required this.subtitle,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final String name;
  final String subtitle;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PgCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      onTap: onTap,
      child: Row(
        children: [
          PgIconBadge(
              icon: Icons.smart_display_rounded, color: c.teal, background: c.tealSoft),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: c.dim)),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggleFavorite,
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? c.danger : c.faint,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
