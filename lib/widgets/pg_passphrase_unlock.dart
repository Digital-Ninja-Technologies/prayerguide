import 'package:flutter/material.dart';

import '../core/security/encryption_service.dart';
import '../core/theme/pg_colors.dart';
import '../core/theme/pg_text.dart';
import 'pg_button.dart';
import 'pg_text_field.dart';

/// Shown instead of a list (Journal, Requests) when this device holds no
/// local copy of the user's encryption key but the account has a recovery
/// passphrase escrowed server-side — i.e. this looks like a new device or a
/// reinstall. Lets the user unlock with their passphrase, or explicitly
/// start fresh (abandoning the old, now-unreadable entries on this device).
class PgPassphraseUnlock extends StatefulWidget {
  const PgPassphraseUnlock(
      {super.key, required this.uid, required this.onUnlocked});

  final String uid;
  final VoidCallback onUnlocked;

  @override
  State<PgPassphraseUnlock> createState() => _PgPassphraseUnlockState();
}

class _PgPassphraseUnlockState extends State<PgPassphraseUnlock> {
  final _passphrase = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _confirmingStartFresh = false;

  Future<void> _unlock() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await EncryptionService.instance
          .unlockWithPassphrase(widget.uid, _passphrase.text);
      widget.onUnlocked();
    } on WrongPassphraseException {
      setState(() => _error = "That passphrase doesn't match.");
    } catch (e) {
      setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startFresh() async {
    setState(() => _loading = true);
    await EncryptionService.instance.startFreshOnThisDevice(widget.uid);
    widget.onUnlocked();
  }

  @override
  void dispose() {
    _passphrase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: c.tealSoft, borderRadius: BorderRadius.circular(18)),
            child: Icon(Icons.lock_outline_rounded, size: 28, color: c.teal),
          ),
          const SizedBox(height: 16),
          Text('This device is locked',
              style: PgText.serif(size: 21, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            "Your entries are end-to-end encrypted and this looks like a new device. Enter your recovery passphrase to unlock them here.",
            style: TextStyle(fontSize: 14, height: 1.6, color: c.dim),
          ),
          const SizedBox(height: 18),
          PgTextField(
            controller: _passphrase,
            hint: 'Recovery passphrase',
            obscureText: true,
            errorText: _error,
          ),
          const SizedBox(height: 14),
          PgButton(
              label: _loading ? 'Unlocking…' : 'Unlock',
              onPressed: _loading ? null : _unlock),
          const SizedBox(height: 18),
          if (!_confirmingStartFresh)
            TextButton(
              onPressed: () => setState(() => _confirmingStartFresh = true),
              child: Text("I don't have my passphrase",
                  style: TextStyle(
                      color: c.faint,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Starting fresh means entries encrypted before today will stay unreadable on this device, permanently — nobody can recover them without the passphrase.",
                    style: TextStyle(fontSize: 13, height: 1.5, color: c.dim),
                  ),
                  const SizedBox(height: 12),
                  PgButton(
                    label: _loading ? 'Working…' : 'Start fresh on this device',
                    variant: PgButtonVariant.danger,
                    onPressed: _loading ? null : _startFresh,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
