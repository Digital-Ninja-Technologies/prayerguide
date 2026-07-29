import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_section_label.dart';

const kSupportEmail = 'thedigitalninjatechnologies@gmail.com';

const _faqs = [
  (
    'Is my journal really private?',
    "Yes. Journal entries are end-to-end encrypted on your device before they're ever sent to our servers — we only ever see unreadable ciphertext, and there's no way for us (or anyone with database access) to read them.",
  ),
  (
    "What happens if I lose my phone or reinstall the app?",
    "If you turned on cloud backup (Settings > Privacy & encryption), your journal key restores automatically on your other devices via iCloud (iOS) or Google Drive (Android). Without a backup, old journal entries can't be recovered by anyone — that's the trade-off of true end-to-end encryption.",
  ),
  (
    'Are prayer requests encrypted too?',
    "No — requests are stored as plain text so you can choose to share them with your prayer companion. They're still protected by row-level access rules, so only you (and a companion you've paired with, for requests you mark shared) can see them.",
  ),
  (
    'How does the prayer streak work?',
    "Any prayer session of 3 minutes or longer counts toward your streak for the day. Missing a day resets the count, but there's no shame framing — streak protection reminders can give you a gentle nudge if you haven't prayed yet and it's getting late.",
  ),
  (
    'Can I use Prayer Guide without an internet connection?',
    "The Bible reader, reading plans, and devotional all work fully offline since the full KJV text is bundled with the app. Journal, requests, streak, and companion features need a connection to sync with your account.",
  ),
  (
    'How do I delete my account or data?',
    "Email us at $kSupportEmail and we'll take care of it.",
  ),
];

class AboutHelpScreen extends StatelessWidget {
  const AboutHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(title: 'About & help', onBack: () => context.pop()),
            const PgSectionLabel('About us'),
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prayer Guide', style: PgText.serif(size: 19, weight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    "Prayer Guide is built by Digital Ninja Technologies to help you build a consistent, unhurried prayer life — guided prayer, Scripture, journaling, and people to walk alongside you, without the guilt-driven streaks and noise so many habit apps lean on.",
                    style: TextStyle(fontSize: 14, height: 1.6, color: c.dim),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "We built this because we wanted a prayer app that felt like a quiet room, not a scoreboard — your data stays yours, your journal stays private, and nothing here is designed to guilt you into opening it.",
                    style: TextStyle(fontSize: 14, height: 1.6, color: c.dim),
                  ),
                ],
              ),
            ),
            const PgSectionLabel('Frequently asked questions'),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [for (final faq in _faqs) _FaqTile(question: faq.$1, answer: faq.$2)],
              ),
            ),
            const PgSectionLabel('Contact & feedback'),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mail_outline_rounded, size: 18, color: c.teal),
                      const SizedBox(width: 8),
                      const Text('Get in touch', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Questions, feedback, a bug you've spotted, or a feature you wish existed — we'd genuinely like to hear it.",
                    style: TextStyle(fontSize: 13, height: 1.55, color: c.dim),
                  ),
                  const SizedBox(height: 14),
                  PgButton(
                    label: kSupportEmail,
                    icon: Icon(Icons.send_rounded, size: 16, color: c.onTeal),
                    onPressed: () => launchUrl(
                      Uri(scheme: 'mailto', path: kSupportEmail, query: 'subject=Prayer Guide feedback'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(child: Text('Prayer Guide · v1.0.0', style: TextStyle(fontSize: 11.5, color: c.faint))),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _open = !_open),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(widget.question, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    ),
                    Icon(_open ? Icons.remove_rounded : Icons.add_rounded, size: 19, color: c.teal),
                  ],
                ),
                if (_open) ...[
                  const SizedBox(height: 10),
                  Text(widget.answer, style: TextStyle(fontSize: 13.5, height: 1.6, color: c.dim)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
