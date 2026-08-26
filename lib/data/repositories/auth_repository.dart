import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';

const _nonceCharset =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';

/// A random string passed through Apple's native sign-in and echoed back
/// (hashed) inside the identity token, so Supabase can confirm the token
/// it's verifying was minted for this exact sign-in attempt.
String _generateNonce([int length = 32]) {
  final random = Random.secure();
  return List.generate(
      length, (_) => _nonceCharset[random.nextInt(_nonceCharset.length)])
      .join();
}

/// Deep link Supabase redirects back to after a Google/Apple OAuth flow on
/// iOS/Android. Must be registered as a URL scheme on both platforms (see
/// android/app/src/main/AndroidManifest.xml and ios/Runner/Info.plist) and
/// added to Supabase Dashboard → Authentication → URL Configuration →
/// Redirect URLs. Not used on web — see [_oauthRedirect].
const kOAuthRedirect = 'io.supabase.prayerguide://login-callback/';

/// The custom `io.supabase.prayerguide://` scheme only means anything to a
/// native OS, which knows to hand that URL back to this app — a browser tab
/// has nowhere to send it, so the OAuth popup would complete but never
/// return control to the running web app. On web, redirect back to the
/// page's own origin instead (also needs to be added to Supabase's allowed
/// Redirect URLs, e.g. `http://localhost:PORT` for local dev).
String? get _oauthRedirect => kIsWeb ? Uri.base.origin : kOAuthRedirect;

/// On iOS/Android, `signInWithOAuth`'s default launch mode
/// (`LaunchMode.platformDefault`) opens the provider's login page in an
/// in-app browser sheet (SFSafariViewController on iOS) — when that page
/// redirects to our custom `io.supabase.prayerguide://` scheme, the OS hands
/// the link to this app, but the sheet itself has no reason to know it
/// should dismiss, so it just sits there until the user taps its own
/// "Done"/close button, even though sign-in already succeeded underneath.
/// `LaunchMode.externalApplication` opens the system Safari app instead —
/// when *that* gets redirected to our scheme, iOS switches directly back to
/// this app with no leftover sheet to dismiss. On web there's no such
/// sheet, so the default is fine there.
LaunchMode get _oauthLaunchMode =>
    kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication;

class AuthRepository {
  GoTrueClient get _auth => supa.auth;

  User? get currentUser => _auth.currentUser;
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  /// [username] is inserted into `profiles` by `handle_new_user()` in the
  /// same transaction as the `auth.users` row — if it's already taken, the
  /// whole signUp() call fails (no orphan account is left behind) and the
  /// caller should let the user pick another one.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String username,
  }) {
    return _auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'username': username},
    );
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  /// Sends a reset-password email whose link redirects back into the app
  /// (native) or the current page (web) with a recovery session — the app
  /// picks that up via [onAuthStateChange]'s `AuthChangeEvent.passwordRecovery`
  /// and routes to the "set a new password" screen.
  Future<void> sendPasswordReset(String email) {
    return _auth.resetPasswordForEmail(email, redirectTo: _oauthRedirect);
  }

  /// Sets a new password for the current session — used once a
  /// `AuthChangeEvent.passwordRecovery` has put the user in a recovery
  /// session (see [sendPasswordReset]).
  Future<void> updatePassword(String newPassword) {
    return _auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Requires the Google provider to be configured in the Supabase dashboard
  /// (Authentication → Providers → Google) with your OAuth client id/secret,
  /// and the redirect URL added to the dashboard's allowed Redirect URLs —
  /// `kOAuthRedirect` for native, the web app's own origin for web.
  Future<bool> signInWithGoogle() {
    return _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _oauthRedirect,
      authScreenLaunchMode: _oauthLaunchMode,
    );
  }

  /// Native "Sign in with Apple" (AuthenticationServices), offered as the
  /// equivalent login option App Store guideline 4.8 requires wherever a
  /// third-party login (Google, here) is offered. This deliberately does
  /// *not* go through [signInWithGoogle]'s `signInWithOAuth` browser flow —
  /// App Review does not recognize a generic OAuth redirect through Apple's
  /// web endpoint as a compliant "Sign in with Apple"; it must be the native
  /// system sheet, which is what `sign_in_with_apple` drives.
  ///
  /// Requires the "Sign in with Apple" capability enabled on the iOS App ID
  /// (Apple Developer portal) — mirrored locally by the
  /// `com.apple.developer.applesignin` entitlement in
  /// `ios/Runner/Runner.entitlements` — and the Apple provider configured in
  /// the Supabase dashboard (Authentication → Providers → Apple) with this
  /// app's bundle id as an authorized client id, same as the Google flow's
  /// prerequisite in [signInWithGoogle].
  Future<AuthResponse> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException(
          'Apple sign-in did not return an identity token.');
    }

    return _auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  Future<void> signOut() => _auth.signOut();

  /// Permanently deletes the current user's account and all associated
  /// data via the `delete_own_account` RPC (see migration
  /// 0019_delete_own_account.sql) — irreversible. The server-side row is
  /// gone after the RPC returns, but the local session object doesn't know
  /// that on its own, so sign out explicitly to clear it rather than
  /// leaving the app looking signed-in to an account that no longer exists.
  Future<void> deleteAccount() async {
    await supa.rpc('delete_own_account');
    await _auth.signOut();
  }
}
