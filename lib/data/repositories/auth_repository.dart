import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';

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

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) {
    return _auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
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

  /// Requires the Apple provider to be configured in the Supabase dashboard,
  /// its redirect URL added to the dashboard's allowed Redirect URLs (see
  /// [signInWithGoogle]), and the Sign in with Apple capability enabled on
  /// the iOS target.
  Future<bool> signInWithApple() {
    return _auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: _oauthRedirect,
      authScreenLaunchMode: _oauthLaunchMode,
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
