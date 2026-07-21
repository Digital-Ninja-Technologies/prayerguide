import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_section_label.dart';
import '../../widgets/pg_text_field.dart';

class InviteScreen extends StatelessWidget {
  const InviteScreen({super.key});

  static const _link = 'prayerguide.app/j/sarah-9f2k';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(title: 'Invite a companion', onBack: () => context.pop()),
            Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Text(
                "Pray alongside someone you trust. You'll share encouragement and chosen requests — never your private journal.",
                style: TextStyle(fontSize: 14.5, height: 1.6, color: c.dim),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
              margin: const EdgeInsets.only(bottom: 22),
              decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(22)),
              child: Column(
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.qr_code_2_rounded, size: 120, color: Color(0xFF0E1513)),
                  ),
                  const SizedBox(height: 14),
                  Text('Have them scan this to pair instantly', style: TextStyle(fontSize: 13, color: c.dim)),
                ],
              ),
            ),
            const PgSectionLabel('Or share your invite'),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_link,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13.5, color: c.dim, fontFamily: 'monospace')),
                  ),
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: _link));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite link copied')));
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: c.teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text('Copy', style: TextStyle(color: c.onTeal, fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  const Expanded(child: PgTextField(hint: 'Invite by username or email')),
                  const SizedBox(width: 10),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line2), borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.arrow_forward_rounded, color: c.teal),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(child: _ShareOption(icon: Icons.ios_share_rounded, label: 'Share link')),
                const SizedBox(width: 10),
                Expanded(child: _ShareOption(icon: Icons.qr_code_rounded, label: 'Show QR')),
                const SizedBox(width: 10),
                Expanded(child: _ShareOption(icon: Icons.mail_outline_rounded, label: 'Message')),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: Text(
                'Free plan includes one companion. You can change or remove them anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, height: 1.5, color: c.faint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  const _ShareOption({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, size: 22, color: c.teal),
          const SizedBox(height: 7),
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
