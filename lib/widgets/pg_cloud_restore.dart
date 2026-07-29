import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/backup/cloud_backup_service.dart';
import '../core/security/encryption_service.dart';
import '../core/theme/pg_colors.dart';
import '../core/theme/pg_text.dart';
import 'pg_button.dart';

/// Shown instead of a list (Journal) when this device holds no local copy
/// of the user's encryption key but the account clearly has existing
/// encrypted entries — i.e. this looks like a new device or a reinstall.
/// Offers a platform-appropriate cloud restore (iCloud Keychain sync on
/// iOS, Google Drive on Android), or explicitly starting fresh.
class PgCloudRestoreUnlock extends StatefulWidget {
  const PgCloudRestoreUnlock({super.key, required this.uid, required this.onUnlocked});

  final String uid;
  final VoidCallback onUnlocked;

  @override
  State<PgCloudRestoreUnlock> createState() => _PgCloudRestoreUnlockState();
}

class _PgCloudRestoreUnlockState extends State<PgCloudRestoreUnlock> {
  bool _loading = false;
  String? _error;
  bool _confirmingStartFresh = false;

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _checkICloud() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final unlocked = await EncryptionService.instance.isUnlockedOnThisDevice(widget.uid);
      if (unlocked) {
        widget.onUnlocked();
      } else {
        setState(() => _error =
            "No iCloud backup found yet. Make sure iCloud Keychain is on in this device's Settings, and that you backed up from your other device.");
      }
    } catch (e) {
      setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restoreFromGoogleDrive() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await CloudBackupService.instance.restore(widget.uid);
      widget.onUnlocked();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('StateError: ', ''));
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
            decoration: BoxDecoration(color: c.tealSoft, borderRadius: BorderRadius.circular(18)),
            child: Icon(Icons.lock_outline_rounded, size: 28, color: c.teal),
          ),
          const SizedBox(height: 16),
          Text('This device is locked', style: PgText.serif(size: 21, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            _isIOS
                ? "Your entries are end-to-end encrypted and this looks like a new device. If you backed up to iCloud, turning on iCloud Keychain here should unlock them automatically."
                : "Your entries are end-to-end encrypted and this looks like a new device. Restore your key from Google Drive to unlock them here.",
            style: TextStyle(fontSize: 14, height: 1.6, color: c.dim),
          ),
          const SizedBox(height: 18),
          if (_error != null) ...[
            Text(_error!, style: TextStyle(fontSize: 13, color: c.danger, height: 1.5)),
            const SizedBox(height: 14),
          ],
          if (_isIOS)
            PgButton(
              label: _loading ? 'Checking…' : "I've turned on iCloud Keychain",
              onPressed: _loading ? null : _checkICloud,
            )
          else if (_isAndroid)
            PgButton(
              label: _loading ? 'Restoring…' : 'Restore from Google Drive',
              onPressed: _loading ? null : _restoreFromGoogleDrive,
            )
          else
            PgButton(label: 'Retry', onPressed: _loading ? null : _checkICloud),
          const SizedBox(height: 18),
          if (!_confirmingStartFresh)
            TextButton(
              onPressed: () => setState(() => _confirmingStartFresh = true),
              child: Text("I don't have a backup",
                  style: TextStyle(color: c.faint, fontSize: 13, fontWeight: FontWeight.w600)),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration:
                  BoxDecoration(color: c.surface, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Starting fresh means entries encrypted before today will stay unreadable on this device, permanently — nobody can recover them without a backup.",
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
