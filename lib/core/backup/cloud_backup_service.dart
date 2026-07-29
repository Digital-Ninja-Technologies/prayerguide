import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../security/encryption_service.dart';

/// Backs the encryption key up to (and restores it from) the signed-in
/// Google account's app-private Drive folder (`appDataFolder` — invisible in
/// the user's regular Drive, only this app can read/write it). This is the
/// Android equivalent of [EncryptionService.backupToICloud]: iOS gets real
/// OS-level Keychain sync for free, Android has no equivalent for
/// Keystore-protected secrets, so this does the same job by hand.
///
/// Requires a Google OAuth client id (`GOOGLE_OAUTH_CLIENT_ID` in `.env`) —
/// see SETUP.md. Without one, [isConfigured] is false and every method here
/// throws a clear [StateError] instead of failing mysteriously.
class CloudBackupService {
  CloudBackupService._();
  static final instance = CloudBackupService._();

  static const _scopes = ['https://www.googleapis.com/auth/drive.appdata'];
  static const _fileName = 'prayerguide_key.json';

  final GoogleSignIn _signIn = GoogleSignIn.instance;
  bool _initialized = false;

  bool get isConfigured => (dotenv.env['GOOGLE_OAUTH_CLIENT_ID'] ?? '').isNotEmpty;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    if (!isConfigured) {
      throw StateError(
        'Google Drive backup needs GOOGLE_OAUTH_CLIENT_ID set in .env — see SETUP.md.',
      );
    }
    // Android (no google-services.json in this project) needs the *web*
    // application's client id passed as serverClientId, not clientId — see
    // the google_sign_in_android package docs.
    await _signIn.initialize(serverClientId: dotenv.env['GOOGLE_OAUTH_CLIENT_ID']);
    _initialized = true;
  }

  Future<GoogleSignInAccount> _signedInAccount() async {
    await _ensureInitialized();
    return _signIn.authenticate();
  }

  Future<Map<String, String>> _authHeaders(GoogleSignInAccount account) async {
    final authorization = await account.authorizationClient.authorizeScopes(_scopes);
    return {'Authorization': 'Bearer ${authorization.accessToken}'};
  }

  Future<String?> _findFileId(Map<String, String> headers) async {
    final uri = Uri.parse(
      'https://www.googleapis.com/drive/v3/files'
      "?spaces=appDataFolder&q=name='$_fileName'&fields=files(id)",
    );
    final res = await http.get(uri, headers: headers);
    if (res.statusCode != 200) throw StateError('Drive lookup failed: ${res.statusCode} ${res.body}');
    final files = (jsonDecode(res.body)['files'] as List?) ?? const [];
    return files.isEmpty ? null : files.first['id'] as String;
  }

  /// Uploads this device's current key to Drive, creating or overwriting the
  /// backup file, returning the signed-in account's email for display.
  Future<String> backup(String uid) async {
    final key = await EncryptionService.instance.exportLocalKeyBase64(uid);
    if (key == null) throw StateError('This device has no key to back up yet.');

    final account = await _signedInAccount();
    final headers = await _authHeaders(account);
    final existingId = await _findFileId(headers);
    final payload = jsonEncode({'uid': uid, 'key': key});

    final uri = existingId == null
        ? Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart')
        : Uri.parse('https://www.googleapis.com/upload/drive/v3/files/$existingId?uploadType=multipart');
    final request = http.MultipartRequest(existingId == null ? 'POST' : 'PATCH', uri)
      ..headers.addAll(headers)
      ..files.add(http.MultipartFile.fromString(
        'metadata',
        jsonEncode(existingId == null
            ? {'name': _fileName, 'parents': ['appDataFolder']}
            : {'name': _fileName}),
        contentType: MediaType('application', 'json'),
      ))
      ..files.add(http.MultipartFile.fromString('file', payload, contentType: MediaType('application', 'json')));

    final streamed = await request.send();
    if (streamed.statusCode >= 300) {
      throw StateError('Drive upload failed: ${streamed.statusCode}');
    }
    return account.email;
  }

  /// Downloads the backed-up key from Drive and imports it as this device's
  /// local key. Returns the signed-in account's email for display.
  Future<String> restore(String uid) async {
    final account = await _signedInAccount();
    final headers = await _authHeaders(account);
    final fileId = await _findFileId(headers);
    if (fileId == null) throw StateError('No backup found in this Google account.');

    final res = await http.get(
      Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId?alt=media'),
      headers: headers,
    );
    if (res.statusCode != 200) throw StateError('Drive download failed: ${res.statusCode}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['uid'] != uid) {
      throw StateError('That Google account\'s backup belongs to a different Prayer Guide account.');
    }
    await EncryptionService.instance.importKeyBase64(uid, data['key'] as String);
    return account.email;
  }

  Future<bool> hasBackup(String uid) async {
    final account = await _signedInAccount();
    final headers = await _authHeaders(account);
    return await _findFileId(headers) != null;
  }
}
