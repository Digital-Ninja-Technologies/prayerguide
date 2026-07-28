import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/encryption_service.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/theme/pg_colors.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_form_error.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_text_field.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool? _hasRecovery;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final uid = supa.auth.currentUser?.id;
    if (uid == null) return;
    final has = await EncryptionService.instance.hasRecoverySetUp(uid);
    if (mounted) setState(() => _hasRecovery = has);
  }

  Future<void> _openSetupDialog() async {
    final uid = supa.auth.currentUser!.id;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _SetPassphraseDialog(uid: uid),
    );
    if (result == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PgHeader(
                title: 'Privacy & encryption', onBack: () => context.pop()),
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: c.tealSoft,
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(18)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 20, color: c.teal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Your journal entries are end-to-end encrypted. The encryption key lives only on your device — Supabase, and anyone with database access, only ever sees ciphertext. Prayer requests are stored as plain text (protected by row-level access rules) so you can choose to share them with your prayer companion.",
                      style:
                          TextStyle(fontSize: 13.5, height: 1.6, color: c.text),
                    ),
                  ),
                ],
              ),
            ),
            Text('RECOVERY',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: c.dim)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(18)),
              child: _hasRecovery == null
                  ? const Center(
                      child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _hasRecovery!
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.error_outline_rounded,
                              size: 18,
                              color: _hasRecovery! ? c.teal : c.amber,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _hasRecovery!
                                  ? 'Recovery passphrase is set'
                                  : 'No recovery passphrase set',
                              style: const TextStyle(
                                  fontSize: 14.5, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _hasRecovery!
                              ? "If you sign in on a new device, enter this passphrase to unlock your existing entries."
                              : "Without this, a new device or a reinstall can't decrypt entries you've already written — nobody can, not even you. Set a passphrase to allow recovery.",
                          style: TextStyle(
                              fontSize: 13, height: 1.55, color: c.dim),
                        ),
                        const SizedBox(height: 14),
                        PgButton(
                          label: _hasRecovery!
                              ? 'Change recovery passphrase'
                              : 'Set up recovery passphrase',
                          variant: PgButtonVariant.outline,
                          onPressed: _openSetupDialog,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetPassphraseDialog extends StatefulWidget {
  const _SetPassphraseDialog({required this.uid});
  final String uid;

  @override
  State<_SetPassphraseDialog> createState() => _SetPassphraseDialogState();
}

class _SetPassphraseDialogState extends State<_SetPassphraseDialog> {
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _save() async {
    if (_p1.text.length < 8) {
      setState(() => _error = 'Use at least 8 characters.');
      return;
    }
    if (_p1.text != _p2.text) {
      setState(() => _error = "Passphrases don't match.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await EncryptionService.instance.setupRecovery(widget.uid, _p1.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = 'Could not save: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _p1.dispose();
    _p2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AlertDialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Set a recovery passphrase'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Choose something memorable — this is the only way to unlock your encrypted entries on a new device. We can't reset it for you.",
            style: TextStyle(fontSize: 13, color: c.dim, height: 1.5),
          ),
          const SizedBox(height: 16),
          PgTextField(
              controller: _p1, hint: 'New passphrase', obscureText: true),
          const SizedBox(height: 10),
          PgTextField(
              controller: _p2, hint: 'Confirm passphrase', obscureText: true),
          PgFormError(_error),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel')),
        TextButton(
            onPressed: _loading ? null : _save,
            child: Text(_loading ? 'Saving…' : 'Save')),
      ],
    );
  }
}
