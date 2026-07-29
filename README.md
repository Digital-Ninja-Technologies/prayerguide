# Prayer Guide

A Flutter mobile app that helps Christians build a consistent, Scripture-centered
prayer habit — guided prayer, a prayer timer, journaling, prayer requests, a
gentle (non-shame-based) streak, and companion/community features. Built for
iOS and Android from a single codebase.

This app is the real implementation of a prototype designed in
[Claude Design](https://claude.ai/design); see [Design origin](#design-origin)
below for where the visual system and product spec came from.

## Scope

The app covers all four phases of the product spec
(`project/uploads/PrayerGuide_PRD_v2_1.md`):

- **Phase 1 — the habit loop.** Onboarding, auth (email/password + reset +
  create account, Google, Apple), Home, Daily Prayer Guide + guide library,
  Prayer Timer, Scripture of the Day, a KJV Bible reader with bookmarks/notes,
  Prayer Journal, Prayer Request manager, Prayer Streak with milestones,
  Notifications preferences, Settings/Profile, Upgrade/Premium.
- **Phase 2 — depth & accountability.** Focus Mode (setup + gentle in-session
  overlay), Prayer Companion + invite flow, Prayer Challenges (list, detail,
  create), Bible reading plans, Daily Devotional, Fasting Companion.
- **Phase 3 — live & community.** Prayer Together (synced session), Prayer
  Groups, Audio Prayer Room.
- **Phase 4 — intelligence.** Growth Insights.

There is no AI Prayer Assistant — it was removed (see `git log` for
`Add custom app icon, remove unwired Prayer Assistant feature`) since it
required a deployed Supabase Edge Function and an Anthropic API key that
weren't part of this project's setup. Re-adding it would mean restoring
`supabase/functions/assistant-proxy` and its route/repository.

Not every screen is backed by live data yet — see
[What's real vs. UI-only](#whats-real-vs-ui-only).

## Stack

- **Flutter / Dart** — single codebase for iOS + Android.
- **flutter_riverpod** — app state (auth, profile, journal, requests).
- **go_router** — declarative routing; `StatefulShellRoute` drives the
  persistent bottom nav (Home / Bible / Journal / Streak / Profile).
- **Supabase** — Postgres + Auth (email/password, Google, Apple). Schema and
  RLS policies live in `supabase/migrations/`.
- **Client-side encryption** — journal entries are encrypted on-device
  (AES-256-GCM via the `cryptography` package) before they ever reach
  Supabase, with the key held in the platform Keychain/Keystore
  (`flutter_secure_storage`). See `lib/core/security/encryption_service.dart`.
  Prayer requests are stored as plain text (protected by RLS, not E2E
  encryption) so they can be shared with a paired prayer companion.
- **Cloud key backup** — opt-in, platform-native: iCloud Keychain sync on
  iOS (zero config), Google Drive `appDataFolder` on Android (via
  `google_sign_in`, needs a client id — see SETUP.md). Replaces an earlier
  passphrase-based recovery scheme.
- **flutter_local_notifications** — real, scheduled prayer/scripture
  reminders (see SETUP.md's Notifications section for what's and isn't
  wired).
- **Bundled KJV text** — the Bible reader's full text ships locally as a
  JSON asset (`assets/bible/kjv.json`), not fetched from an API, so
  reading/search/reading-plan scheduling all work offline.
- **google_fonts** — Spectral (serif, for scripture/headings) and Manrope
  (sans, for UI chrome), matching the original design system.
- **qr_flutter / mobile_scanner** — generates and scans the Companion
  invite QR code (real camera scanning, not a placeholder icon).

## Project structure

```
lib/
  core/          theme (colors/typography), router, Supabase client init, encryption
  data/
    bible/       bundled KJV text + reading-plan day-schedule generation
    devotional/  local devotional content + date-based daily rotation
    models/      plain Dart data classes
    repositories/  Supabase CRUD per feature (auth, journal, requests, profile,
                    bible notes, challenges, companion, fasting, focus, insights,
                    reading plans)
    static/      reference content (guide categories, challenge catalog, ...)
  state/         Riverpod providers wiring repositories to the UI
  features/      one folder per screen/flow (home, journal, streak, focus, companion, ...)
  widgets/       shared design-system components (PgButton, PgCard, PgPill,
                  PgHeader, PgTextField, PgFormError, ...)
supabase/
  migrations/    SQL schema + RLS policies
```

## Getting started

```
flutter pub get
cp .env.example .env   # fill in your Supabase project URL + anon key
flutter run
```

Full setup — applying the Supabase schema and migrations, enabling
Google/Apple auth — is in **[SETUP.md](SETUP.md)**.

## What's real vs. UI-only

Nearly everything is wired to Supabase now — auth, Journal, Prayer
Requests (with companion sharing), Profile/Settings, Prayer Streak, Bible
reader/notes/plans/devotional, Growth Insights, Fasting, Focus Mode session
logging, Challenges, Companion/Invite, Guide Library, Notifications,
Groups, and Prayer Together (live, via Supabase Realtime Presence).

What's left as UI-only: Audio Prayer Room (needs WebRTC/SFU) and the
Upgrade/paywall screen (needs RevenueCat or native store billing). Focus
Mode's actual app-*blocking* also needs platform entitlements (iOS Screen
Time, Android Accessibility Service — both common store-rejection causes)
beyond this codebase.

See **[SETUP.md](SETUP.md)** for the full, maintained breakdown of what's
real vs. not, and why.

## Design origin

The visual system and product spec came out of a Claude Design session:

- `project/PrayerGuide.dc.html` + `project/support.js` — the original
  interactive HTML/CSS/JS prototype (colors, typography, spacing, all copy).
- `project/uploads/PrayerGuide_PRD_v2_1.md` — the product requirements doc
  driving scope across all 4 phases.
- `chats/chat1.md` — the design conversation, showing how the prototype
  evolved and where specific decisions (streak framing, monetization split,
  focus mode constraints) came from.

Kept in the repo for reference — nothing in `lib/` depends on them.
