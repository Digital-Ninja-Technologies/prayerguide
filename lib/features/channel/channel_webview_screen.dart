import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/pg_colors.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_header.dart';

/// In-app viewer for a single church's YouTube channel, reached by tapping
/// an entry on the Channel tab's directory. Backed by a real WebView (not
/// just a link out) so a signed-in Google/YouTube session persists across
/// app restarts — the platform WebView's cookie jar is durable by default.
/// Not available on web builds (`webview_flutter` is mobile-only here).
class ChannelWebviewScreen extends StatefulWidget {
  const ChannelWebviewScreen({
    super.key,
    required this.channelName,
    required this.channelUrl,
  });

  final String channelName;
  final String channelUrl;

  @override
  State<ChannelWebviewScreen> createState() => _ChannelWebviewScreenState();
}

class _ChannelWebviewScreenState extends State<ChannelWebviewScreen> {
  WebViewController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 14, 0),
            child: PgHeader(
              title: widget.channelName,
              onBack: () => context.pop(),
              trailing: _controller != null
                  ? IconButton(
                      onPressed: _refresh,
                      icon: Icon(Icons.refresh_rounded, color: c.dim),
                      tooltip: 'Refresh',
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
