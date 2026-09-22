# Tennis IQ — Growth Roadmap

**Date:** 2026-09-22
**Status:** Proposed, prioritized
**Companion plan:** `2026-09-22-v1.1-game-center-review-prompt-plan.md` (detailed implementation plan for P1)

---

## How to read this

Each phase has a **goal** (the business outcome), **success metric**, and **effort**. Phases are ordered by expected return on effort. Later phases assume earlier ones shipped. Marketing track runs in parallel and costs no app code.

---

## P0 — Ship it (this week, no code)

**Goal:** The app is currently unsellable because it is not on the App Store. Everything else is noise until v1.0 is live.

- Enroll in the Apple Developer Program ($99/yr).
- Register bundle ID `com.srqtennis.TennisIQ`, create the app record and the nonconsumable `com.srqtennis.TennisIQ.fullunlock` at $9.99.
- Accept Paid Apps agreements, complete tax/banking.
- Signed archive via `scripts/archive-for-upload.sh ACTUAL_TEAM_ID`, validate with `scripts/check-release.py`.
- Live sandbox purchase tests, then submit.

**Success metric:** v1.0 approved and live.
**Effort:** ~1 day of account/admin work. All steps documented in `release/APP_STORE_LISTING.md`, `release/READINESS.md`, `release/ACCOUNT_HANDOFF.md`.

---

## P1 — Competition & reviews (v1.1, ~2–3 days of code)

**Goal:** Give players a reason to come back daily and give the store listing social proof. A solitary local score does not sell a quiz game; competition does.

1. **Game Center integration** — leaderboards (best Daily Rally score, best Shot Clock score) and achievements mirroring the six local badges. Free players submit rally scores and earn achievements too: competition is the top-of-funnel.
2. **Review prompt** — ask for an App Store review at a feel-good moment (new personal best, a perfect round, or the 3rd completed round), at most once per app version.

**Success metric:** Game Center dashboard opens per DAU; review count growth after v1.1 ships.
**Effort:** Small. Full task-by-task plan in the companion plan doc.
**App Store Connect work:** Enable Game Center on the app ID, create 2 leaderboards + 6 achievements (IDs in the plan), update keywords and review notes.

---

## P2 — Conversion (v1.2, ~1 week)

**Goal:** More of the free Daily Rally players who love the game pay for it.

1. **Pricing test.** $9.99 one-time is premium pricing for an unknown indie trivia app. Test $4.99–$5.99, or tier it: Shot Clock $1.99, Practice $2.99, Full Unlock $6.99 as the anchor. Decide with real funnel numbers, not taste.
2. **Tease My IQ in the free tier.** Let free players complete the 30-question placement once and *show them their IQ and label* ("Your Tennis IQ: 62 — Building"), then gate tracking, badges, and re-placement. A tasted identity converts better than a lock icon.
3. **One free challenge round per day.** Challenge links are the best growth loop, but both-players-must-own kills it. A limited free tier pulls buyers in.
4. **App Store link on share cards.** Verified gap: result cards and challenge shares currently contain no download link. Every shared card should be a funnel.

**Success metric:** Install → paywall view → purchase conversion; share-to-install rate.
**Depends on:** Privacy-friendly analytics (see P3 #3) — you cannot judge a pricing test without funnel numbers, so pull TelemetryDeck (or equivalent) into v1.2.

---

## P3 — Retention & repeat revenue (v1.3, ~1–2 weeks)

**Goal:** Make Daily Rally a habit and give existing buyers a reason to spend again.

1. **Streaks + daily local notification.** "Daily Rally" begs for a streak counter and a gentle reminder. Purely local, no server.
2. **Seasonal question packs.** Questions like "through the 2026 US Open" age. Ship a new pack per slam/season (cheap consumable IAP or free update). Gives you a "What's New" story every few months, which matters for store featuring.
3. **Analytics.** Privacy-light (TelemetryDeck is the standard Apple-friendly choice). Minimum events: round started/completed, paywall shown/purchased, challenge sent/opened. Update App Store privacy answers accordingly.
4. **Localization scoping.** Spanish, French, German, Japanese are large tennis markets. The bank is English-only today; this is a content project as much as a code project.

**Success metric:** DAU retention curve; pack attach rate; revenue per paying user.

---

## Marketing track (parallel, ongoing, no app code)

1. **SRQ Tennis distribution (highest ROI).** You are a coach with students, parents, and adult clients. Get the app on every student's phone at the next lesson. First 100 downloads should come from people who already trust you.
2. **Share cards as content.** Post one tricky rules question from the bank weekly ("Did you know…?") on Instagram/TikTok with the app name. The 1,584-question audited bank is a content goldmine.
3. **SEO on srq.tennis.** Target evergreen rules searches ("tennis tiebreak rules 2026", "what is a let in tennis") ending in "test yourself in Tennis IQ." Links to the app store listing.
4. **App Store assets.** Preview video, screenshots refreshed after v1.1 (show a leaderboard).

---

## Explicit non-goals for now

- **Tour Pass / captain-funded rooms / online leaderboards** — server product, needs a real club pilot. Stays in `docs/PRODUCT_OWNERSHIP.md`.
- **Subscriptions** — the one-time unlock is the v1 model. Revisit after v1.3 with data.
- **Android** — no current plan; web PWA at `web/` is the cross-platform experiment if wanted.
- **Rerunning `scripts/build_questions.py`** — do not regenerate the audited bank without reapplying corrections (see HANDOFF.md).

---

## Sequencing summary

| Phase | Ships | Effort | Metric |
|---|---|---|---|
| P0 | v1.0 live on App Store | 1 day admin | Approved & live |
| P1 | v1.1 Game Center + review prompt | 2–3 days code | Retention, reviews |
| P2 | v1.2 conversion + analytics | ~1 week | Purchase conversion |
| P3 | v1.3 streaks + packs + localization scoping | 1–2 weeks | DAU, repeat revenue |
| Track | Marketing, ongoing | Hours/week | Downloads |
