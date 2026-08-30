import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'devotional_share_card.dart';

/// Builds a [DevotionalShareCard] into a temporary off-screen [OverlayEntry]
/// just long enough to capture it, then removes it — same on-demand-capture
/// technique as `streak_share.dart`'s `shareStreakCard`, since
/// `DevotionalScreen` doesn't keep a permanent off-screen card of its own
/// the way `ScriptureScreen` does.
Future<void> shareDevotionalCard({
  required BuildContext context,
  required String title,
  required String question,
  required String reference,
  required String dateLabel,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final key = GlobalKey();
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -DevotionalShareCard.width - 50,
      top: 0,
      child: RepaintBoundary(
        key: key,
        child: DevotionalShareCard(
          title: title,
          question: question,
          reference: reference,
          dateLabel: dateLabel,
        ),
      ),
    ),
  );
  overlay.insert(entry);
  try {
    final bytes = await _captureAfterLayout(key);
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/prayer_guide_devotional_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      text: 'Today\'s devotional, from Prayer Guide 🙏',
    ));
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't share — $e")));
    }
  } finally {
    entry.remove();
  }
}

Future<Uint8List> _captureAfterLayout(GlobalKey key) async {
  await WidgetsBinding.instance.endOfFrame;
  await WidgetsBinding.instance.endOfFrame;
  final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    throw Exception('The card isn\'t ready yet — try again in a moment.');
  }
  final image = await boundary.toImage(pixelRatio: 3);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) throw Exception('Could not render the card.');
  return byteData.buffer.asUint8List();
}
