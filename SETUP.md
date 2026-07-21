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
supabase db push        # applies supabase/migrations/0001_init.sql
```

(or paste `supabase/migrations/0001_init.sql` into the Supabase SQL editor).

This creates `profiles`, `journal_entries`, `prayer_requests`,
`prayer_sessions` (feeds the streak via a DB trigger), `bible_notes`,
`notification_prefs`, `companions`/`companion_invites`/`companion_checkins`,
`challenge_progress`, `reading_plan_progress`, `fasting_sessions`, `groups`,
and `subscriptions` — all with RLS policies scoping rows to their owner.

**Enable auth providers** you want to use, in the Supabase dashboard
(Authentication → Providers):
- Email is on by default.
- Google — add your OAuth client ID/secret.
- Apple — add your Services ID + key; also add the Sign in with Apple
  capability in Xcode for the iOS target.

Both OAuth flows use `supabase_flutter`'s `signInWithOAuth`, which opens a
browser/deep-link redirect — you'll need a redirect URL configured in both
Supabase and your app's URL scheme (see the [supabase_flutter OAuth
docs](https://supabase.com/docs/guides/auth/social-login)).

## 3. AI Prayer Assistant (Phase 4)

The Assistant screen calls a Supabase Edge Function
(`supabase/functions/assistant-proxy`) that proxies to Claude. Your
Anthropic API key is **never** put in the Flutter app — it lives only as a
server-side secret:

```
supabase functions deploy assistant-proxy
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
```

Until this is deployed, the Assistant screen still works — it shows a
friendly "not connected yet" message instead of a reply.

## 4. Push notifications (Smart Notifications, PRD §5.8)

Not wired up yet. The `notifications` screen's toggles are local-only UI.
To make them real: add Firebase to the project (`flutterfire configure`),
add `firebase_messaging` + `flutter_local_notifications`, and persist
preferences to the `notification_prefs` table (schema already exists).

## 5. What's real vs. prototype-visual

**Wired to Supabase (real CRUD, survives app restart):**
Auth (email/password + reset + create account; Google/Apple need the
dashboard config above), Journal, Prayer Requests, Profile/Settings
(theme preference, hide-streak toggle), and the Prayer Streak (a DB trigger
recomputes it from logged `prayer_sessions`).

Journal entry text and prayer request title/note are genuinely end-to-end
encrypted: `lib/core/security/encryption_service.dart` generates a random
AES-256-GCM key on-device, stored only in the platform Keychain/Keystore via
`flutter_secure_storage`. Supabase only ever stores ciphertext
(`title_cipher`/`body_cipher`/`note_cipher` columns) — the key never leaves
the device unencrypted, so nobody but the signed-in device (or someone who
knows the recovery passphrase — see below) can decrypt.

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

**UI-complete, local/mock state (matches the design, not yet backed by a
table read/write):** Guide Library, Bible reader/notes, Notifications
toggles, Focus Mode, Companion/Invite, Challenges, Reading Plans,
Devotional, Fasting, Prayer Together / Groups / Audio Room, Growth
Insights, Upgrade/paywall (no real billing — needs RevenueCat or
App Store/Play Billing).

Those all have matching tables in the migration already, so wiring them up
is a repository + provider per screen, following the same pattern as
`lib/data/repositories/journal_repository.dart` +
`lib/state/journal_provider.dart`.

**Needs platform work beyond this codebase (per the PRD's own risk
callouts):** Focus Mode's actual app-blocking (iOS Screen Time entitlement,
Android Accessibility Service — both are common App/Play Store rejection
causes; apply for the entitlement before committing to a release), Prayer
Together's real-time sync (Supabase Realtime channels), Audio Prayer Rooms
(WebRTC/audio SFU + moderation), and in-app purchases for the Upgrade
screen.
