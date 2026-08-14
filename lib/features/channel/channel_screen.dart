import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/static/nigerian_churches.dart';
import '../../state/custom_channels_provider.dart';
import '../../state/favorite_channels_provider.dart';
import '../../state/hidden_channels_provider.dart';
import '../../widgets/pg_card.dart';
import '../../widgets/pg_icon_badge.dart';

/// Directory of church YouTube channels — a fixed search bar up top filters
/// a curated list of major Nigerian churches (see `nigerian_churches.dart`)
/// so a user can find one without scrolling through all of them. Tapping an
/// entry opens `ChannelWebviewScreen` with that church's real channel; the
/// heart on each row saves it to `favoriteChannelsProvider` (real Supabase
/// row, not local-only).
///
/// The heart icon beside "+" opens `FavoritesScreen` — every favorited
/// channel and video, on its own page, rather than an inline section here.
/// The "+" button next to the search bar lets a user add their own channel
/// (`custom_channels`, migration 0024) — shown in "Your channels", with its
/// own delete button since, unlike the curated directory, these are entries
/// the user owns.
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

  List<NigerianChurch> _filtered(Set<String> hiddenUrls) {
    final q = _query.trim().toLowerCase();
    return kNigerianChurches
        .where((ch) => !hiddenUrls.contains(ch.youtubeUrl))
        .where((ch) => q.isEmpty || ch.searchText.contains(q))
        .toList();
  }

  void _open(BuildContext context,
      {required String name, required String url}) {
    context.push(
        '/channel/view?name=${Uri.encodeComponent(name)}&url=${Uri.encodeComponent(url)}');
  }

  Future<void> _hideChannel(String name, String url) async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Remove $name from your list?'),
        content: const Text(
            "It won't show up in your directory or favorites anymore. This can't be undone from within the app."),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Remove', style: TextStyle(color: c.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(hiddenChannelsProvider.notifier).hide(url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't remove that channel — $e")));
    }
  }

  Future<void> _toggleFavorite(
      {required String name, required String url}) async {
    try {
      await ref
          .read(favoriteChannelsProvider.notifier)
          .toggle(name: name, url: url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't update favorites — $e")));
    }
  }

  Future<void> _addCustomChannel() async {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final c = context.colors;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Add a channel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Channel name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              keyboardType: TextInputType.url,
              decoration:
                  const InputDecoration(labelText: 'YouTube channel URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Add', style: TextStyle(color: c.teal)),
          ),
        ],
      ),
    );
    if (result != true) return;

    final name = nameCtrl.text.trim();
    final url = urlCtrl.text.trim();
    if (name.isEmpty || url.isEmpty) return;
    if (!(url.startsWith('http://') || url.startsWith('https://'))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a full URL, starting with https://')));
      return;
    }

    try {
      await ref.read(customChannelsProvider.notifier).add(name: name, url: url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't add that channel — $e")));
    }
  }

  Future<void> _removeCustomChannel(String id, String name) async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Remove $name?'),
        content:
            const Text("You can add it again later if you change your mind."),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Remove', style: TextStyle(color: c.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(customChannelsProvider.notifier).remove(id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't remove that channel — $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hiddenUrls = ref.watch(hiddenChannelsProvider).valueOrNull ?? {};
    final customUrl = _customChannelUrl;
    final isCustomUrlHidden =
        customUrl != null && hiddenUrls.contains(customUrl);
    final results = _filtered(hiddenUrls);
    final favorites = (ref.watch(favoriteChannelsProvider).valueOrNull ?? [])
        .where((f) => !hiddenUrls.contains(f.url))
        .toList();
    final favoriteUrls = favorites.map((f) => f.url).toSet();
    final customChannels = ref.watch(customChannelsProvider).valueOrNull ?? [];
    final showCustomChannels =
        customChannels.isNotEmpty && _query.trim().isEmpty;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 14, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Channel',
                    style: PgText.serif(size: 26, weight: FontWeight.w600)),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.push('/channel/favorites'),
                      tooltip: 'Favorites',
                      icon: Icon(Icons.favorite_rounded, color: c.danger),
                    ),
                    IconButton(
                      onPressed: _addCustomChannel,
                      tooltip: 'Add your own channel',
                      icon: Icon(Icons.add_circle_rounded,
                          color: c.teal, size: 28),
                    ),
                  ],
                ),
              ],
            ),
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
                  prefixIcon:
                      Icon(Icons.search_rounded, color: c.faint, size: 20),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: c.faint, size: 18),
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
                if (showCustomChannels) ...[
                  Text('YOUR CHANNELS',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: c.dim)),
                  const SizedBox(height: 10),
                  for (final ch in customChannels) ...[
                    _ChurchTile(
                      name: ch.name,
                      subtitle: 'Added by you',
                      onTap: () => _open(context, name: ch.name, url: ch.url),
                      trailing: IconButton(
                        onPressed: () => _removeCustomChannel(ch.id, ch.name),
                        tooltip: 'Remove',
                        icon: Icon(Icons.delete_outline_rounded,
                            color: c.faint, size: 20),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 8),
                ],
                if (customUrl != null &&
                    !isCustomUrlHidden &&
                    _query.trim().isEmpty) ...[
                  _ChurchTile(
                    name: 'Your church',
                    subtitle: 'From this app\'s configuration',
                    onTap: () =>
                        _open(context, name: 'Your church', url: customUrl),
                    trailing: _ChannelActions(
                      isFavorite: favoriteUrls.contains(customUrl),
                      onToggleFavorite: () =>
                          _toggleFavorite(name: 'Your church', url: customUrl),
                      onHide: () => _hideChannel('Your church', customUrl),
                    ),
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
                      onTap: () =>
                          _open(context, name: ch.name, url: ch.youtubeUrl),
                      trailing: _ChannelActions(
                        isFavorite: favoriteUrls.contains(ch.youtubeUrl),
                        onToggleFavorite: () =>
                            _toggleFavorite(name: ch.name, url: ch.youtubeUrl),
                        onHide: () => _hideChannel(ch.name, ch.youtubeUrl),
                      ),
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

/// Heart (favorite/unlike toggle) + a small "remove from my list" action —
/// used on every curated/favorited/"Your church" tile. Unliking just clears
/// the favorite (the entry stays in the directory); hiding removes it from
/// the directory entirely via `hiddenChannelsProvider`.
class _ChannelActions extends StatelessWidget {
  const _ChannelActions({
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onHide,
  });

  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onToggleFavorite,
          tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? c.danger : c.faint,
            size: 20,
          ),
        ),
        IconButton(
          onPressed: onHide,
          tooltip: 'Remove from your list',
          icon: Icon(Icons.close_rounded, color: c.faint, size: 20),
        ),
      ],
    );
  }
}

class _ChurchTile extends StatelessWidget {
  const _ChurchTile({
    required this.name,
    required this.subtitle,
    required this.onTap,
    required this.trailing,
  });

  final String name;
  final String subtitle;
  final VoidCallback onTap;
  final Widget trailing;

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
              icon: Icons.smart_display_rounded,
              color: c.teal,
              background: c.tealSoft),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
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
          trailing,
        ],
      ),
    );
  }
}
