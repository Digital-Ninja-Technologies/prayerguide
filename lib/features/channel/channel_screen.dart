import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../widgets/pg_button.dart';

/// In-app viewer for the church's YouTube channel. Backed by a real WebView
/// (not just a link out) so a signed-in Google/YouTube session persists
/// across app restarts — the platform WebView's cookie jar is durable by
/// default, so nothing extra is needed to "stay signed in".
///
/// Configured via `CHURCH_YOUTUBE_CHANNEL_URL` in `.env` — see SETUP.md.
/// Not available on web builds (`webview_flutter` is mobile-only here);
/// that build target only exists for internal verification, not shipping.
class ChannelScreen extends StatefulWidget {
  const ChannelScreen({super.key});

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  WebViewController? _controller;
  bool _loading = true;
  String? _error;

  String? get _channelUrl {
    final url = dotenv.env['CHURCH_YOUTUBE_CHANNEL_URL']?.trim();
    return (url == null || url.isEmpty) ? null : url;
  }

  @override
  void initState() {
    super.initState();
    final url = _channelUrl;
    if (!kIsWeb && url != null) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
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
        ..loadRequest(Uri.parse(url));
    }
  }

  void _refresh() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _controller?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final url = _channelUrl;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Channel', style: PgText.serif(size: 26, weight: FontWeight.w600)),
                if (_controller != null)
                  IconButton(
                    onPressed: _refresh,
                    icon: Icon(Icons.refresh_rounded, color: c.dim),
                    tooltip: 'Refresh',
                  ),
              ],
            ),
          ),
          Expanded(
            child: url == null
                ? const _ChannelMessage(
                    icon: Icons.smart_display_outlined,
                    title: 'Channel not configured',
                    body:
                        "Set CHURCH_YOUTUBE_CHANNEL_URL in .env to show the church's "
                        "YouTube channel here — see SETUP.md.",
                  )
                : kIsWeb
                    ? _ChannelMessage(
                        icon: Icons.smart_display_outlined,
                        title: 'Open the channel',
                        body: "The in-app channel viewer isn't available on web builds.",
                        actionLabel: 'Open in browser',
                        onAction: () =>
                            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                      )
                    : Stack(
                        children: [
                          WebViewWidget(controller: _controller!),
                          if (_loading)
                            const Center(child: CircularProgressIndicator()),
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
