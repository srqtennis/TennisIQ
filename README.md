# Tennis IQ

A tennis brain game: official court and scoring knowledge, history, slams, lingo, and first-strike strategy.

This repo is the working product for the side project.

**Continuing work? Read [HANDOFF.md](HANDOFF.md) first** for current scope, verification, ownership decisions and App Store blockers.

## What you have

| Path | What it is |
|---|---|
| `docs/TENNIS_IQ_LIBRARY.md` | Editorial reference; use `docs/QUESTION_AUDIT.md` for the shipped bank audit |
| `TennisIQ/Resources/questions.json` | 1,584-question audited bank with explanations |
| `TennisIQ/` | Native **SwiftUI iOS** app source |
| `web/` | Playable iPhone-first PWA you can ship today |
| `scripts/build_questions.py` | Legacy generator; do not rerun over the audited bank without reapplying and verifying corrections |

## Play it on iPhone tonight

1. Host the `web/` folder (GitHub Pages, Netlify, or `python3 -m http.server` on the same Wi-Fi).
2. Open the URL in Safari on the iPhone.
3. Share → **Add to Home Screen**.
4. It launches full-screen like an app.

Modes:

- **Daily Rally** — 10 mixed questions
- **Shot Clock** — 20 seconds per ball
- **Practice / Library** — filter by Court, Scoring, Rules, History, Slams, Lingo, Strategy, Tour

## Native iOS app (Xcode → TestFlight → App Store)

A paid Apple Developer membership and a configured signing team are required for an upload-ready archive.

1. Open `TennisIQ.xcodeproj` in Xcode.
2. Select the **TennisIQ** scheme and an iPhone simulator, then click Run.
3. If no simulator is available, install an iOS runtime in Xcode Settings → Components.
4. To run on your iPhone, select your Apple developer team under Signing & Capabilities, connect your phone, and select it as the run destination.

The project targets iOS 17+, uses bundle ID `com.srqtennis.TennisIQ`, and displays as **Tennis IQ**. It includes the native app sources and `TennisIQ/Resources/questions.json`. The web app and server files are not bundled into the native app.

Native release model:

- Free download; Daily Rally is free forever.
- One nonconsumable in-app purchase unlocks Shot Clock, Practice, the full Library, My IQ, placement, badges, result cards and friendly challenge links.
- Product: `com.srqtennis.TennisIQ.fullunlock`; U.S. base price $9.99. StoreKit supplies the localized price and verified ownership.
- Restore Purchases is available in the paywall and About screen.
- Local StoreKit catalog: `Configuration/TennisIQ.storekit`; this does not configure the live product.
- App icon and privacy manifest are included. Scores, first-attempt knowledge rating and badges stay local; Apple handles purchases.
- Complete current age-rating and privacy questionnaires in App Store Connect.
- Release metadata and account checklist: `release/APP_STORE_LISTING.md`.
- Run UI tests with the shared TennisIQ scheme to exercise real local StoreKit transactions.
- Inspect a signed archive with `python3 scripts/check-release.py <archive>`. `--allow-unsigned` checks packaging only and does not prove upload readiness.

## Editorial rules for new questions

- Rules and measurements: follow the current ITF Rules of Tennis.
- Records: name the era (Open Era vs all-time) and avoid weekly ranking trivia that goes stale in seven days.
- Every item needs a real explanation. The product is the explanation, not the points.
- Difficulties: `rookie` / `club` / `tour`.

## Honest scope

The native app includes personal quiz-knowledge progression and unverified friendly challenges. It does not measure tennis playing ability or offer live scores or online leaderboards. Tour Pass and captain-funded club rooms are a later proposal, described in `docs/PRODUCT_OWNERSHIP.md`.
