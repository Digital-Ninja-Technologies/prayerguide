import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_config.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/journal_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/requests_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());
final journalRepositoryProvider = Provider((ref) => JournalRepository());
final requestsRepositoryProvider = Provider((ref) => RequestsRepository());
final profileRepositoryProvider = Provider((ref) => ProfileRepository());

/// Emits whenever Supabase auth state changes (sign in / out / token refresh).
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).onAuthStateChange;
});

/// The current signed-in user id, or null when signed out. Screens should
/// watch this (not `Supabase.instance.client.auth.currentUser` directly) so
/// they rebuild on sign-in/out.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.maybeWhen(
    data: (s) => s.session?.user.id,
    orElse: () => supa.auth.currentUser?.id,
  );
});
