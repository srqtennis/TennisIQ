# Tennis IQ: start here

## Repository and current state

Continue from `codex/tennis-iq-single-use-codes` in `https://github.com/srqtennis/TennisIQ`, not the older `main` branch. This branch contains the native Xcode app, audited question bank, artwork, StoreKit integration, offline progression, tests, and release documentation. The branch name predates the current native scope.

Open `TennisIQ.xcodeproj`, select the shared TennisIQ scheme, choose an installed iPhone or iPad simulator and Run. Native deployment target: iOS 17+. Bundle ID: `com.srqtennis.TennisIQ`. The shared scheme uses the local StoreKit catalog for development; it does not create a live App Store product.

The native app is the release target. `web/` is an older separate PWA/payment-link implementation, not bundled in the native app. Do not mistake its commerce flow for native StoreKit behavior or replace native purchases with a web checkout.

## Product decisions to preserve

- Free download. Solo Daily Rally stays free forever and saves local progress before purchase.
- US $9.99 one-time nonconsumable `com.srqtennis.TennisIQ.fullunlock`. StoreKit supplies localized prices and verified ownership; restore and revocation are handled.
- Permanent unlock includes Shot Clock, Practice, Library, My IQ, placement, badges, result cards, and friendly challenge links. No recurring entitlement is needed for these features.
- Optional $9.99/year Tour Pass is a later proposal, not implemented or sold. Captain-funded rooms, server boards, synchronization and Tour seasons need a separate design and real club pilot. See `docs/PRODUCT_OWNERSHIP.md`.
- My IQ is a personal quiz-knowledge score, not psychological IQ or tennis playing ability. Last 100 distinct first attempts contribute to a smoothed 0–100 score; provisional until 30 distinct answers. Repeated familiar questions cannot increase it.
- Placement uses 30 questions, ten each Rookie/Club/Tour, preferring unseen questions. Completed rounds save progress; abandoned rounds do not.
- Six badges persist once earned. Local history retains the latest 20 rounds. Progress is local UserDefaults Codable data, not an account/sync service.
- Result cards use ImageRenderer and native user-initiated sharing. No automatic messaging.
- Challenges use `tennisiq://challenge#` links containing ten ordered question IDs plus bank version/content fingerprint. They require compatible bank content and the permanent unlock. They are friendly, unverified rounds; no leaderboard or anti-cheat claim. Fingerprints provide compatibility checks, not authentication.

## Important files

- `TennisIQ/Models/PurchaseStore.swift`: StoreKit 2 verified nonconsumable ownership.
- `TennisIQ/Models/Progression.swift`: pure local rating/badge engine.
- `TennisIQ/Models/Challenge.swift`: bounded challenge encoding/validation.
- `TennisIQ/Models/GameStore.swift`: bank loading, local persistence and placement deck.
- `TennisIQ/Views/RootView.swift`: navigation, ownership gates and inbound URLs.
- `TennisIQ/Views/QuizView.swift`: scoring, timer deadline, completion recording and results.
- `TennisIQ/Views/PlayerProgressView.swift`, `ResultShareView.swift`, `ChallengeView.swift`: new owned features.
- `Configuration/Info.plist`: explicit app plist, challenge URL scheme.
- `Configuration/TennisIQ.storekit` and `TennisIQUITests/TennisIQ.storekit`: keep byte-identical.

## Question bank: preserve the audit

Native `TennisIQ/Resources/questions.json` and `web/questions.json` are identical audited version 7, with 1,584 questions. See `docs/QUESTION_AUDIT.md`, `docs/audit/final-ledger.json`, correction reports and source evidence. 518 entries were corrected; 20 tactical items retain contextual judgments. Do not promise timeless or infallible tennis records.

Do not rerun the legacy `scripts/build_questions.py` over this bank without preserving/reapplying and verifying audited corrections. Keep native/web banks and bank version compatible when editing; old challenge links intentionally reject incompatible content.

## Verification

From the repository root:

```sh
swiftc TennisIQ/Models/Progression.swift tests/ProgressionTests.swift -o /tmp/tennisiq-progression-tests
/tmp/tennisiq-progression-tests
swiftc TennisIQ/Models/Question.swift TennisIQ/Models/Challenge.swift tests/ChallengeCodecTests.swift -o /tmp/tennisiq-challenge-tests
/tmp/tennisiq-challenge-tests
node --test tests/questions.test.cjs
xcodebuild -project TennisIQ.xcodeproj -scheme TennisIQ -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcrun simctl list devices available
```

Use an available simulator ID from that last command for UI tests:

```sh
xcodebuild test -project TennisIQ.xcodeproj -scheme TennisIQ -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_ID' -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

StoreKit UI tests must run serially. The suite uses actual local StoreKitTest transactions, not app-side unlock overrides. Pure progression: 42 checks; challenge codec: 31 assertions; bank: 4 tests passed at handoff. iPhone and iPad simulator progression/challenge acceptance passed. See `release/STOREKIT-UI-VALIDATION.md` for exact final versus baseline runs, resolved issues and coverage limits. JSON summaries and 38 current screenshots with provenance are committed under `release/`; raw xcresult bundles and build archives are generated local artifacts and intentionally ignored.

Current screenshots are `release/screenshots/progression-iphone/` and `progression-ipad/`. Older screenshot folders are baseline evidence, not current product presentation.

## Remaining App Store work

The app is not upload-ready. The owner said they need to enroll in the paid Apple Developer Program. No signing identity or live App Store Connect IAP was configured at handoff. See `release/READINESS.md`, `ACCOUNT_HANDOFF.md` and `APP_STORE_LISTING.md`.

Account-holder actions remain: enrollment, Xcode account/team, agreements and tax/banking, app/IAP creation, signed archive validation, real sandbox/TestFlight/device testing, metadata and submission. Local StoreKit tests and unsigned archives do not prove live commerce or upload readiness. Do not spend, accept legal agreements, invent account details, or claim upload/submission occurred.

`bash scripts/archive-for-upload.sh ACTUAL_TEAM_ID` creates/checks a signed archive once a real team is configured; it does not upload. `python3 scripts/check-release.py ARCHIVE_PATH` validates packaging/signing. `--allow-unsigned` is packaging evidence only.

## Public support/privacy pages

Live at `https://srq.tennis/tennis-iq/support/` and `/tennis-iq/privacy/`. Source is in `release/site/`; deployment preservation evidence is `release/website-deployment.json`. Support contact: michael@srq.tennis. The current pages disclose local progress and user-initiated sharing.

Only the two static pages were added/updated while preserving all other existing srq.tennis files and server function metadata. This repository is not the full deployed site. Do not deploy this repository as a replacement for srq.tennis or rebuild an unrelated stale local website. See `release/site/README.md` before any website change. No hosting credentials are stored here.
