import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../supabase/supabase_config.dart';

/// Thrown by [EncryptionService.encrypt]/[decrypt] when this device has no
/// local copy of the user's key, but the server has a passphrase-wrapped
/// escrow copy — i.e. this looks like a new device/reinstall for an
/// existing encrypted-data user. Callers should prompt for the recovery
/// passphrase (via [EncryptionService.unlockWithPassphrase]) rather than
/// silently generating a new, unrelated key.
class PassphraseRequiredException implements Exception {
  const PassphraseRequiredException();
}

/// Thrown by [EncryptionService.unlockWithPassphrase] when the passphrase
/// doesn't unwrap the stored key (wrong passphrase).
class WrongPassphraseException implements Exception {
  const WrongPassphraseException();
}

/// Client-side (true end-to-end) encryption for journal entries and prayer
/// request text.
///
/// The data-encryption key (DEK) is a random AES-256 key generated on
/// first use and cached in the platform keychain/keystore via
/// [FlutterSecureStorage] — Supabase only ever sees ciphertext.
///
/// Recovery (opt-in): a user can set a recovery passphrase
/// ([setupRecovery]). That wraps the *same* DEK with a passphrase-derived
/// key (PBKDF2-HMAC-SHA256, random salt) and stores the wrapped copy in the
/// `encryption_keys` table. Supabase still never sees the DEK or the
/// passphrase — only someone who knows the passphrase can unwrap it
/// ([unlockWithPassphrase]). Without a recovery passphrase set up before a
/// reinstall/new device, old entries are unrecoverable by design — the
/// escrow is the trade-off a user can choose to accept for convenience.
class EncryptionService {
  EncryptionService._();
  static final instance = EncryptionService._();

  final _storage = const FlutterSecureStorage();
  final _algorithm = AesGcm.with256bits();
  final _kdf = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 200000, bits: 256);
  final Map<String, SecretKey> _cache = {};

  String _storageKey(String uid) => 'pg_e2e_key_$uid';

  Future<SecretKey?> _localKey(String uid) async {
    final cached = _cache[uid];
    if (cached != null) return cached;
    final existing = await _storage.read(key: _storageKey(uid));
    if (existing == null) return null;
    final key = SecretKey(base64Decode(existing));
    _cache[uid] = key;
    return key;
  }

  Future<void> _saveLocalKey(String uid, SecretKey key) async {
    final bytes = await key.extractBytes();
    await _storage.write(key: _storageKey(uid), value: base64Encode(bytes));
    _cache[uid] = key;
  }

  Future<Map<String, dynamic>?> _fetchEscrow(String uid) {
    return supa.from('encryption_keys').select().eq('user_id', uid).maybeSingle();
  }

  /// Resolves the key to use for [uid]: the cached/local one if present,
  /// otherwise a brand-new one *unless* the server has an escrowed key
  /// (meaning this is a new device for existing encrypted data), in which
  /// case it throws [PassphraseRequiredException] instead of silently
  /// diverging from the user's real key.
  Future<SecretKey> _keyFor(String uid) async {
    final local = await _localKey(uid);
    if (local != null) return local;

    final escrow = await _fetchEscrow(uid);
    if (escrow != null) throw const PassphraseRequiredException();

    final newKey = await _algorithm.newSecretKey();
    await _saveLocalKey(uid, newKey);
    return newKey;
  }

  /// True once this user has set up a recovery passphrase (server has an
  /// escrowed key), regardless of whether *this* device has unlocked it yet.
  Future<bool> hasRecoverySetUp(String uid) async => await _fetchEscrow(uid) != null;

  /// Whether this device currently holds a usable local key.
  Future<bool> isUnlockedOnThisDevice(String uid) async => await _localKey(uid) != null;

  /// Sets up (or replaces) the recovery passphrase, wrapping this device's
  /// current key — generating one first if this device doesn't have one yet.
  Future<void> setupRecovery(String uid, String passphrase) async {
    var key = await _localKey(uid);
    key ??= await _keyFor(uid); // generates fresh if brand new, throws if escrow exists elsewhere

    final salt = _randomBytes(16);
    final wrappingKey = await _kdf.deriveKeyFromPassword(password: passphrase, nonce: salt);
    final dekBytes = await key.extractBytes();
    final nonce = _algorithm.newNonce();
    final box = await _algorithm.encrypt(dekBytes, secretKey: wrappingKey, nonce: nonce);
    final wrapped = base64Encode(Uint8List.fromList([...box.nonce, ...box.cipherText, ...box.mac.bytes]));

    await supa.from('encryption_keys').upsert({
      'user_id': uid,
      'wrapped_key': wrapped,
      'salt': base64Encode(salt),
      'iterations': 200000,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Unwraps the escrowed key with [passphrase] and caches it as this
  /// device's local key. Throws [WrongPassphraseException] if it doesn't
  /// unwrap, or [StateError] if no recovery was ever set up.
  Future<void> unlockWithPassphrase(String uid, String passphrase) async {
    final escrow = await _fetchEscrow(uid);
    if (escrow == null) throw StateError('No recovery passphrase has been set up for this account.');

    final salt = base64Decode(escrow['salt'] as String);
    final iterations = escrow['iterations'] as int;
    final kdf = iterations == 200000
        ? _kdf
        : Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256);
    final wrappingKey = await kdf.deriveKeyFromPassword(password: passphrase, nonce: salt);

    final packed = base64Decode(escrow['wrapped_key'] as String);
    const nonceLength = 12;
    const macLength = 16;
    final nonce = packed.sublist(0, nonceLength);
    final mac = packed.sublist(packed.length - macLength);
    final cipherText = packed.sublist(nonceLength, packed.length - macLength);

    try {
      final dekBytes = await _algorithm.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: wrappingKey,
      );
      await _saveLocalKey(uid, SecretKey(dekBytes));
    } catch (_) {
      throw const WrongPassphraseException();
    }
  }

  /// Explicitly starts fresh on this device with a brand-new key, abandoning
  /// any escrowed key (old entries encrypted under the old key will show as
  /// undecryptable). Only call this after the user has confirmed they don't
  /// have — or don't want — their recovery passphrase.
  Future<void> startFreshOnThisDevice(String uid) async {
    final newKey = await _algorithm.newSecretKey();
    await _saveLocalKey(uid, newKey);
  }

  Uint8List _randomBytes(int length) {
    final rand = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rand.nextInt(256)));
  }

  /// Encrypts [plaintext] for user [uid]. Returns a base64 string packing
  /// nonce + ciphertext + MAC — safe to store directly in a `text` column.
  /// Throws [PassphraseRequiredException] if this device needs unlocking
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
  /// decrypted (wrong/missing key, e.g. after a reinstall with no recovery
  /// set up) so callers can show a placeholder instead of crashing.
  /// Throws [PassphraseRequiredException] if this device needs unlocking.
  Future<String?> decrypt(String uid, String encoded) async {
    final key = await _keyFor(uid); // may throw PassphraseRequiredException
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
