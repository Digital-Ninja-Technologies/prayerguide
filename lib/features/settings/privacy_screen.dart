import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/backup/cloud_backup_service.dart';
import '../../core/security/encryption_service.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/theme/pg_colors.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_header.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool? _isBackedUp;
  bool _working = false;
  String? _error;
  String? _status;

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final uid = supa.auth.currentUser?.id;
    if (uid == null) return;
    if (_isIOS) {
      final backed = await EncryptionService.instance.isBackedUpToICloud(uid);
      if (mounted) setState(() => _isBackedUp = backed);
    } else {
      // No silent check for Google Drive — it needs an interactive sign-in.
      if (mounted) setState(() => _isBackedUp = false);
    }
  }

  Future<void> _backup() async {
    final uid = supa.auth.currentUser!.id;
    setState(() {
      _working = true;
      _error = null;
      _status = null;
    });
    try {
      if (_isIOS) {
        await EncryptionService.instance.backupToICloud(uid);
        setState(() => _status =
            'Backed up. iCloud Keychain will sync this to your other devices.');
      } else if (_isAndroid) {
        final email = await CloudBackupService.instance.backup(uid);
        setState(() => _status = 'Backed up to Google Drive ($email).');
      }
      await _refresh();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('StateError: ', ''));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
            child: PgHeader(
                title: 'Privacy & encryption', onBack: () => context.pop()),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        Icon(Icons.lock_outline_rounded,
                            size: 20, color: c.teal),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Your journal entries are end-to-end encrypted. The encryption key lives only on your device — Supabase, and anyone with database access, only ever sees ciphertext. Prayer requests are stored as plain text (protected by row-level access rules) so you can choose to share them with your prayer companion.",
                            style: TextStyle(
                                fontSize: 13.5, height: 1.6, color: c.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text('CLOUD BACKUP',
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isIOS
                                  ? Icons.cloud_outlined
                                  : Icons.cloud_outlined,
                              size: 18,
                              color: c.teal,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isIOS
                                  ? 'Back up to iCloud'
                                  : (_isAndroid
                                      ? 'Back up to Google Drive'
                                      : 'Cloud backup'),
                              style: const TextStyle(
                                  fontSize: 14.5, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isIOS
                              ? "Without this, a new device or a reinstall can't decrypt entries you've already written — nobody can, not even you. Back up your key to iCloud Keychain so it's ready on your other devices automatically."
                              : _isAndroid
                                  ? "Without this, a new device or a reinstall can't decrypt entries you've already written — nobody can, not even you. Back up your key to your Google account's private app storage."
                                  : "Cloud backup is available on iOS (iCloud) and Android (Google Drive).",
                          style: TextStyle(
                              fontSize: 13, height: 1.55, color: c.dim),
                        ),
                        if (_isIOS && _isBackedUp == true) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded,
                                  size: 16, color: c.teal),
                              const SizedBox(width: 6),
                              Text('Backed up to iCloud',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: c.teal)),
                            ],
                          ),
                        ],
                        if (_status != null) ...[
                          const SizedBox(height: 10),
                          Text(_status!,
                              style: TextStyle(
                                  fontSize: 13, color: c.teal, height: 1.5)),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(_error!,
                              style: TextStyle(
                                  fontSize: 13, color: c.danger, height: 1.5)),
                        ],
                        if (_isIOS || _isAndroid) ...[
                          const SizedBox(height: 14),
                          PgButton(
                            label: _working ? 'Backing up…' : 'Back up now',
                            variant: PgButtonVariant.outline,
                            onPressed: _working ? null : _backup,
                          ),
                          if (_isAndroid &&
                              !CloudBackupService.instance.isConfigured) ...[
                            const SizedBox(height: 10),
                            Text(
                              "Google Drive backup isn't configured for this build yet (needs GOOGLE_OAUTH_CLIENT_ID) — see SETUP.md.",
                              style: TextStyle(
                                  fontSize: 12, color: c.faint, height: 1.5),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('LEGAL',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: c.dim)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                        color: c.surface,
                        border: Border.all(color: c.line),
                        borderRadius: BorderRadius.circular(18)),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: [
                        _LegalLinkRow(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Privacy Policy',
                          onTap: () => context.push('/privacy-policy'),
                          showBorder: true,
                        ),
                        _LegalLinkRow(
                          icon: Icons.description_outlined,
                          label: 'Terms of Use',
                          onTap: () => context.push('/terms-of-use'),
                          showBorder: false,
                        ),
                      ],
                    ),
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

class _LegalLinkRow extends StatelessWidget {
  const _LegalLinkRow(
      {required this.icon,
      required this.label,
      required this.onTap,
      required this.showBorder});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
            border:
                showBorder ? Border(bottom: BorderSide(color: c.line)) : null),
        child: Row(
          children: [
            Icon(icon, size: 19, color: c.teal),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600))),
            Icon(Icons.chevron_right_rounded, size: 17, color: c.faint),
          ],
        ),
      ),
    );
  }
}
