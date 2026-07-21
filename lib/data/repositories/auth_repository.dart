import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';

/// Deep link Supabase redirects back to after a Google/Apple OAuth flow.
/// Must be registered as a URL scheme on both platforms (see
/// android/app/src/main/AndroidManifest.xml and ios/Runner/Info.plist) and
/// added to Supabase Dashboard → Authentication → URL Configuration →
/// Redirect URLs.
const kOAuthRedirect = 'io.supabase.prayerguide://login-callback/';

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

  Future<void> sendPasswordReset(String email) {
    return _auth.resetPasswordForEmail(email);
  }

  /// Requires the Google provider to be configured in the Supabase dashboard
  /// (Authentication → Providers → Google) with your OAuth client id/secret,
  /// and `kOAuthRedirect` added to the dashboard's allowed Redirect URLs.
  Future<bool> signInWithGoogle() {
    return _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kOAuthRedirect,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  /// Requires the Apple provider to be configured in the Supabase dashboard,
  /// `kOAuthRedirect` added to its allowed Redirect URLs, and the Sign in
  /// with Apple capability enabled on the iOS target.
  Future<bool> signInWithApple() {
    return _auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: kOAuthRedirect,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() => _auth.signOut();
}
