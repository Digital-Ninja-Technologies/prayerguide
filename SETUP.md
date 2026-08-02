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
   this.
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

## 3b. RevenueCat (Premium subscriptions, real billing)

The Upgrade screen (`lib/features/settings/upgrade_screen.dart`) uses
[RevenueCat](https://www.revenuecat.com) (`purchases_flutter` +
`purchases_ui_flutter`) to sell real Monthly/Annual subscriptions through
the App Store and Play Store, gated behind an entitlement named
`PrayerGuide`. Without API keys configured, the screen shows a "not
configured" notice and preview pricing instead of failing — same pattern
as Google Drive backup above.

**Right now this app is wired to a RevenueCat Test Store** (`.env`'s
`REVENUECAT_API_KEY`, a `test_...` key) — it exercises the full
purchase/restore/entitlement flow without needing a real Apple/Google
developer account, but purchases aren't real money and won't survive a
switch to production keys. To go live:

1. **Apple Developer Program** ($99/yr) and **Google Play Console** ($25
   one-time) accounts — required before either store will let you create
   in-app purchase products. Both have identity/business verification that
   can take a few days, so start these first if you don't have them yet.
2. **Create the subscription products** in each store:
   - App Store Connect → your app → Subscriptions → create a subscription
     group with **Monthly** and **Annual** auto-renewable subscriptions.
   - Google Play Console → your app → Monetize → Subscriptions → same two
     products.
   - Product IDs just need to be consistent between the store and
     RevenueCat's dashboard — e.g. `pg_premium_monthly` / `pg_premium_annual`.
   - Price the **Annual** product **15% below Monthly × 12** (e.g. Monthly
     $4.99 → Annual $50.90) — the Upgrade screen's "SAVE X%" badge computes
     its percentage live from whatever the two products actually cost, so
     pricing them any other way will just show a different (but still
     correct) percentage rather than break anything.
3. **Create a [RevenueCat](https://app.revenuecat.com) project** (or reuse
   the existing Test Store one), add both the iOS and Android apps, and
   connect each to its store (App Store Connect requires an
   App-Specific Shared Secret; Play Console requires a service-account
   JSON with access to your app — RevenueCat's dashboard walks through
   generating both).
4. **Create an Entitlement** named exactly `PrayerGuide` (must match
   `kPremiumEntitlementId` in `lib/core/purchases/revenue_cat_service.dart`)
   and attach both products to it.
5. **Create an Offering** (e.g. `default`) with two Packages — one
   `$rc_monthly`, one `$rc_annual` — pointing at the two products.
   `upgrade_screen.dart` looks up packages by `PackageType.monthly` /
   `PackageType.annual`, so the packages must use RevenueCat's standard
   monthly/annual package types.
6. **Design the Paywall** (RevenueCat dashboard → Paywalls) for the
   `PrayerGuide` entitlement — used by `requirePremium()`
   (`lib/core/purchases/premium_gate.dart`) to gate premium-only features
   at the point of use (currently wired to the Focus Mode entry point in
   `timer_screen.dart`; call `requirePremium(context)` before unlocking any
   other premium feature the same way).
7. **Copy the real per-platform public SDK keys** (RevenueCat dashboard →
   Project Settings → API Keys — the public SDK keys, not the secret key)
   into `.env` as `REVENUECAT_IOS_API_KEY` / `REVENUECAT_ANDROID_API_KEY`,
   and clear `REVENUECAT_API_KEY` — the app prefers that Test Store key
   over the platform-specific ones whenever it's set.

Once configured, `SubscriptionRepository.fetch()` reads live entitlement
status from RevenueCat (falling back to a cached `subscriptions` row in
Supabase if RevenueCat isn't configured) and stays in sync afterwards via
`RevenueCatService.customerInfoStream` — RevenueCat's live update
listener, which fires on purchases, restores, renewals, and even
purchases made on another device, without needing to re-fetch manually.
Every purchase/restore/update is synced back to the `subscriptions` table.
Test purchases against the Test Store need nothing extra; against real
stores, use a sandbox tester (App Store Connect → Users and Access →
Sandbox) or a Play Console license-test account — real cards are never
charged in sandbox/test mode.

**Customer Center** (RevenueCat dashboard → Customer Center) lets
subscribers self-serve cancel/manage their plan from inside the app —
configure it in the dashboard and it's already wired up as a "Manage
subscription" button on the Upgrade screen once a subscription is active.

## 3c. LiveKit (Audio Prayer Room voice)

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
`ambience_player.dart` plus the pill list in `timer_screen.dart`.

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
configured** (see §3c): joining a room (reachable from a group's "Join
live room" button in Groups) opens a Supabase Realtime Presence channel
keyed to that group (`lib/features/room/room_screen.dart`, same technique
as Prayer Together) — the member grid, count, host badge, and raised
hands are all real and synced live. With `LIVEKIT_URL` set, it also joins
real LiveKit voice with a mic mute/unmute button. Without it, rooms fall
back to presence-only rather than failing.

**Subscriptions are real, real billing included** (see §3b): the Upgrade
screen sells actual Monthly/Annual subscriptions through RevenueCat, with
live entitlement status, purchase/restore, and Customer Center management.

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
