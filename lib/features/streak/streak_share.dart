import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'streak_share_card.dart';

/// On-demand version of what `streak_screen.dart` does with a permanently
/// embedded off-screen card: builds the same [StreakShareCard] into a
/// temporary [OverlayEntry] just long enough to capture it, then removes
/// it. Lets other screens (the "well prayed" completion screen, the daily
/// streak popup) trigger a share without needing their own copy of the
/// capture plumbing or a permanent off-screen widget in their tree.
Future<Uint8List> _captureStreakCard({
  required BuildContext context,
  required int streak,
  required int longestStreak,
  required String weekTimeLabel,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final key = GlobalKey();
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -StreakShareCard.width - 50,
      top: 0,
      child: RepaintBoundary(
        key: key,
        child: StreakShareCard(
          streak: streak,
          longestStreak: longestStreak,
          weekTimeLabel: weekTimeLabel,
          dateLabel: DateFormat('MMMM d').format(DateTime.now()),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  try {
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
  } finally {
    entry.remove();
  }
}

/// Captures and opens the share sheet directly — used from prompts where
/// tapping "Share" should go straight to sharing, not a save-vs-share
/// choice (that choice already lives on the Streak screen itself).
Future<void> shareStreakCard({
  required BuildContext context,
  required int streak,
  required int longestStreak,
  required String weekTimeLabel,
}) async {
  try {
    final bytes = await _captureStreakCard(
      context: context,
      streak: streak,
      longestStreak: longestStreak,
      weekTimeLabel: weekTimeLabel,
    );
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/prayer_guide_streak_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      text: 'My prayer streak, from Prayer Guide 🔥🙏',
    ));
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't share — $e")));
    }
  }
}
