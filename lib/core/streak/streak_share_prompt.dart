import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/static/pg_content.dart';
import '../../features/streak/streak_share.dart';
import '../theme/pg_colors.dart';
import '../../widgets/pg_button.dart';

const _prefsPromptedPrefix = 'pg_streak_share_prompted_';

/// A "share your streak" prompt at a milestone streak day — not shown on
/// every single completed session (that would turn a core daily action
/// into friction), only when [streakCount] lands on one of [milestoneDays],
/// and at most once per specific milestone value (a fresh run at the same
/// milestone after a reset shows it again, which is fine — it's a genuine
/// new achievement).
Future<void> maybeShowStreakSharePrompt(
  BuildContext context, {
  required int streakCount,
  required int longestStreak,
  required String weekTimeLabel,
}) async {
  if (!milestoneDays.contains(streakCount)) return;
  final prefs = await SharedPreferences.getInstance();
  final key = '$_prefsPromptedPrefix$streakCount';
  if (prefs.getBool(key) ?? false) return;
  await prefs.setBool(key, true);
  if (!context.mounted) return;
  // The dialog's own builder context becomes deactivated the moment it
  // pops itself — the Share button needs the *caller's* still-live context
  // (this one) to build the off-screen card afterward via an Overlay.
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _StreakSharePromptDialog(
      streakCount: streakCount,
      onShare: () {
        Navigator.of(dialogContext).pop();
        shareStreakCard(
          context: context,
          streak: streakCount,
          longestStreak: longestStreak,
          weekTimeLabel: weekTimeLabel,
        );
      },
    ),
  );
}

class _StreakSharePromptDialog extends StatelessWidget {
  const _StreakSharePromptDialog({
    required this.streakCount,
    required this.onShare,
  });

  final int streakCount;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AlertDialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('$streakCount days of prayer 🔥'),
      content: Text(
        "That's a real rhythm. Want to share it?",
        style: TextStyle(color: c.dim, height: 1.4),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Not now', style: TextStyle(color: c.dim)),
        ),
        PgButton(
          label: 'Share',
          expand: false,
          dense: true,
          onPressed: onShare,
        ),
      ],
    );
  }
}
