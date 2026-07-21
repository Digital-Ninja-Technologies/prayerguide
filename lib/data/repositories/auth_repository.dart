import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';

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
  /// (Authentication → Providers → Google) with your OAuth client id/secret.
  Future<bool> signInWithGoogle() {
    return _auth.signInWithOAuth(OAuthProvider.google);
  }

  /// Requires the Apple provider to be configured in the Supabase dashboard
  /// and a Sign in with Apple capability/entitlement on the iOS build.
  Future<bool> signInWithApple() {
    return _auth.signInWithOAuth(OAuthProvider.apple);
  }

  Future<void> signOut() => _auth.signOut();
}
