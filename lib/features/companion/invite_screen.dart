import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/pg_colors.dart';
import '../../state/companion_provider.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_section_label.dart';
import '../../widgets/pg_text_field.dart';

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  String? _code;
  String? _error;
  final _redeemController = TextEditingController();
  bool _redeeming = false;

  @override
  void initState() {
    super.initState();
    _createInvite();
  }

  Future<void> _createInvite() async {
    try {
      final code = await ref.read(companionRepositoryProvider).createInvite();
      if (mounted) setState(() => _code = code);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not create an invite: $e');
    }
  }

  Future<void> _redeem() async {
    final code = _redeemController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _redeeming = true;
      _error = null;
    });
    try {
      await ref.read(companionRepositoryProvider).redeemInvite(code);
      ref.invalidate(companionProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  Future<void> _scan() async {
    final code = await context.push<String>('/companion/invite/scan');
    if (code == null || !mounted) return;
    _redeemController.text = code;
    await _redeem();
  }

  @override
  void dispose() {
    _redeemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(title: 'Invite a companion', onBack: () => context.pop()),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(child: _buildContent(context, c)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PgColors c) {
    final link = _code == null ? null : 'prayerguide.app/j/$_code';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Text(
            "Pray alongside someone you trust. You'll share encouragement and a check-in streak — never your private journal.",
            style: TextStyle(fontSize: 14.5, height: 1.6, color: c.dim),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
          margin: const EdgeInsets.only(bottom: 22),
          decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(22)),
          child: Column(
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.all(12),
                child: link == null
                    ? const Icon(Icons.qr_code_2_rounded,
                        size: 120, color: Color(0xFF0E1513))
                    : QrImageView(
                        data: link,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(color: Color(0xFF0E1513)),
                        dataModuleStyle: const QrDataModuleStyle(color: Color(0xFF0E1513)),
                      ),
              ),
              const SizedBox(height: 14),
              Text(
                _code == null ? 'Preparing your invite…' : 'Have them scan this to pair instantly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: c.dim),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _scan,
                icon: Icon(Icons.qr_code_scanner_rounded, size: 18, color: c.teal),
                label: Text('Scan a code instead', style: TextStyle(color: c.teal, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.line),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        const PgSectionLabel('Or share your invite'),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Expanded(
                child: Text(link ?? 'Generating…',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13.5, color: c.dim, fontFamily: 'monospace')),
              ),
              TextButton(
                onPressed: link == null
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: link));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Invite link copied')));
                      },
                style: TextButton.styleFrom(
                  backgroundColor: c.teal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text('Copy',
                    style: TextStyle(
                        color: c.onTeal,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const PgSectionLabel('Have a code from someone else?'),
        Row(
          children: [
            Expanded(
              child: PgTextField(
                controller: _redeemController,
                hint: 'Enter their invite code',
                errorText: _error,
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: c.teal,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _redeeming ? null : _redeem,
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: _redeeming
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: c.onTeal))
                      : Icon(Icons.arrow_forward_rounded, color: c.onTeal),
                ),
              ),
            ),
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
    );
  }
}
