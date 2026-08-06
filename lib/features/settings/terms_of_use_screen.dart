import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../widgets/pg_header.dart';
import 'about_help_screen.dart' show kSupportEmail;

const _kEffectiveDate = 'August 2026';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
            child: PgHeader(title: 'Terms of Use', onBack: () => context.pop()),
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
                    title: '1. Agreement',
                    body:
                        "These terms govern your use of Prayer Guide, built by Digital Ninja "
                        "Technologies. By creating an account or using the app, you agree to them. If "
                        "you don't agree, please don't use the app.",
                  ),
                  const _LegalSection(
                    title: '2. What Prayer Guide is for',
                    body:
                        "Prayer Guide is a personal devotional tool — guided prayer, a Bible reader, "
                        "journaling, prayer requests, and a gentle habit streak. It is not a substitute "
                        "for pastoral care, professional counseling, or medical or crisis support. If "
                        "you're in crisis, please contact a licensed professional or emergency services "
                        "in your area.",
                  ),
                  const _LegalSection(
                    title: '3. Your account',
                    body:
                        "You're responsible for keeping your login credentials secure and for "
                        "everything that happens under your account. You must be able to form a binding "
                        "agreement to use Prayer Guide — broadly, an adult, or a minor using it with a "
                        "parent or guardian's permission, consistent with the age requirements of your "
                        "app store.",
                  ),
                  const _LegalSection(
                    title: '4. Your content',
                    body:
                        "You own what you write — journal entries, prayer requests, notes. By sharing a "
                        "prayer request with a companion, you're choosing to let that specific person "
                        "see it; you can un-share it at any time. We don't claim ownership of your "
                        "content and don't use it to train AI models or share it with advertisers. "
                        "Journal entries are end-to-end encrypted, which also means: if you lose access "
                        "to your encryption key (e.g. an uninstall with no cloud backup and no other "
                        "signed-in device), we cannot recover that content for you — nobody can.",
                  ),
                  const _LegalSection(
                    title: '5. Acceptable use',
                    body:
                        "Use Prayer Guide the way it's meant to be used: don't try to break, reverse "
                        "engineer, or abuse the service; don't use it to harass, threaten, or share "
                        "content that's illegal or infringes someone else's rights; don't attempt to "
                        "access another user's account or data. We may suspend or terminate accounts "
                        "that violate this.",
                  ),
                  const _LegalSection(
                    title: '6. Premium subscriptions',
                    body:
                        "Prayer Guide offers an optional Premium tier with additional features. "
                        "Subscription billing, when enabled, is handled entirely through the App Store "
                        "or Google Play — refunds, cancellations, and billing disputes are subject to "
                        "their respective policies, not ours.",
                  ),
                  const _LegalSection(
                    title: '7. Termination',
                    body:
                        "You can stop using Prayer Guide and delete your account at any time from "
                        "Settings > Delete account, or by emailing $kSupportEmail. We may suspend or "
                        "terminate access for accounts that violate these terms.",
                  ),
                  const _LegalSection(
                    title: '8. Disclaimer & limitation of liability',
                    body:
                        "Prayer Guide is provided \"as is,\" without warranties of any kind. We work "
                        "hard to keep it reliable and your data safe, but we can't guarantee "
                        "uninterrupted or error-free service. To the fullest extent permitted by law, "
                        "Digital Ninja Technologies is not liable for indirect, incidental, or "
                        "consequential damages arising from your use of the app.",
                  ),
                  const _LegalSection(
                    title: '9. Changes to these terms',
                    body:
                        "We may update these terms as the app evolves. If we make a material change, "
                        "we'll update the effective date above and let you know in the app.",
                  ),
                  const _LegalSection(
                    title: '10. Contact',
                    body:
                        "Questions about these terms? Email us at $kSupportEmail.",
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
