import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;

import '../../features/bible/bible_notes_screen.dart';
import '../../features/bible/bible_screen.dart';
import '../../features/challenges/challenge_detail_screen.dart';
import '../../features/challenges/challenge_new_screen.dart';
import '../../features/challenges/challenges_screen.dart';
import '../../features/companion/companion_detail_screen.dart';
import '../../features/companion/companion_list_screen.dart';
import '../../features/companion/invite_screen.dart';
import '../../features/companion/qr_scan_screen.dart';
import '../../features/devotional/devotional_screen.dart';
import '../../features/fasting/fasting_screen.dart';
import '../../features/focus/focus_active_screen.dart';
import '../../features/focus/focus_setup_screen.dart';
import '../../features/groups/group_new_screen.dart';
import '../../features/groups/groups_screen.dart';
import '../../features/guide/guide_library_screen.dart';
import '../../features/guide/guide_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/journal/journal_new_screen.dart';
import '../../features/journal/journal_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/reset_password_confirm_screen.dart';
import '../../features/plans/plan_detail_screen.dart';
import '../../features/plans/plans_screen.dart';
import '../../features/requests/request_new_screen.dart';
import '../../features/requests/requests_screen.dart';
import '../../features/room/room_screen.dart';
import '../../features/scripture/scripture_screen.dart';
import '../../features/sermons/sermon_note_detail_screen.dart';
import '../../features/sermons/sermon_note_new_screen.dart';
import '../../features/sermons/sermon_notes_screen.dart';
import '../../features/settings/insights_screen.dart';
import '../../features/settings/notification_day_times_screen.dart';
import '../../features/settings/notifications_screen.dart';
import '../../features/settings/about_help_screen.dart';
import '../../features/settings/privacy_policy_screen.dart';
import '../../features/settings/privacy_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/terms_of_use_screen.dart';
import '../../features/settings/upgrade_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/streak/streak_screen.dart';
import '../../features/timer/timer_screen.dart';
import '../../features/together/together_screen.dart';
import '../supabase/supabase_config.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Set when Supabase reports a password-recovery session (the user clicked
  // the link in a reset-password email) — consumed once by `redirect` below
  // to force a detour to the "set a new password" screen regardless of
  // where the deep link actually landed.
  var passwordRecovery = false;
  final authSub = supa.auth.onAuthStateChange.listen((state) {
    if (state.event == AuthChangeEvent.passwordRecovery) {
      passwordRecovery = true;
    }
  });
  ref.onDispose(authSub.cancel);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(supa.auth.onAuthStateChange),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (passwordRecovery) {
        passwordRecovery = false;
        if (loc != '/reset-password-confirm') return '/reset-password-confirm';
      }
      final loggedIn = supa.auth.currentUser != null;
      final isAuthFlow = loc == '/splash' ||
          loc == '/onboarding' ||
          loc == '/reset-password-confirm';
      if (!loggedIn && !isAuthFlow) return '/onboarding';
      if (loggedIn && loc == '/onboarding') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(
        path: '/reset-password-confirm',
        builder: (c, s) => const ResetPasswordConfirmScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/bible',
              builder: (c, s) => BibleScreen(
                initialBook: s.uri.queryParameters['book'],
                initialChapter:
                    int.tryParse(s.uri.queryParameters['chapter'] ?? ''),
                planKey: s.uri.queryParameters['planKey'],
                planDay: int.tryParse(s.uri.queryParameters['day'] ?? ''),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/journal', builder: (c, s) => const JournalScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/sermons', builder: (c, s) => const SermonNotesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/settings', builder: (c, s) => const SettingsScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/guide',
        builder: (c, s) =>
            GuideScreen(category: s.uri.queryParameters['category']),
      ),
      GoRoute(
          path: '/guide-library',
          builder: (c, s) => const GuideLibraryScreen()),
      GoRoute(
        path: '/timer',
        builder: (c, s) => TimerScreen(
          category: s.uri.queryParameters['category'],
          presetMinutes: int.tryParse(s.uri.queryParameters['minutes'] ?? ''),
        ),
      ),
      GoRoute(path: '/scripture', builder: (c, s) => const ScriptureScreen()),
      GoRoute(
          path: '/journal/new', builder: (c, s) => const JournalNewScreen()),
      GoRoute(
        path: '/journal/:id',
        builder: (c, s) => JournalEditScreen(entryId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/requests', builder: (c, s) => const RequestsScreen()),
      GoRoute(
          path: '/requests/new', builder: (c, s) => const RequestNewScreen()),
      GoRoute(
          path: '/bible-notes', builder: (c, s) => const BibleNotesScreen()),
      GoRoute(
          path: '/notifications',
          builder: (c, s) => const NotificationsScreen()),
      GoRoute(
        path: '/notifications/times/:kind',
        builder: (c, s) =>
            NotificationDayTimesScreen(kind: s.pathParameters['kind']!),
      ),
      GoRoute(path: '/streak', builder: (c, s) => const StreakScreen()),
      GoRoute(path: '/privacy', builder: (c, s) => const PrivacyScreen()),
      GoRoute(
          path: '/privacy-policy',
          builder: (c, s) => const PrivacyPolicyScreen()),
      GoRoute(
          path: '/terms-of-use', builder: (c, s) => const TermsOfUseScreen()),
      GoRoute(path: '/about', builder: (c, s) => const AboutHelpScreen()),
      GoRoute(path: '/upgrade', builder: (c, s) => const UpgradeScreen()),
      GoRoute(path: '/insights', builder: (c, s) => const InsightsScreen()),
      GoRoute(
          path: '/focus/setup', builder: (c, s) => const FocusSetupScreen()),
      GoRoute(
          path: '/focus/active', builder: (c, s) => const FocusActiveScreen()),
      GoRoute(
          path: '/companion', builder: (c, s) => const CompanionListScreen()),
      GoRoute(
        path: '/companion/invite',
        builder: (c, s) => const InviteScreen(),
      ),
      GoRoute(
        path: '/companion/:id',
        builder: (c, s) =>
            CompanionDetailScreen(companionRowId: s.pathParameters['id']!),
      ),
      GoRoute(
          path: '/companion/invite/scan',
          builder: (c, s) => const QrScanScreen()),
      GoRoute(path: '/challenges', builder: (c, s) => const ChallengesScreen()),
      GoRoute(
        path: '/challenges/new',
        builder: (c, s) => const ChallengeNewScreen(),
      ),
      GoRoute(
        path: '/challenges/:key',
        builder: (c, s) =>
            ChallengeDetailScreen(challengeKey: s.pathParameters['key']!),
      ),
      GoRoute(path: '/plans', builder: (c, s) => const PlansScreen()),
      GoRoute(
        path: '/plans/:key',
        builder: (c, s) => PlanDetailScreen(planKey: s.pathParameters['key']!),
      ),
      GoRoute(path: '/devotional', builder: (c, s) => const DevotionalScreen()),
      GoRoute(path: '/fasting', builder: (c, s) => const FastingScreen()),
      GoRoute(
        path: '/together/:id',
        builder: (c, s) =>
            TogetherScreen(companionRowId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/groups', builder: (c, s) => const GroupsScreen()),
      GoRoute(path: '/groups/new', builder: (c, s) => const GroupNewScreen()),
      GoRoute(
        path: '/room',
        builder: (c, s) =>
            RoomScreen(groupId: s.uri.queryParameters['groupId'] ?? ''),
      ),
      GoRoute(
          path: '/sermons/new', builder: (c, s) => const SermonNoteNewScreen()),
      GoRoute(
        path: '/sermons/:id',
        builder: (c, s) =>
            SermonNoteDetailScreen(noteId: s.pathParameters['id']!),
      ),
    ],
  );
});

/// Pushes [location] unless it's already the current route. go_router
/// derives each page's key from its location, so pushing the same location
/// twice before the first push settles (e.g. a double-tap) puts two pages
/// with an identical key on the Navigator stack and crashes with
/// `!keyReservation.contains(key)`.
extension SafePush on BuildContext {
  void pushOnce(String location) {
    if (GoRouterState.of(this).uri.toString() != location) {
      push(location);
    }
  }
}

/// Bridges a Stream (Supabase auth changes) into a Listenable so go_router
/// can re-run its redirect logic on sign-in/out.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
