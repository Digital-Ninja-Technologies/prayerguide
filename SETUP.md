# Running Prayer Guide

This is a Flutter implementation of the `PrayerGuide.dc.html` prototype
(see `README.md` / `chats/chat1.md` for the design history and PRD).

## 1. Install Flutter

Flutter 3.24+ / Dart 3.5+. `flutter pub get` to fetch dependencies.

## 2. Configure Supabase

`.env` already has your project URL + anon (publishable) key. The anon key is
safe to ship in the client — it's the public key, gated by Row Level
Security. Nothing else in this repo needs a secret key.

**Apply the schema** — the anon key can't run DDL, so run this yourself:

```
supabase link --project-ref glkgiigirmfrmbgsmdrp
supabase db push        # applies every file in supabase/migrations/, in order
```

(or paste each migration file into the Supabase SQL editor, in numeric
order — `0001_init.sql` first, then `0002`, `0003`, `0004`, ...).

This creates `profiles`, `journal_entries`, `prayer_requests`,
`prayer_sessions` (feeds the streak via a DB trigger), `bible_notes`,
`notification_prefs`, `companions`/`companion_invites`/`companion_checkins`,
`challenge_progress`, `reading_plan_progress`, `fasting_sessions`,
`focus_sessions`, `groups`, `subscriptions`, and `sermon_notes` — all with
RLS policies scoping rows to their owner. (An early migration also created
`encryption_keys` for passphrase-based key escrow; migration `0009` drops
it now that cloud backup replaced that scheme — see below.) Migration
`0014` also creates a private `sermon-audio` Storage bucket (with RLS on
`storage.objects` scoping each user to their own folder) for the Sermon
Note Taker's recordings — nothing extra to configure, `supabase db push`
sets it up along with everything else.

**Social auth (Google / Apple) via Supabase** — the app code side is done:
`AuthRepository.signInWithGoogle/signInWithApple` call `signInWithOAuth` with
`redirectTo: kOAuthRedirect` (`io.supabase.prayerguide://login-callback/`,
defined in `lib/data/repositories/auth_repository.dart`), and that URL scheme
is already registered on both platforms (`android/app/src/main/AndroidManifest.xml`'s
`login-callback` intent-filter, `ios/Runner/Info.plist`'s `CFBundleURLTypes`).
`supabase_flutter` handles the incoming deep link and session exchange
automatically — no extra Dart wiring needed. What's left is dashboard +
provider-console configuration, which can't be done from this repo:

1. **Supabase Dashboard → Authentication → URL Configuration → Redirect URLs**
   — add `io.supabase.prayerguide://login-callback/` to the allow list (in
   addition to whatever your Site URL is). OAuth will fail silently without
   this. **On web** (`flutter run -d chrome`, or any web deployment), the
   custom `io.supabase.prayerguide://` scheme means nothing to a browser —
   `AuthRepository` redirects to the page's own origin instead (see
   `_oauthRedirect` in `auth_repository.dart`), so also add that origin
   (e.g. `http://localhost:PORT` for local dev, or your deployed domain) to
   the same Redirect URLs allow list. The password-reset email link uses the
   same redirect and needs the same allow-list entries — without them, the
   "Forgot password" flow sends an email whose link goes nowhere useful.
2. **Google** — in [Google Cloud Console](https://console.cloud.google.com/apis/credentials),
   create an OAuth 2.0 Client ID (Web application type — Supabase's hosted
   authorize/callback endpoint does the redirect, so the *web* client type is
   correct even though you're calling it from mobile). Add
   `https://<project-ref>.supabase.co/auth/v1/callback` as an authorized
   redirect URI on that client. Paste the client ID + secret into Supabase
   Dashboard → Authentication → Providers → Google, and enable it.
3. **Apple** — in [Apple Developer](https://developer.apple.com/account/resources/identifiers/list/serviceId),
   create a Services ID, enable "Sign in with Apple", and set its return URL
   to `https://<project-ref>.supabase.co/auth/v1/callback`. Generate a
   private key for Sign in with Apple, and enter the Services ID, Team ID,
   Key ID, and private key into Supabase Dashboard → Authentication →
   Providers → Apple. Separately, add the **Sign in with Apple capability**
   to the iOS target in Xcode (`ios/Runner.xcodeproj`) — Apple requires this
   entitlement for the native app regardless of Supabase's config, and (per
   App Store guideline 4.8) requires it if the app offers other social
   logins at all.
4. If you ever change the bundle ID / package name from `com.prayerguide.*`,
   update `kOAuthRedirect`'s scheme (`io.supabase.prayerguide`) to match, in
   all three places: `auth_repository.dart`, the Android intent-filter, and
   the iOS `CFBundleURLTypes` entry.

Full reference: [supabase_flutter OAuth docs](https://supabase.com/docs/guides/auth/social-login).

## 3. Notifications (Smart Notifications, PRD §5.8)

Morning prayer, evening prayer, scripture-of-the-day, and streak-protection
reminders are real local (on-device) notifications, not just UI —
`lib/core/notifications/notification_scheduler.dart` (via
`flutter_local_notifications` + `timezone`/`flutter_timezone`) schedules or
cancels them whenever a toggle changes, on app start, and (for streak
protection specifically) right after you complete a prayer session, so it
doesn't nag you for a day you already prayed. No extra setup needed — this
works out of the box on iOS and Android.

**Companion check-ins are the one exception**: notifying *you* when your
companion checks in requires a server-triggered push (Supabase Edge
Function + FCM/APNs), since it depends on someone else's action, not a
schedule your device already knows about. That toggle still saves your
preference but doesn't fire a notification yet — wiring it up means adding
Firebase (`flutterfire configure` + `firebase_messaging`) and a Postgres
trigger/Edge Function on `companion_checkins` inserts that calls FCM/APNs.

## 3a. Google Drive backup (optional, Android cloud backup)

The Android "back up to Google Drive" flow (Settings → Privacy & encryption)
needs a **Web application** OAuth 2.0 client id from
[Google Cloud Console](https://console.cloud.google.com/apis/credentials)
(Web, not Android type — `google_sign_in` on Android uses it as
`serverClientId` even though the app itself is Android). Steps:

1. Create (or reuse) a Google Cloud project, enable the **Google Drive API**.
2. Credentials → Create Credentials → OAuth client ID → **Web application**.
   Add your Supabase project's domain (or `localhost` for dev) under
   Authorized redirect URIs if prompted — Drive's `appDataFolder` scope
   doesn't need a redirect flow on Android, but Google's console may still
   require one to be listed.
3. Also register the Android app itself (package name
   `com.prayerguide.prayer_guide` + your release/debug SHA-1 fingerprints)
   under **OAuth consent screen → Android** so Google trusts the app calling
   in — see the [google_sign_in_android setup docs](https://pub.dev/packages/google_sign_in_android#integration).
4. Put the **Web application** client id in `.env` as `GOOGLE_OAUTH_CLIENT_ID`.

Without this, the button explains it isn't configured rather than failing
silently. iOS's iCloud backup needs none of this — it uses
`flutter_secure_storage`'s `synchronizable` Keychain option, which just
needs the user's device to have iCloud Keychain turned on.

## 3b. LiveKit (Audio Prayer Room voice)

Audio Prayer Room (Groups → a room's "Join live room") already has real,
live member presence via Supabase Realtime (`lib/features/room/room_screen.dart`)
— the member grid, host badge, and raised hands are genuinely synced.
Actually hearing each other needs [LiveKit](https://livekit.io):

1. Create a free [LiveKit Cloud](https://cloud.livekit.io) account and
   project.
2. From the project's Settings → Keys, grab the **API Key**, **API
   Secret**, and the **WebSocket URL** (`wss://your-project.livekit.cloud`).
3. **Put the API Key/Secret in Supabase Edge Function secrets — never in
   `.env`.** A client-embedded secret could be extracted from the app
   bundle and used to mint join tokens for any room. Either run:
   ```
   supabase secrets set LIVEKIT_API_KEY=... LIVEKIT_API_SECRET=...
   ```
   or set them in the Supabase dashboard → Edge Functions → Secrets.
4. **Deploy the token function**: `supabase functions deploy livekit-token`
   (or paste `supabase/functions/livekit-token/index.ts` into a new Edge
   Function in the dashboard). It verifies the caller is actually a member
   of the group before minting a token — see the file for details.
5. **Put only the WebSocket URL** in `.env` as `LIVEKIT_URL` — this one is
   just a connection endpoint, safe to ship client-side.

Once `LIVEKIT_URL` is set, `room_screen.dart` requests microphone
permission, fetches a token from the Edge Function, and joins the room's
voice automatically alongside presence — with a mic mute/unmute button.
Leave it blank to disable — rooms stay presence-only (today's behavior)
rather than failing.

## 3c. Church YouTube channel (Channel tab)

The Channel tab (`lib/features/channel/channel_screen.dart`) embeds the
church's YouTube channel in a real WebView (`webview_flutter`) — not just a
link out. Set `CHURCH_YOUTUBE_CHANNEL_URL` in `.env` to the channel's URL
(e.g. `https://www.youtube.com/@yourchurch`). Leave it blank to show a "not
configured" message instead of a broken viewer.

Signing into a Google/YouTube account inside the tab stays signed in across
app restarts with no extra code — the platform WebView's cookie storage is
persistent by default; nothing clears it. Not available on web builds
(`webview_flutter` doesn't support web here) — that target only exists for
internal build verification, not shipping.

## 3d. Push notifications (Companion prayer invites)

Tapping "Pray live" on a companion's detail screen already drops you into a
real live session (`lib/features/together/together_screen.dart`, Supabase
Realtime Presence) — but until now the other side only found out if they
happened to already be in the app. This adds a real push notification, an
in-app accept/decline pop-up, and lets the requester see if it was
declined.

**What's already wired, with nothing to configure:**
`supabase/migrations/0021_companion_prayer_invites.sql` (the
`companion_prayer_invites` + `device_push_tokens` tables, RLS, and the
`respond_to_prayer_invite` RPC) and the client side
(`lib/state/prayer_invite_provider.dart`,
`lib/core/notifications/push_service.dart`). What's left needs a real
Firebase project — until then, `PushService.isConfigured` is false and
[init] no-ops, same "leave it blank to disable" pattern as every other
optional integration in this app.

1. **Create a [Firebase project](https://console.firebase.google.com)**
   (or reuse one), then add both an iOS app (bundle id
   `com.prayerguide.prayerGuide`) and an Android app (package
   `com.prayerguide.prayer_guide`) to it.
2. **iOS also needs an APNs key** uploaded to the Firebase project (Project
   Settings → Cloud Messaging → Apple app configuration) — generate one at
   [developer.apple.com](https://developer.apple.com/account/resources/authkeys/list)
   (Keys → + → enable Apple Push Notifications service).
3. **Run the FlutterFire CLI** from the repo root:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Select the Firebase project and both platforms. This overwrites
   `lib/firebase_options.dart` (currently a placeholder — see the comment
   at its top) with your project's real values, which is what flips
   `PushService.isConfigured` to true.
4. **In Xcode** (`ios/Runner.xcworkspace`), select the Runner target →
   Signing & Capabilities → **+ Capability → Push Notifications**. This
   creates/updates `Runner.entitlements` — commit it.
5. **Deploy the Edge Function** and give it a Firebase service account:
   - Firebase Console → Project Settings → Service Accounts → Generate new
     private key (downloads a JSON file).
   - ```
     supabase functions deploy send-companion-invite-push
     supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat path/to/the-downloaded-file.json)"
     ```
   (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` are
   provided automatically, same as every other Edge Function here.)

Once all of the above is done, "Pray live" pushes the other side a
notification even if they're not in the app; tapping it (or the in-app
pop-up if they already are) joins them into the same live session, and
declining tells the requester "so-and-so can't pray right now" instead of
leaving them waiting indefinitely. Without it, "Pray live" still works
exactly as it always has — presence-only, for whoever's already there.

## 3e. Dynamic Island (Prayer Timer Live Activity)

A live countdown on the Lock Screen and, on supported iPhones, the Dynamic
Island — while a Prayer Timer session (`lib/features/timer/timer_screen.dart`)
is running, similar to a live sports score. iOS-only (there's no Android
equivalent of Live Activities) and needs iOS 16.1+.

**Already written, nothing left to configure in code:**
`lib/core/live_activity/live_activity_service.dart` (the Dart side, wired
into `timer_screen.dart`'s start/pause/resume/finish already) and
`ios/Runner/LiveActivityChannel.swift` (the native method-channel handler,
registered from `AppDelegate.swift`). **What's missing is the Xcode Widget
Extension target itself** — this repo intentionally doesn't hand-edit
`project.pbxproj` to add one; that kind of raw Xcode project surgery is
easy to get subtly wrong and impossible to verify without Xcode itself.
Add it the normal way:

1. **In Xcode** (`ios/Runner.xcworkspace`): File → New → Target → **Widget
   Extension**. Name it `PrayerTimerWidget`, and check **"Include Live
   Activity"**. Xcode scaffolds a new `ios/PrayerTimerWidget/` group with
   starter files — the ones already in this repo's `ios/PrayerTimerWidget/`
   folder on disk replace them:
   - Delete Xcode's generated `PrayerTimerWidget.swift` (or
     `PrayerTimerWidgetLiveActivity.swift`, whatever it names the
     Live Activity file) and `PrayerTimerWidgetBundle.swift`.
   - Add the existing `PrayerTimerAttributes.swift`,
     `PrayerTimerLiveActivity.swift`, and `PrayerTimerWidgetBundle.swift`
     from `ios/PrayerTimerWidget/` to the new target (drag them into the
     group in Xcode, making sure **"PrayerTimerWidget"** is checked under
     Target Membership).
2. **Add `PrayerTimerAttributes.swift` to the Runner target too** (select
   it in Xcode, check **"Runner"** as well as "PrayerTimerWidget" under
   Target Membership) — `LiveActivityChannel.swift` in the main app needs
   the same type the widget renders.
3. **Set the extension's deployment target to iOS 16.1+** (its own target
   → General → Minimum Deployments) — Live Activities don't exist before
   that, even though the main app's deployment target stays at 13.0 for
   everything else.
4. Build and run on a **physical device** — Live Activities and the
   Dynamic Island don't render in the iOS Simulator except on some
   simulated hardware/OS combinations; a real iPhone 14 Pro or newer shows
   the actual Dynamic Island, older iPhones still get the Lock Screen
   banner.

Without the extension target added, `LiveActivityService` still runs
without crashing — `Activity.request()` just has nothing to render, so
starting a Prayer Timer session behaves exactly as before.

## 3f. Xcode Cloud (iOS CI)

`ios/ci_scripts/ci_post_clone.sh` runs automatically after Xcode Cloud
clones the repo, before it builds. It does two things a fresh git checkout
is otherwise missing entirely:

1. **Installs Flutter** (a shallow clone of the `stable` channel, since
   Xcode Cloud's VM starts empty every run) and runs `flutter pub get` +
   `pod install`. Without this, `xcodebuild` fails immediately with
   `Could not resolve package dependencies ...
   FlutterGeneratedPluginSwiftPackage ... doesn't exist in file system` —
   that Swift Package is generated by `flutter pub get`, not committed.
2. **Generates `.env`** from Xcode Cloud's own Environment Variables.
   `.env` is bundled as a Flutter asset (`pubspec.yaml`) that
   `flutter_dotenv` reads at runtime — it's correctly gitignored, so
   without this step the later Flutter build phase fails looking for a
   declared asset file that simply isn't there.

**Required setup in App Store Connect** (once, per workflow): your app →
Xcode Cloud → the workflow → **Environment → Environment Variables** → add
`SUPABASE_URL` and `SUPABASE_ANON_KEY` (mark `SUPABASE_ANON_KEY` as
**Secret**). Xcode Cloud injects whatever's configured there into every
script phase's environment, including `ci_post_clone.sh`, which writes them
into the generated `.env`. The rest (`GOOGLE_OAUTH_CLIENT_ID`,
`CHURCH_YOUTUBE_CHANNEL_URL`, `IOS_APP_STORE_ID`, `LIVEKIT_URL`) are
optional, same names and same "leave blank to disable" behavior as
`.env.example` — add them the same way if you want those integrations
working in Xcode Cloud builds too.

No setup needed for the script to run at all — Xcode Cloud finds and runs
`ci_post_clone.sh` by convention (the exact path), as long as its
"Executable" file permission bit is preserved
(`git update-index --chmod=+x` if it's ever lost).

## 4. What's real vs. prototype-visual

**Wired to Supabase (real CRUD, survives app restart):**
Auth (email/password + reset + create account; Google/Apple need the
dashboard config above), Journal, Prayer Requests, Profile/Settings
(theme preference, hide-streak toggle), and the Prayer Streak (a DB trigger
recomputes it from logged `prayer_sessions`).

Journal entry text is genuinely end-to-end encrypted:
`lib/core/security/encryption_service.dart` generates a random AES-256-GCM
key on-device, stored only in the platform Keychain/Keystore via
`flutter_secure_storage`. Supabase only ever stores ciphertext
(`title_cipher`/`body_cipher` columns) — the key never leaves the device
unencrypted, so nobody but a device with the key (or a successful cloud
restore — see below) can decrypt.

Prayer Requests are **not** end-to-end encrypted (migration `0007` dropped
the `title_cipher`/`note_cipher` columns in favor of plain `title`/`note`
columns, protected only by Postgres RLS). That trade-off was made
deliberately so requests could be genuinely shared with a prayer companion
— see "Companion/Invite" below for why E2E encryption made that impossible.
Anyone with direct database access (e.g. a Supabase admin) can read request
text; Journal entries remain unreadable to anyone without the key.

**Cross-device backup (opt-in, replaces the old passphrase/escrow scheme —
migration `0009` drops the now-unused `encryption_keys` table):** from
Settings → Privacy & encryption, a user can back their key up to their own
cloud account instead of memorizing a passphrase:

- **iOS**: `EncryptionService.backupToICloud` re-saves the key into a
  Keychain item marked `synchronizable` — iOS's own iCloud Keychain sync
  then carries it to the user's other devices automatically (their device
  needs iCloud Keychain turned on in Settings). Apple handles the
  transport; this app never sees or transmits the key itself.
- **Android**: Keystore-protected secrets are intentionally non-exportable,
  so there's no OS-level equivalent. `lib/core/backup/cloud_backup_service.dart`
  uploads the key to the signed-in Google account's app-private Drive
  folder (`appDataFolder` — invisible in the user's regular Drive, only
  this app can read it) instead. Needs `GOOGLE_OAUTH_CLIENT_ID` — see
  section 3a above.

On a new device, opening Journal without a local key and with existing
encrypted entries on the account shows a restore prompt
(`PgCloudRestoreUnlock`) offering the platform-appropriate cloud restore.
If a user never backed up (or the backup isn't reachable), that's still an
honest dead end for old entries — the prompt offers "start fresh on this
device" instead of pretending recovery is possible.

**Bible reader, Bible highlights/bookmarks/notes, Reading Plans, and the
Devotional are also real**, not mocked: the reader runs on the full KJV
text bundled locally (`assets/bible/kjv.json`, public domain, 66 books /
31,102 verses — see `lib/data/bible/bible_library.dart`), so it works fully
offline with real book/chapter navigation. Highlights/bookmarks/notes are
stored in the `bible_notes` table. Reading Plans generate a real day-by-day
schedule from that same text (`lib/data/bible/reading_plan_schedule.dart`)
and track progress per user in `reading_plan_progress`. The Devotional
rotates through 14 curated entries by day-of-year, pulling its scripture
text live from the bundled Bible rather than retyping it.

**Growth Insights, Fasting, Focus Mode session tracking, Challenges, and
Companion/Invite are also real** now:

- **Growth Insights** — the weekly bar chart, total time, and "gentle
  insight" text are computed from actual `prayer_sessions` rows (this
  week's per-day totals, most-visited category, most common time of day),
  not hardcoded.
- **Fasting** — start/end a real fast (`fasting_sessions`), with a live
  elapsed/remaining ring and real prayer-session/journal-entry counts
  during the fast window.
- **Focus Mode** — start/end is tracked for real (`focus_sessions`, new
  migration `0005`) with a live elapsed timer on the overlay. This is
  session *tracking* only — actual app-blocking still needs the OS
  entitlements below; the "apps to quiet" toggles remain visual.
- **Challenges** — `challenge_progress` tracks real day-by-day progress for
  both catalog challenges and custom ones created via Create Challenge.
  Tapping Start/Continue advances the day and persists it.
- **Companion/Invite** — real invite codes (`companion_invites` +
  `redeem_companion_invite` RPC, migration `0006`) pair two accounts via
  `companions`; check-ins persist to `companion_checkins` and show real
  history; shared streak is `min(your streak, their streak)`. The invite
  screen now shows a real, scannable QR code (`qr_flutter`) of the invite
  link, and "Scan a code instead" opens a live camera scanner
  (`mobile_scanner`) that reads a companion's QR and redeems it
  automatically — pairing also still works via copy/paste or manually
  typing the code. Scanning needs camera permission (`NSCameraUsageDescription`
  on iOS; `mobile_scanner`'s own manifest declares the Android permission).
  **Shared prayer requests are now real**: a
  request can be flagged `shared_with_companion` when created (or via the
  toggle on the Requests list), and migration `0007` adds an RLS policy
  granting a paired companion read access to just those flagged rows —
  this only became possible after removing E2E encryption from Prayer
  Requests (see above); with the key living only on the author's device,
  a companion's device had no way to decrypt anything. The Companion
  screen shows a "Shared requests" section (category + title, attributed
  to whoever shared it) above the existing real check-in history.
  **"Pray live" can also push-notify the companion now** (migration `0021`
  + `send-companion-invite-push`) so they find out even if they're not
  already in the app — needs Firebase configured (§3d); until then it
  behaves exactly as before, presence-only.

**Guide Library, Notifications, Groups, and Prayer Together are also real**
now:

- **Guide Library** — each of the 6 categories (Thanksgiving, Worship,
  Repentance, Family, Healing, Spiritual Growth) has its own real verse,
  intro, prayer points, and reflection question (`lib/data/static/pg_content.dart`);
  tapping a category routes `/guide?category=...` to the matching content
  instead of always showing "Thanksgiving". Tapping "Begin" now also passes
  the real category through to the timer, so completed sessions log the
  actual category prayed (`prayer_sessions.category`) instead of always
  logging "Thanksgiving" — this also fixes Growth Insights' "most-visited
  category" stat, which was silently wrong for every session before this.
  Devotional and Scripture-of-the-day sessions log their own categories too.
- **Notifications** — all five toggles (morning/evening prayer, scripture
  nudge, streak protection, companion check-ins) read and write the
  existing `notification_prefs` table in real time; reminder/quiet-hours
  times shown are the real stored values. Morning/evening/scripture/streak-
  protection also schedule real local notifications now (see the
  Notifications section further up) — only companion check-ins remain
  preference-only, since that one needs a server push, not a local
  schedule.
- **Groups** — real `groups` + `group_members` tables (already scaffolded
  in `0001_init.sql`); migration `0008` adds a shareable invite code +
  `redeem_group_invite` RPC (same pattern as Companion invites, needed
  because the member-only RLS policy means you can't look up a group you're
  not in yet). You can create a group, share its code, join another
  group by code, and leave a group; the list shows real member counts.
  There's no group chat/discussion feed — the original design never had
  one either, just this membership list.
- **Prayer Together** — a real live session with your paired Companion
  using Supabase Realtime Presence (`lib/features/together/together_screen.dart`),
  not a hardcoded "6:20" timer. Each device tracks presence on a channel
  keyed by the companion pairing id; the screen shows "Waiting for
  `<name>`…" until both of you are actually present, then starts a timer
  synced from the later of the two join timestamps. Leaving untracks
  presence. This needs a paired companion to work (there was never a
  group version of this in the design — the two-avatar UI and the
  prototype's own back-button wiring both point at Companion, not Groups).

**Prayer Timer ambience is real**: the Meditation/Silence/Tender Clouds
pills loop real bundled audio (`audioplayers`,
`lib/features/timer/ambience_player.dart`, tracks in `assets/audio/`)
instead of just toggling a pill with no sound. Tapping a pill starts that
track on loop and shows a small pulsing dot next to "AMBIENCE" while
audio is playing; tapping the same pill again stops it. To swap or add a
track, drop a file in `assets/audio/` and update the `_fileFor` map in
`ambience_player.dart` plus the pill list in `timer_screen.dart`. On iOS,
a running session also drives a real Lock Screen/Dynamic Island Live
Activity (`lib/core/live_activity/live_activity_service.dart`) once the
`PrayerTimerWidget` extension target is added in Xcode (§3e) — without it,
the timer works exactly as before, just without the lock-screen countdown.

**Scripture of the Day is real**: both the Home screen card and the full
`/scripture` screen pull from a 14-entry library
(`lib/data/scripture/scripture_of_day_library.dart`) cycled by
day-of-year (offset from the Devotional's own rotation so they don't show
the same verse on the same day), with verse text pulled live from the
bundled KJV — not a single hardcoded verse and a literally hardcoded
"JULY 21" date. Home's Devotional/Challenges/Companion mini-tiles and the
"Start today's prayer" card also now show real data (today's devotional
title, your actual active-challenge day count, your real companion's
name, real time-of-day) instead of hardcoded placeholders.

**Audio Prayer Room is real, including voice, once LiveKit is
configured** (see §3b): joining a room (reachable from a group's "Join
live room" button in Groups) opens a Supabase Realtime Presence channel
keyed to that group (`lib/features/room/room_screen.dart`, same technique
as Prayer Together) — the member grid, count, host badge, and raised
hands are all real and synced live. With `LIVEKIT_URL` set, it also joins
real LiveKit voice with a mic mute/unmute button. Without it, rooms fall
back to presence-only rather than failing.

**Sermon Note Taker is real** (`lib/features/sermons/`, its own bottom nav
tab): record audio while typing notes at the same time — the two aren't
sequential steps. `lib/core/audio/sermon_recorder.dart` wraps the `record`
package (mono AAC-LC, since it's speech not music) with start/pause/
resume/stop; on save, the recording uploads to the private `sermon-audio`
Storage bucket (migration `0014`) and the note (title, speaker, scripture
reference, notes text, audio path/duration) is written to `sermon_notes`.
Playback on the detail screen streams from a short-lived signed URL — the
bucket is private, so that's the only way to reach the audio. Recording
is disabled in web builds (`kIsWeb`-gated; the underlying platform APIs
aren't there) — typed notes still work fine there. Notes text is plain,
RLS-protected like Prayer Requests, not end-to-end encrypted like Journal
— sermon notes aren't the kind of content that scheme was built to
protect, and encrypting them would block a future "share this note"
feature the same way it did for Requests.

**Still needs platform work beyond this codebase (per the PRD's own risk
callouts):** Focus Mode's actual app-blocking (iOS Screen Time entitlement,
Android Accessibility Service — both are common App/Play Store rejection
causes; apply for the entitlement before committing to a release) and
Offline Audio Bible (needs a real audio content source — see the Digital
Bible Platform integration, once wired up).
