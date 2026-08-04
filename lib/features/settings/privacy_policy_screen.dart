import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../widgets/pg_header.dart';
import 'about_help_screen.dart' show kSupportEmail;

const _kEffectiveDate = 'July 2026';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
            child:
                PgHeader(title: 'Privacy Policy', onBack: () => context.pop()),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Effective $_kEffectiveDate',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: c.faint,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 18),
                  const _LegalSection(
                    title: 'The short version',
                    body:
                        "Prayer Guide is built by Digital Ninja Technologies. Your journal is end-to-end "
                        "encrypted — we cannot read it, even if we wanted to. We don't sell your data, "
                        "we don't show ads, and we don't use your prayers or journal to train any AI "
                        "model. This page explains exactly what we collect and why.",
                  ),
                  const _LegalSection(
                    title: '1. Information we collect',
                    body:
                        "Account information: your email address and, if you sign in with Google or "
                        "Apple, the name and email they share with us. Profile data: display name, theme "
                        "preference, and streak settings you choose. Activity data: prayer session "
                        "timestamps and durations (used to compute your streak and Growth Insights), "
                        "reading-plan and challenge progress, fasting session times, and focus-mode "
                        "session times. Content you create: journal entries, prayer requests, Bible "
                        "highlights/bookmarks/notes, and devotional/challenge activity.",
                  ),
                  const _LegalSection(
                    title: '2. What stays encrypted vs. plain text',
                    body:
                        "Journal entries are encrypted on your device before they ever reach our "
                        "servers (AES-256-GCM), using a key stored only in your device's Keychain or "
                        "Keystore. We store only unreadable ciphertext — nobody at Digital Ninja "
                        "Technologies, and nobody with access to our database, can read your journal. "
                        "Prayer requests are stored as plain text, protected by row-level access rules "
                        "restricting them to you and, for requests you explicitly mark as shared, a "
                        "prayer companion you've paired with. We made this trade-off deliberately so "
                        "requests could be shared with a companion — true end-to-end encryption would "
                        "make that impossible.",
                  ),
                  const _LegalSection(
                    title: '3. Optional cloud backup',
                    body:
                        "If you turn on cloud backup (Settings > Privacy & encryption), a copy of your "
                        "journal encryption key is stored in your personal iCloud Keychain (iOS) or your "
                        "Google account's private app-data folder (Android) — a location only you can "
                        "access, not Digital Ninja Technologies. This is opt-in; without it, an "
                        "encryption key that's lost (e.g. from an uninstall with no other signed-in "
                        "device) cannot be recovered by anyone, including us.",
                  ),
                  const _LegalSection(
                    title: '4. Who we share data with',
                    body:
                        "Supabase — our backend provider — hosts our database and handles "
                        "authentication; they process data on our behalf under their own security "
                        "commitments. Google and Apple process sign-in if you choose those options. We "
                        "do not sell, rent, or share your personal information with advertisers or data "
                        "brokers, and we do not use your content to train machine learning models.",
                  ),
                  const _LegalSection(
                    title: '5. Your choices',
                    body:
                        "You can edit or delete journal entries and prayer requests at any time from "
                        "within the app. You can turn cloud backup on or off whenever you like. To "
                        "delete your account and all associated data, email us at $kSupportEmail — we'll "
                        "take care of it.",
                  ),
                  const _LegalSection(
                    title: '6. Children',
                    body:
                        "Prayer Guide is not directed at children under 13, and we do not knowingly "
                        "collect information from them. If you believe a child has provided us "
                        "information, contact us and we'll remove it.",
                  ),
                  const _LegalSection(
                    title: '7. Changes to this policy',
                    body:
                        "If we make a material change to how we handle your data, we'll update the "
                        "effective date above and let you know in the app.",
                  ),
                  const _LegalSection(
                    title: '8. Contact',
                    body:
                        "Questions about this policy? Email us at $kSupportEmail.",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: PgText.serif(size: 17, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(fontSize: 14, height: 1.6, color: c.dim)),
        ],
      ),
    );
  }
}
