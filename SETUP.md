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
`focus_sessions`, `encryption_keys`, `groups`, and `subscriptions` — all
with RLS policies scoping rows to their owner.

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

## 3. Push notifications (Smart Notifications, PRD §5.8)

Not wired up yet. The `notifications` screen's toggles are local-only UI.
To make them real: add Firebase to the project (`flutterfire configure`),
add `firebase_messaging` + `flutter_local_notifications`, and persist
preferences to the `notification_prefs` table (schema already exists).

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
unencrypted, so nobody but the signed-in device (or someone who knows the
recovery passphrase — see below) can decrypt.

Prayer Requests are **not** end-to-end encrypted (migration `0007` dropped
the `title_cipher`/`note_cipher` columns in favor of plain `title`/`note`
columns, protected only by Postgres RLS). That trade-off was made
deliberately so requests could be genuinely shared with a prayer companion
— see "Companion/Invite" below for why E2E encryption made that impossible.
Anyone with direct database access (e.g. a Supabase admin) can read request
text; Journal entries remain unreadable to anyone but the device/passphrase
holder.

**Cross-device recovery (opt-in):** from Settings → Privacy & encryption, a
user can set a recovery passphrase. That wraps their existing key with a
PBKDF2-derived key (200k iterations, random salt) and stores the wrapped
copy in the `encryption_keys` table (`supabase/migrations/0002_encryption_key_recovery.sql`).
Supabase still never sees the raw key or the passphrase — only someone who
knows the passphrase can unwrap it. On a new device, opening Journal or
Requests without a local key shows an unlock prompt (`PgPassphraseUnlock`)
asking for that passphrase; entering it decrypts and caches the key on that
device too. If a user never sets a passphrase (or has forgotten it), that's
still an honest dead end for old entries — the unlock screen offers
"start fresh on this device" instead of pretending recovery is possible.

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
  times shown are the real stored values. This only persists the
  *preference*; actually scheduling local/push notifications from those
  preferences is still unbuilt (needs a notifications/scheduling package).
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

**UI-complete, local/mock state (matches the design, not yet backed by a
table read/write):** Audio Room, Upgrade/paywall (no real billing — needs
RevenueCat or App Store/Play Billing).

**Needs platform work beyond this codebase (per the PRD's own risk
callouts):** Focus Mode's actual app-blocking (iOS Screen Time entitlement,
Android Accessibility Service — both are common App/Play Store rejection
causes; apply for the entitlement before committing to a release), Audio
Prayer Rooms (WebRTC/audio SFU + moderation), and in-app purchases for the
Upgrade screen.
