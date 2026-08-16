# Routing coverage

A reference map of every route in `lib/core/router/app_router.dart` — what
screen it renders, what params it takes, and (found by grepping every
`context.push(...)` / `context.go(...)` / `context.pushOnce(...)` call in
`lib/`) where in the app it's actually reachable from. Regenerate this by
hand after adding or removing a route; it's a snapshot, not something the
app enforces.

## Bottom nav tabs

`AppShell` / `StatefulShellRoute.indexedStack` — always reachable via
`PgBottomNav`, in this order.

| Path | Screen | Notes |
|---|---|---|
| `/home` | `HomeScreen` | Default tab. |
| `/bible` | `BibleScreen` | Also reachable directly via `book`/`chapter`/`planKey`/`day` query params (see below). |
| `/journal` | `JournalScreen` | |
| `/sermons` | `SermonNotesScreen` | |
| `/channel` | `ChannelScreen` | Now a searchable directory of church YouTube channels (`nigerian_churches.dart`) with favoriting, not just a single fixed channel — see `/channel/view` and `/channel/favorites` below. |
| `/settings` | `SettingsScreen` | The "Profile" tab. |

## Auth / onboarding flow

Reached via the router's top-level `redirect`, not a `push`/`go` call from
a screen (except where noted).

| Path | Screen | Reached from |
|---|---|---|
| `/splash` | `SplashScreen` | `initialLocation`. |
| `/onboarding` | `OnboardingScreen` | `redirect` when signed out; also `splash_screen.dart` on its own auth check. |
| `/reset-password-confirm` | `ResetPasswordConfirmScreen` | `redirect`, when Supabase reports a `passwordRecovery` auth event (the link in a reset-password email). |

`/home` is also the `redirect` target once signed in while sitting at
`/onboarding`.

## Everything else

| Path | Screen | Params | Reached from |
|---|---|---|---|
| `/channel/view` | `ChannelWebviewScreen` | `name`, `url` (query) | `channel_screen.dart` (`_open`, tapping a channel/video), `favorites_screen.dart` (`_open`, tapping a favorited item) |
| `/channel/favorites` | `FavoritesScreen` | — | `channel_screen.dart` (favorites button in the header) |
| `/guide` | `GuideScreen` | `category` (query) | `home_screen.dart` ("Start today's prayer"), `challenge_detail_screen.dart`, `guide_library_screen.dart` (category tap) |
| `/guide-library` | `GuideLibraryScreen` | — | `guide_screen.dart` (browse-all icon in the header) |
| `/timer` | `TimerScreen` | `category`, `minutes` (query) | `devotional_screen.dart`, `scripture_screen.dart`, `guide_screen.dart` |
| `/scripture` | `ScriptureScreen` | — | `home_screen.dart` (Scripture of the Day card) |
| `/journal/new` | `JournalNewScreen` | — | `journal_screen.dart` (`_createEntry`) |
| `/journal/:id` | `JournalEditScreen` | `id` (path) | `journal_screen.dart` (entry tap) |
| `/requests` | `RequestsScreen` | — | `home_screen.dart` |
| `/requests/new` | `RequestNewScreen` | — | `requests_screen.dart` (Add button + empty state) |
| `/bible-notes` | `BibleNotesScreen` | — | `bible_screen.dart` (Notes pill + notes icon) |
| `/notifications` | `NotificationsScreen` | — | `settings_screen.dart` |
| `/notifications/times/:kind` | `NotificationDayTimesScreen` | `kind` (path: `morning`/`evening`) | `notifications_screen.dart` (edit-times rows) |
| `/streak` | `StreakScreen` | — | `home_screen.dart`, `settings_screen.dart` |
| `/privacy` | `PrivacyScreen` | — | `settings_screen.dart` |
| `/privacy-policy` | `PrivacyPolicyScreen` | — | `privacy_screen.dart` |
| `/terms-of-use` | `TermsOfUseScreen` | — | `privacy_screen.dart` |
| `/about` | `AboutHelpScreen` | — | `settings_screen.dart` |
| `/insights` | `InsightsScreen` | — | `settings_screen.dart` ("Growth insights" row) |
| `/focus/setup` | `FocusSetupScreen` | — | `timer_screen.dart` (Focus Mode button) |
| `/focus/active` | `FocusActiveScreen` | — | `focus_setup_screen.dart` (`_begin`) |
| `/companion` | `CompanionListScreen` | — | `home_screen.dart`, `groups_screen.dart` ("Pray together") |
| `/companion/invite` | `InviteScreen` | — | `pushInviteCompanion()` in `companion_provider.dart` (used by `companion_list_screen.dart`, `challenge_new_screen.dart`); also pushed directly from `challenge_detail_screen.dart` |
| `/companion/:id` | `CompanionDetailScreen` | `id` (path) | `companion_list_screen.dart` |
| `/companion/invite/scan` | `QrScanScreen` | — | `invite_screen.dart` (`_scan`) |
| `/challenges` | `ChallengesScreen` | — | `home_screen.dart` |
| `/challenges/new` | `ChallengeNewScreen` | — | `challenges_screen.dart` |
| `/challenges/:key` | `ChallengeDetailScreen` | `key` (path) | `challenges_screen.dart` (catalog + in-progress cards) |
| `/plans` | `PlansScreen` | — | `bible_screen.dart` (Reading plans pill) |
| `/plans/:key` | `PlanDetailScreen` | `key` (path) | `plans_screen.dart` |
| `/devotional` | `DevotionalScreen` | — | `home_screen.dart`, `bible_screen.dart` (Devotional pill) |
| `/together/:id` | `TogetherScreen` | `id` (path), `inviteId` (query, optional) | `companion_detail_screen.dart` ("Pray live"); `push_service.dart` (notification tap / in-app accept) |
| `/groups` | `GroupsScreen` | — | `home_screen.dart` |
| `/groups/new` | `GroupNewScreen` | — | `groups_screen.dart` (New button + empty state) |
| `/room` | `RoomScreen` | `groupId` (query) | `groups_screen.dart` ("Join live room") |
| `/sermons/new` | `SermonNoteNewScreen` | — | `sermon_notes_screen.dart` |
| `/sermons/:id` | `SermonNoteDetailScreen` | `id` (path) | `sermon_notes_screen.dart` (note tap) |

## Unreachable routes (no in-app entry point)

None currently. `/insights` and `/guide-library` were each missing a tap
target as of the previous pass — fixed by adding a "Growth insights" row
in Settings and a browse-all icon on the Guide screen's header,
respectively. (The Fasting feature and its `/fasting` route were removed
entirely.)
