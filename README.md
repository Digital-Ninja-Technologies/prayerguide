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
(`project/uploads/PrayerGuide_PRD_v2_1.md`) — 35 screens total:

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
- **Phase 4 — intelligence.** AI Prayer Assistant (Claude-backed), Growth
  Insights.

Not every screen is backed by live data yet — see
[What's real vs. UI-only](#whats-real-vs-ui-only).

## Stack

- **Flutter / Dart** — single codebase for iOS + Android.
- **flutter_riverpod** — app state (auth, profile, journal, requests).
- **go_router** — declarative routing; `StatefulShellRoute` drives the
  persistent bottom nav (Home / Bible / Journal / Streak / Profile).
- **Supabase** — Postgres + Auth (email/password, Google, Apple) + Edge
  Functions. Schema and RLS policies live in `supabase/migrations/`.
- **Client-side encryption** — journal entries and prayer request text are
  encrypted on-device (AES-256-GCM via the `cryptography` package) before
  they ever reach Supabase, with the key held in the platform
  Keychain/Keystore (`flutter_secure_storage`) and an opt-in
  passphrase-based recovery/escrow flow for new devices. See
  `lib/core/security/encryption_service.dart`.
- **Claude API** — the AI Prayer Assistant is proxied through a Supabase Edge
  Function (`supabase/functions/assistant-proxy`) so the API key never lives
  in the client.
- **google_fonts** — Spectral (serif, for scripture/headings) and Manrope
  (sans, for UI chrome), matching the original design system.

## Project structure

```
lib/
  core/          theme (colors/typography), router, Supabase client init, encryption
  data/
    models/      plain Dart data classes
    repositories/  Supabase CRUD per feature (auth, journal, requests, profile, assistant)
    static/      reference content (guide categories, challenges, reading plans, ...)
  state/         Riverpod providers wiring repositories to the UI
  features/      one folder per screen/flow (home, journal, streak, focus, companion, ...)
  widgets/       shared design-system components (PgButton, PgCard, PgPill, ...)
supabase/
  migrations/    SQL schema + RLS policies
  functions/     assistant-proxy Edge Function (Claude proxy)
```

## Getting started

```
flutter pub get
cp .env.example .env   # fill in your Supabase project URL + anon key
flutter run
```

Full setup — applying the Supabase schema, enabling Google/Apple auth,
deploying the Assistant proxy function — is in **[SETUP.md](SETUP.md)**.

## What's real vs. UI-only

**Wired to Supabase, persists across restarts:** auth, Journal, Prayer
Requests, Profile/Settings (theme, hide-streak), and the Prayer Streak (a DB
trigger recomputes it from logged prayer sessions).

**UI-complete, local/mock state for now:** Guide Library, Bible
reader/notes, Focus Mode, Companion/Invite, Challenges, Reading Plans,
Devotional, Fasting, Prayer Together/Groups/Audio Room, Growth Insights,
Upgrade (no real billing). Their tables already exist in the migration, so
wiring each one up follows the same repository + Riverpod-provider pattern
used for Journal and Requests.

**Needs platform/infra work beyond this codebase** (per the PRD's own risk
list): Focus Mode's actual app-blocking (iOS Screen Time entitlement,
Android Accessibility Service — both are common store-rejection causes),
Prayer Together's real-time sync (Supabase Realtime), Audio Prayer Rooms
(WebRTC + moderation), push notifications (Firebase), and in-app purchases
for Upgrade.

See `SETUP.md` for the full breakdown and exact next steps.

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
