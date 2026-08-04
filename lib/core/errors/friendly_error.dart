import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns a caught exception into something a user could actually read —
/// never a raw `AuthApiException(message: ..., statusCode: ..., code: ...)`
/// or `PostgrestException` dump. Falls back to a calm, generic message for
/// anything unrecognized rather than leaking internals.
String friendlyErrorMessage(Object error) {
  if (error is AuthException) return _authMessage(error);
  if (error is PostgrestException) return _postgrestMessage(error);
  if (error is SocketException || error is TimeoutException) {
    return "You appear to be offline. Check your connection and try again.";
  }
  return "Something went wrong. Please try again.";
}

String _authMessage(AuthException e) {
  final code = e.code;
  switch (code) {
    case 'invalid_credentials':
      return "That email or password isn't right.";
    case 'user_already_exists':
    case 'user_already_registered':
      return "An account with that email already exists — try signing in instead.";
    case 'email_not_confirmed':
      return "Please confirm your email before signing in — check your inbox.";
    case 'weak_password':
      return "That password is too weak — use at least 8 characters.";
    case 'over_request_rate_limit':
    case 'over_email_send_rate_limit':
      return "Too many attempts — please wait a bit and try again.";
    case 'same_password':
      return "That's your current password — choose a different one.";
  }
  final msg = e.message.toLowerCase();
  if (msg.contains('invalid login credentials')) {
    return "That email or password isn't right.";
  }
  if (msg.contains('email not confirmed')) {
    return "Please confirm your email before signing in — check your inbox.";
  }
  if (msg.contains('already registered') || msg.contains('already exists')) {
    return "An account with that email already exists — try signing in instead.";
  }
  if (msg.contains('password') && msg.contains('least')) {
    return "That password is too weak — use at least 8 characters.";
  }
  if (msg.contains('rate limit')) {
    return "Too many attempts — please wait a bit and try again.";
  }
  return "Something went wrong signing you in. Please try again.";
}

String _postgrestMessage(PostgrestException e) {
  if (e.code == '23505') return "That already exists.";
  return "Something went wrong loading your data. Please try again.";
}
