# Tennis IQ

A tennis brain game: official court and scoring knowledge, history, slams, lingo, and first-strike strategy.

This repo is the working product for the side project.

## What you have

| Path | What it is |
|---|---|
| `docs/TENNIS_IQ_LIBRARY.md` | Source-of-truth fact library (ITF dimensions, scoring, history, records, tactics) |
| `TennisIQ/Resources/questions.json` | 96-question bank with explanations |
| `TennisIQ/` | Native **SwiftUI iOS** app source |
| `web/` | Playable iPhone-first PWA you can ship today |
| `scripts/build_questions.py` | Regenerates the JSON if you add balls |

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

Apple will not let an agent submit under your account. You ship it from a Mac.

1. On a Mac with Xcode 16+:
   - File → New → Project → **App**
   - Product Name: `TennisIQ`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Bundle ID: `com.srqtennis.TennisIQ` (change to your team domain)
2. Delete the stub `ContentView.swift`.
3. Add every file under `TennisIQ/` to the target.
4. Add `TennisIQ/Resources/questions.json` to the target (Target Membership checked, type: Default).
5. Set iOS deployment to 17.0+.
6. Display name: `Tennis IQ`.
7. Run on a simulator or your phone.

App Store checklist:

- Apple Developer Program ($99/year)
- App icon 1024×1024, no transparency, no rounded corners in the file
- Privacy Nutrition Label: this v1 stores scores only on-device — no account, no tracking
- Screenshots for 6.7" and 6.1" iPhones
- Review notes: Trivia game. All content original quiz copy based on public ITF rules and published tennis records.
- Age rating: 4+
- Then Archive → Distribute → TestFlight → App Store Connect

## Editorial rules for new questions

- Rules and measurements: follow the current ITF Rules of Tennis.
- Records: name the era (Open Era vs all-time) and avoid weekly ranking trivia that goes stale in seven days.
- Every item needs a real explanation. The product is the explanation, not the points.
- Difficulties: `rookie` / `club` / `tour`.

## Honest scope

v1 is a sharp quiz with a real knowledge library. It is not Hawk-Eye, not a swing analyser, and not live scores. Next useful layers if you want them: daily seed so everyone gets the same 10, Game Center leaderboards, a court-diagram question type, and a Watch glance for rule of the day.
