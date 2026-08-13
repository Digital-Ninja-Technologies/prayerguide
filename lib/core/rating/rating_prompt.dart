import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/pg_colors.dart';
import '../../widgets/pg_button.dart';

const _androidPackage = 'com.prayerguide.prayer_guide';
const _prefsShownKey = 'pg_rating_prompted';

/// The App Store numeric id (assigned once the app has a first App Store
/// Connect submission) — set `IOS_APP_STORE_ID` in `.env` once published.
/// Without it, the iOS review link can't be built yet.
String? get _iosAppStoreId {
  final id = dotenv.env['IOS_APP_STORE_ID']?.trim();
  return (id == null || id.isEmpty) ? null : id;
}

/// Opens the platform store listing (with a direct "write a review" deep
/// link where possible). Shows a friendly message instead of failing
/// silently if the iOS App Store id isn't configured yet.
Future<void> openStoreListing(BuildContext context) async {
  if (Platform.isIOS) {
    final id = _iosAppStoreId;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("The App Store listing isn't available yet.")),
      );
      return;
    }
    await launchUrl(
      Uri.parse('https://apps.apple.com/app/id$id?action=write-review'),
      mode: LaunchMode.externalApplication,
    );
    return;
  }
  await launchUrl(
    Uri.parse('https://play.google.com/store/apps/details?id=$_androidPackage'),
    mode: LaunchMode.externalApplication,
  );
}

/// Shows the rating pop-up at most once per install: call after a natural
/// moment of engagement (e.g. reaching a prayer streak). No-ops if it's
/// already been shown, or shown too recently in this session.
Future<void> maybeShowRatingPrompt(BuildContext context, {required int streakCount}) async {
  if (streakCount < 3) return;
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_prefsShownKey) ?? false) return;
  await prefs.setBool(_prefsShownKey, true);
  if (context.mounted) await showRatingPromptDialog(context);
}

Future<void> showRatingPromptDialog(BuildContext context) {
  final c = context.colors;
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Enjoying Prayer Guide?'),
      content: Text(
        "If it's been a help to your prayer life, a quick rating goes a long way "
        "toward other people finding it too.",
        style: TextStyle(color: c.dim, height: 1.4),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Not now', style: TextStyle(color: c.dim)),
        ),
        PgButton(
          label: 'Rate us',
          expand: false,
          dense: true,
          onPressed: () {
            Navigator.of(context).pop();
            openStoreListing(context);
          },
        ),
      ],
    ),
  );
}
