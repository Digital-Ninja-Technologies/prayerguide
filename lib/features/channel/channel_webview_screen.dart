import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/pg_colors.dart';
import '../../state/favorite_videos_provider.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_header.dart';

/// In-app viewer for a single church's YouTube channel, reached by tapping
/// an entry on the Channel tab's directory — or a favorited video, reached
/// by tapping an entry in the "Favorite videos" section, since this screen
/// just needs a name + url either way. Backed by a real WebView (not just a
/// link out) so a signed-in Google/YouTube session persists across app
/// restarts — the platform WebView's cookie jar is durable by default.
/// Not available on web builds (`webview_flutter` is mobile-only here).
///
/// The heart in the header favorites whatever page is *currently loaded* —
/// tap a video from the channel's own listing to navigate to it inside this
/// same WebView, then favorite it; it'll show up in "Favorite videos" back
/// on the Channel tab. Title comes from `getTitle()` (the page's own
/// `document.title`, e.g. "Sunday Service | Church Name - YouTube").
class ChannelWebviewScreen extends ConsumerStatefulWidget {
  const ChannelWebviewScreen({
    super.key,
    required this.channelName,
    required this.channelUrl,
  });

  final String channelName;
  final String channelUrl;

  @override
  ConsumerState<ChannelWebviewScreen> createState() => _ChannelWebviewScreenState();
}

class _ChannelWebviewScreenState extends ConsumerState<ChannelWebviewScreen> {
  WebViewController? _controller;
  bool _loading = true;
  String? _error;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.channelUrl;
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() {
                _loading = false;
                _currentUrl = url;
              });
            }
          },
          onWebResourceError: (e) {
            if (mounted) {
              setState(() {
                _loading = false;
                _error = e.description;
              });
            }
          },
        ))
        ..loadRequest(Uri.parse(widget.channelUrl));
    }
  }

  void _refresh() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _controller?.reload();
  }

  Future<void> _toggleFavoriteVideo() async {
    final controller = _controller;
    if (controller == null) return;
    final url = await controller.currentUrl() ?? _currentUrl;
    if (url == null) return;
    final title = await controller.getTitle() ?? widget.channelName;
    if (!mounted) return;
    try {
      await ref.read(favoriteVideosProvider.notifier).toggle(title: title, url: url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't update favorites — $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isFavoriteVideo = _currentUrl != null &&
        ref.watch(favoriteVideosProvider).valueOrNull?.any((f) => f.url == _currentUrl) ==
            true;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 14, 0),
            child: PgHeader(
              title: widget.channelName,
              onBack: () => context.pop(),
              trailing: _controller != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _toggleFavoriteVideo,
                          tooltip: isFavoriteVideo
                              ? 'Remove this video from favorites'
                              : 'Favorite this video',
                          icon: Icon(
                            isFavoriteVideo
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavoriteVideo ? c.danger : c.dim,
                          ),
                        ),
                        IconButton(
                          onPressed: _refresh,
                          icon: Icon(Icons.refresh_rounded, color: c.dim),
                          tooltip: 'Refresh',
                        ),
                      ],
                    )
                  : null,
            ),
          ),
          Expanded(
            child: kIsWeb
                ? _ChannelMessage(
                    icon: Icons.smart_display_outlined,
                    title: 'Open the channel',
                    body: "The in-app channel viewer isn't available on web builds.",
                    actionLabel: 'Open in browser',
                    onAction: () => launchUrl(Uri.parse(widget.channelUrl),
                        mode: LaunchMode.externalApplication),
                  )
                : Stack(
                    children: [
                      WebViewWidget(controller: _controller!),
                      if (_loading) const Center(child: CircularProgressIndicator()),
                      if (_error != null)
                        _ChannelMessage(
                          icon: Icons.wifi_off_rounded,
                          title: "Couldn't load the channel",
                          body: _error!,
                          actionLabel: 'Try again',
                          onAction: _refresh,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChannelMessage extends StatelessWidget {
  const _ChannelMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration:
                  BoxDecoration(color: c.tealSoft, borderRadius: BorderRadius.circular(20)),
              child: Icon(icon, size: 30, color: c.teal),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(body,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: c.dim, height: 1.5)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              PgButton(label: actionLabel!, expand: false, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
