# Prayer Guide – Product Requirements Document (v2)

**Product Type:** Mobile Application (iOS & Android)
**Target Audience:** Christians building a consistent prayer life, individually or with others
**Focus of this version:** Reworked around achievable scope, real platform constraints, and clear phase gates.

---

## 1. Product Vision

Prayer Guide helps Christians develop a consistent, Scripture-centered prayer life. It combines guided prayer, Bible reading, journaling, and accountability into one daily spiritual companion.

The goal is long-term habit formation, not feature volume. Every phase must ship something a user can rely on daily before the next layer is added.

---

## 2. Problem Statement

Many Christians struggle with inconsistent prayer habits, not knowing what to pray about, lack of accountability, difficulty combining Bible study with prayer, distractions, forgotten prayer requests, and the absence of a structured routine.

Prayer Guide addresses these through guidance, reminders, accountability, and focus tools.

---

## 3. Scope Principles

Three rules govern what makes it into each phase:

1. **Ship a usable habit loop first.** The MVP must let one person pray daily and come back tomorrow. Everything else is additive.
2. **Name blockers before building.** Content licensing and OS-level permissions are resolved in the phase *before* the feature that needs them.
3. **Cut anything with an unresolved dependency.** If a feature depends on a license, entitlement, or third-party term we do not yet have, it moves to a later phase.

---

## 4. Key Constraints (Resolve Early)

These shape the roadmap and must be investigated during Phase 0 / Phase 1, not discovered mid-build.

**Bible text licensing.** Modern versions (ESV, NIV, NLT) require paid licenses or carry strict API terms. Public-domain versions (KJV, ASV, WEB) are safe by default. Start with public-domain text via API.Bible; treat licensed versions as a later, negotiated addition.

**Audio Bible.** Narration audio is separately copyrighted from the text and is a large, licensing-heavy undertaking. It is deferred out of the MVP.

**Worship playlists (Spotify / YouTube).** In-app playback is restricted by both platforms (Spotify requires their app and a premium account for full control; YouTube terms restrict background playback). Scope this as *deep-linking out* to the user's own playlists, not in-app playback.

**Focus Mode (app blocking).** iOS has no true third-party app blocking; it requires the Screen Time API (FamilyControls / ManagedSettings) plus a special Apple entitlement you must apply for. Android requires an Accessibility Service or UsageStatsManager with a Play Store disclosure. Both are common causes of store rejection. Resolve entitlement/permission approval before committing this to a release.

**Real-time sync (Prayer Together).** Live shared sessions need a real-time backend (Supabase Realtime). This is an architecture decision to lock in before Phase 2.

**Sensitive personal data.** Journals and prayer requests are personal, sometimes health-related data (healing, deliverance). A privacy, retention, and encryption policy is required from Phase 1, not bolted on later.

---

## 5. Phase 1 — MVP (The Habit Loop)

The smallest release that stands on its own. A single user can pray daily, know what to pray, capture requests, and be reminded to return.

**5.1 Authentication**
Email sign-up, Google login, Apple login, password reset, basic profile management. (Supabase Auth.)

**5.2 Daily Prayer Guide**
Guided prayer sessions by time of day (Morning, Evening) and a core set of categories at launch: Thanksgiving, Worship, Repentance, Family, Healing, Spiritual Growth. Each session includes Scriptures (public-domain), prayer points, a reflection, and a suggested duration. Remaining categories added incrementally.

**5.3 Prayer Timer**
Presets (5 / 10 / 15 / 30 / 60 min) and custom. Optional ambience (a small starting set: Rain, Ocean, Instrumental). A completed session is what feeds the streak.

**5.4 Scripture of the Day**
Daily verse with a short explanation, prayer focus, and reflection question.

**5.5 Prayer Journal**
Private entries: prayer requests, gratitude, testimonies, reflections. Encrypted at rest.

**5.6 Prayer Request Manager**
Add requests, categorize, set reminders, mark answered, archive.

**5.7 Prayer Streak** *(see detailed spec in §8)*
Consecutive-day tracking tied to completed sessions, with milestones and a monthly streak freeze. Framed gently.

**5.8 Smart Notifications**
Reminders for prayer, devotional, and streak protection. Local notifications via FCM.

**5.9 Basic Bible Reader (text only)**
Public-domain version(s), read-along text, bookmarks, highlights, notes. *No audio in MVP.*

**Deferred out of MVP:** Audio Bible, Reading Plans, worship playlists. These become fast-follows once the habit loop is proven.

---

## 6. Phase 2 — Depth & Accountability

Adds the companion layer and the content that deepens daily use.

- **Audio Bible** (once narration licensing is secured): multiple versions, offline downloads, continue listening, read-along.
- **Bible Reading Plans:** Bible in 90 Days, One Year, New Testament, Psalms/Proverbs challenges, with progress tracking.
- **Daily Devotional:** scripture, message, reflection, prayer.
- **Prayer Companion:** invite via username/email/link/QR; shared schedules with synced reminders; shared prayer requests; shared goals.
- **Accountability check-ins:** Prayed / Later / Missed, visible to companion.
- **Shared Streaks:** consecutive days and challenges tracked between companions.
- **Prayer Challenges:** 7-day, 21-day fasting, 30-day revival, 40-day growth, with progress tracking.
- **Fasting Companion:** track fast duration, sessions, reading, notes.
- **Focus Mode** *(see detailed spec in §7)* — only if entitlement/permissions are approved.

---

## 7. Phase 3 — Live & Community

Higher-complexity, real-time and multi-user features.

- **Prayer Together Mode:** synced timer, shared points/scriptures, live session indicator (requires Supabase Realtime).
- **Prayer Groups, Family Prayer, Church Accounts.**
- **Live Prayer Rooms / Audio Prayer Rooms** (requires content moderation).
- **Group and Church Challenges.**
- **Prayer Events.**

Community features require a content moderation plan before launch.

---

## 8. Phase 4 — Intelligence

- AI Prayer Assistant and prayer suggestions
- Scripture recommendations and prayer topic generator
- Bible Q&A
- AI devotional summaries
- Personalized spiritual growth insights
- Predictive reminder optimization

---

## 9. Feature Specs (New)

### 7 · Focus Mode (App Blocker)

Blocks distracting apps during an active prayer or reading session so the user stays present.

**Platform reality:**
- **iOS:** Screen Time API (FamilyControls / ManagedSettings / DeviceActivity). Requires a special Apple entitlement (apply early). Blocking is OS-enforced; the app selects apps to shield for the session.
- **Android:** Accessibility Service or UsageStatsManager plus an overlay screen, with a required Play Store permissions disclosure.

**Behavior:**
- Toggle on when starting a Prayer Timer session.
- User picks apps to block or a preset (e.g. Social, Games).
- Two modes: **Full block** (premium) and **Gentle mode** (free) — a reminder overlay: *"You're in prayer. Return when ready."*
- Auto-disables when the session ends.
- Emergency bypass (calls, messages) always allowed.

**Risk:** entitlement and permission approval are the top store-rejection causes. Gate this behind Phase 2 and confirm approval before committing to a release date.

### 8 · Prayer Streak

Tracks consecutive days of completed prayer to build momentum.

**Rules:**
- A day counts when the user completes a qualifying session (define minimum, e.g. 3+ minutes on the timer or a completed guided session).
- Resets at local midnight if no qualifying session.
- **Streak Freeze:** 1 free per month to protect a missed day (premium gets more).
- **Grace window:** optional recovery if a session is completed before a set time the next morning.
- **Milestones:** 7, 21, 30, 40, 100, 365 days, with badges.
- **Streak calendar:** shows active, missed, and frozen days.
- Ties into notifications ("Don't break your 12-day streak") and shared streaks with a companion.

**Design caution:** streaks can create guilt around a spiritual practice, which works against the app's purpose. Use encouraging rather than punitive framing, and let users hide the streak count if it becomes a source of anxiety.

---

## 10. Monetization

**Free:** Prayer Guide, Timer, Journal, Scripture of the Day, basic text Bible, one Prayer Companion, Gentle Focus Mode, basic streak.

**Premium:** Unlimited companions, offline Audio Bible, advanced analytics, AI assistant, premium devotionals, exclusive reading plans, full Focus Mode, extra streak freezes, church resources, priority support.

---

## 11. Success Metrics

**Engagement:** DAU, MAU, average daily prayer time, streak retention, reading completion rate.
**Community:** companion invitations, active pairs, shared sessions completed, challenges completed.
**Business:** premium conversion, MRR, renewal rate, CAC, LTV.

---

## 12. Suggested Tech Stack

- **Mobile:** Flutter (single codebase, iOS & Android)
- **Backend / Auth / Storage / DB:** Supabase (PostgreSQL, Supabase Auth, Supabase Storage, Realtime for Phase 3)
- **Notifications:** Firebase Cloud Messaging
- **Analytics / Crash:** Firebase Analytics, Crashlytics
- **Bible content:** API.Bible (public-domain versions first)
- **AI (Phase 4):** OpenAI or comparable LLM provider

---

## 13. Vision Statement

Prayer Guide exists to help Christians build a lifelong habit of prayer by combining Scripture, guided prayer, accountability, worship, and journaling into one beautifully designed mobile experience. Through personal devotion and shared spiritual journeys, it seeks to strengthen believers' relationship with God and with one another, making consistent prayer accessible, meaningful, and sustainable.
