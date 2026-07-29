import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../supabase/supabase_config.dart';

/// Thrown by [EncryptionService.encrypt]/[decrypt] when this device has no
/// local copy of the user's key, but this account clearly has existing
/// encrypted journal entries elsewhere — i.e. this looks like a new
/// device/reinstall. Callers should offer cloud restore (iCloud on iOS,
/// Google Drive on Android — see [PgCloudRestoreUnlock]) rather than
/// silently generating a new, unrelated key.
class CloudRestoreRequiredException implements Exception {
  const CloudRestoreRequiredException();
}

/// Client-side (true end-to-end) encryption for journal entries.
///
/// The data-encryption key (DEK) is a random AES-256 key generated on first
/// use and cached in the platform keychain/keystore via
/// [FlutterSecureStorage] — Supabase only ever sees ciphertext.
///
/// Backup (opt-in, replaces the old passphrase/escrow scheme):
/// - **iOS**: [backupToICloud] re-saves the DEK into a Keychain item marked
///   `kSecAttrSynchronizable`, so iOS's own iCloud Keychain sync carries it
///   to the user's other devices automatically (as long as they have iCloud
///   Keychain turned on) — Apple handles the transport, this app never sees
///   or sends the key anywhere itself.
/// - **Android**: real iCloud-equivalent OS sync doesn't exist for
///   Keystore-protected secrets (they're intentionally non-exportable), so
///   backup there goes through [CloudBackupService], which uploads the DEK
///   to the signed-in Google account's app-private Drive folder.
///
/// Supabase never sees the DEK either way.
class EncryptionService {
  EncryptionService._();
  static final instance = EncryptionService._();

  final _storage = const FlutterSecureStorage();
  final _iCloudStorage = const FlutterSecureStorage(iOptions: IOSOptions(synchronizable: true));
  final _algorithm = AesGcm.with256bits();
  final Map<String, SecretKey> _cache = {};

  String _storageKey(String uid) => 'pg_e2e_key_$uid';

  Future<SecretKey?> _localKey(String uid) async {
    final cached = _cache[uid];
    if (cached != null) return cached;

    final existing = await _storage.read(key: _storageKey(uid));
    if (existing != null) {
      final key = SecretKey(base64Decode(existing));
      _cache[uid] = key;
      return key;
    }

    // Nothing in the plain (non-synced) slot — check whether iOS iCloud
    // Keychain has already delivered a synced copy from another device.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final synced = await _iCloudStorage.read(key: _storageKey(uid));
      if (synced != null) {
        final key = SecretKey(base64Decode(synced));
        await _storage.write(key: _storageKey(uid), value: synced);
        _cache[uid] = key;
        return key;
      }
    }
    return null;
  }

  Future<void> _saveLocalKey(String uid, SecretKey key) async {
    final bytes = await key.extractBytes();
    await _storage.write(key: _storageKey(uid), value: base64Encode(bytes));
    _cache[uid] = key;
  }

  /// Whether this account has any journal entries already — used to tell a
  /// genuinely brand-new user (safe to silently generate a key) apart from
  /// an existing user opening the app on a device with no local key (needs
  /// cloud restore instead).
  Future<bool> _hasExistingEncryptedData(String uid) async {
    final rows = await supa.from('journal_entries').select('id').eq('user_id', uid).limit(1);
    return (rows as List).isNotEmpty;
  }

  /// Resolves the key to use for [uid]: the cached/local one if present,
  /// otherwise a brand-new one *unless* this account already has encrypted
  /// journal entries (meaning this is a new device for existing encrypted
  /// data), in which case it throws [CloudRestoreRequiredException] instead
  /// of silently diverging from the user's real key.
  Future<SecretKey> _keyFor(String uid) async {
    final local = await _localKey(uid);
    if (local != null) return local;

    if (await _hasExistingEncryptedData(uid)) throw const CloudRestoreRequiredException();

    final newKey = await _algorithm.newSecretKey();
    await _saveLocalKey(uid, newKey);
    return newKey;
  }

  /// Whether this device currently holds a usable local key.
  Future<bool> isUnlockedOnThisDevice(String uid) async => await _localKey(uid) != null;

  /// iOS only: re-saves this device's current key (generating one first if
  /// this device doesn't have one yet) into the iCloud-synced Keychain slot.
  Future<void> backupToICloud(String uid) async {
    var key = await _localKey(uid);
    key ??= await _keyFor(uid);
    final bytes = await key.extractBytes();
    await _iCloudStorage.write(key: _storageKey(uid), value: base64Encode(bytes));
  }

  /// iOS only: whether this key is currently in the iCloud-synced slot.
  Future<bool> isBackedUpToICloud(String uid) async {
    final synced = await _iCloudStorage.read(key: _storageKey(uid));
    return synced != null;
  }

  /// Exports this device's local key (base64) for [CloudBackupService] to
  /// upload — null if this device has no local key yet.
  Future<String?> exportLocalKeyBase64(String uid) async {
    final key = await _localKey(uid);
    if (key == null) return null;
    final bytes = await key.extractBytes();
    return base64Encode(bytes);
  }

  /// Imports a key fetched by [CloudBackupService] (e.g. from Google Drive)
  /// and makes it this device's local key.
  Future<void> importKeyBase64(String uid, String base64Key) async {
    await _saveLocalKey(uid, SecretKey(base64Decode(base64Key)));
  }

  /// Explicitly starts fresh on this device with a brand-new key, abandoning
  /// any previously-backed-up key (old entries encrypted under the old key
  /// will show as undecryptable). Only call this after the user has
  /// confirmed they don't have — or don't want — a cloud backup.
  Future<void> startFreshOnThisDevice(String uid) async {
    final newKey = await _algorithm.newSecretKey();
    await _saveLocalKey(uid, newKey);
  }

  /// Encrypts [plaintext] for user [uid]. Returns a base64 string packing
  /// nonce + ciphertext + MAC — safe to store directly in a `text` column.
  /// Throws [CloudRestoreRequiredException] if this device needs restoring
  /// first (see [_keyFor]).
  Future<String> encrypt(String uid, String plaintext) async {
    final key = await _keyFor(uid);
    final nonce = _algorithm.newNonce();
    final box = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );
    final packed = Uint8List.fromList([...box.nonce, ...box.cipherText, ...box.mac.bytes]);
    return base64Encode(packed);
  }

  /// Decrypts a string produced by [encrypt]. Returns null if it can't be
  /// decrypted (wrong/missing key, e.g. after a reinstall with no backup
  /// restored) so callers can show a placeholder instead of crashing.
  /// Throws [CloudRestoreRequiredException] if this device needs restoring.
  Future<String?> decrypt(String uid, String encoded) async {
    final key = await _keyFor(uid); // may throw CloudRestoreRequiredException
    try {
      final packed = base64Decode(encoded);
      const nonceLength = 12;
      const macLength = 16;
      final nonce = packed.sublist(0, nonceLength);
      final mac = packed.sublist(packed.length - macLength);
      final cipherText = packed.sublist(nonceLength, packed.length - macLength);
      final clear = await _algorithm.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: key,
      );
      return utf8.decode(clear);
    } catch (_) {
      return null;
    }
  }
}
