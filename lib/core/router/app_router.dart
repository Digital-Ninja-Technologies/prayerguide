import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/assistant/assistant_screen.dart';
import '../../features/bible/bible_notes_screen.dart';
import '../../features/bible/bible_screen.dart';
import '../../features/challenges/challenge_detail_screen.dart';
import '../../features/challenges/challenge_new_screen.dart';
import '../../features/challenges/challenges_screen.dart';
import '../../features/companion/companion_screen.dart';
import '../../features/companion/invite_screen.dart';
import '../../features/devotional/devotional_screen.dart';
import '../../features/fasting/fasting_screen.dart';
import '../../features/focus/focus_active_screen.dart';
import '../../features/focus/focus_setup_screen.dart';
import '../../features/groups/groups_screen.dart';
import '../../features/guide/guide_library_screen.dart';
import '../../features/guide/guide_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/journal/journal_new_screen.dart';
import '../../features/journal/journal_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/plans/plan_detail_screen.dart';
import '../../features/plans/plans_screen.dart';
import '../../features/requests/request_new_screen.dart';
import '../../features/requests/requests_screen.dart';
import '../../features/room/room_screen.dart';
import '../../features/scripture/scripture_screen.dart';
import '../../features/settings/insights_screen.dart';
import '../../features/settings/notifications_screen.dart';
import '../../features/settings/privacy_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/upgrade_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/streak/streak_screen.dart';
import '../../features/timer/timer_screen.dart';
import '../../features/together/together_screen.dart';
import '../supabase/supabase_config.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(supa.auth.onAuthStateChange),
    redirect: (context, state) {
      final loggedIn = supa.auth.currentUser != null;
      final loc = state.matchedLocation;
      final isAuthFlow = loc == '/splash' || loc == '/onboarding';
      if (!loggedIn && !isAuthFlow) return '/onboarding';
      if (loggedIn && loc == '/onboarding') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),

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
                initialChapter: int.tryParse(s.uri.queryParameters['chapter'] ?? ''),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/journal', builder: (c, s) => const JournalScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/streak', builder: (c, s) => const StreakScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
          ]),
        ],
      ),

      GoRoute(path: '/guide', builder: (c, s) => const GuideScreen()),
      GoRoute(path: '/guide-library', builder: (c, s) => const GuideLibraryScreen()),
      GoRoute(path: '/timer', builder: (c, s) => const TimerScreen()),
      GoRoute(path: '/scripture', builder: (c, s) => const ScriptureScreen()),
      GoRoute(path: '/journal/new', builder: (c, s) => const JournalNewScreen()),
      GoRoute(path: '/requests', builder: (c, s) => const RequestsScreen()),
      GoRoute(path: '/requests/new', builder: (c, s) => const RequestNewScreen()),
      GoRoute(path: '/bible-notes', builder: (c, s) => const BibleNotesScreen()),
      GoRoute(path: '/notifications', builder: (c, s) => const NotificationsScreen()),
      GoRoute(path: '/privacy', builder: (c, s) => const PrivacyScreen()),
      GoRoute(path: '/upgrade', builder: (c, s) => const UpgradeScreen()),
      GoRoute(path: '/insights', builder: (c, s) => const InsightsScreen()),

      GoRoute(path: '/focus/setup', builder: (c, s) => const FocusSetupScreen()),
      GoRoute(path: '/focus/active', builder: (c, s) => const FocusActiveScreen()),
      GoRoute(path: '/companion', builder: (c, s) => const CompanionScreen()),
      GoRoute(path: '/companion/invite', builder: (c, s) => const InviteScreen()),
      GoRoute(path: '/challenges', builder: (c, s) => const ChallengesScreen()),
      GoRoute(
        path: '/challenges/new',
        builder: (c, s) => const ChallengeNewScreen(),
      ),
      GoRoute(
        path: '/challenges/:key',
        builder: (c, s) => ChallengeDetailScreen(challengeKey: s.pathParameters['key']!),
      ),
      GoRoute(path: '/plans', builder: (c, s) => const PlansScreen()),
      GoRoute(
        path: '/plans/:key',
        builder: (c, s) => PlanDetailScreen(planKey: s.pathParameters['key']!),
      ),
      GoRoute(path: '/devotional', builder: (c, s) => const DevotionalScreen()),
      GoRoute(path: '/fasting', builder: (c, s) => const FastingScreen()),

      GoRoute(path: '/together', builder: (c, s) => const TogetherScreen()),
      GoRoute(path: '/groups', builder: (c, s) => const GroupsScreen()),
      GoRoute(path: '/room', builder: (c, s) => const RoomScreen()),

      GoRoute(path: '/assistant', builder: (c, s) => const AssistantScreen()),
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
