# StoreKit and progression UI validation

Final acceptance passed on iPhone 18 Pro Max and iPad Pro 13-inch (M5), both using iOS 27 simulators. Tests exercise the shipping UI with Apple's local StoreKit environment. No fake app-side entitlement flags are used; all runs are serial.

## Latest acceptance

- My IQ and Challenge are gated while unowned. Daily Rally remains playable and its completed round is saved before purchase; My IQ shows that progress and the earned First Round badge after purchase.
- A full 30-question placement completes. The result shows a nonprovisional knowledge rating, the rendered share card, and the result's correct count/accuracy. The system image share popover opens and is dismissed without sending anything. Rating and distinct-question count survive relaunch.
- Challenge creation produces a valid link and preview. Starting it shows the same first question. Opening its URL through `XCUIApplication.open` while unowned shows the paywall; buying preserves the pending link and opens the same question. Invalid pasted links show a friendly error and no Play action.
- Actual nonconsumable purchase, access after relaunch, Restore Purchases, refund revocation, and continued free Daily Rally access passed again on iPhone.
- Final visual smoke passes on both devices: free home/gameplay/explanation, $9.99 paywall, purchased home, Library, and Practice. The final Challenge captures use the compact three-line URL field.

The iPad evidence starts with ten distinct questions and a provisional rating, then shows completed placement and nonprovisional status. Tests intentionally retain local progress between app launches; StoreKit ownership is cleared at each test setup.

| Final evidence | Outcome | Result bundle |
| --- | --- | --- |
| iPhone placement/share/persistence | 1 passed, 0 failed | `Placement-Share-iPhone-Final.xcresult` |
| iPhone compact Challenge + locked inbound purchase | 1 passed, 0 failed | `Challenge-iPhone-Final.xcresult` |
| iPad progression + Challenge + visual smoke | 3 passed, 0 failed | `Progression-iPad-Final.xcresult` |
| iPhone purchase/refund + visual smoke regression | Both passed | `Progression-Final-iPhone.xcresult` |

The last listed four-test bundle had three passes and one share-dismissal test failure: this OS exposes a popover dismiss region instead of a Close button. That assumption was corrected and the full placement/share/persistence case passed in its final bundle above. Earlier runs also exposed a real placement navigation issue, which was fixed before final acceptance. Failed exploratory bundles are retained as debugging history; they are not final acceptance results. Matching `*-summary.json` files preserve the machine-readable outcomes.

## Earlier baseline evidence

Before progression features, `StoreKit-iPhone-Final.xcresult` passed seven behavioral tests: free Daily Rally completion, all original premium gates and empty restore, cancellation, network failure with successful retry, Ask to Buy pending/approval, purchase/persistence/restore/refund, and Shot Clock expiration while backgrounded. The earlier iPhone/iPad screenshot smoke tests also passed. Cancellation, pending approval, network failure, and timer cases were not rerun after progression was added; the latest targeted regression covered purchase/refund and free play.

## Screenshots

Current acceptance screenshots are in `screenshots/progression-iphone/` (21 PNGs, 1320×2868) and `screenshots/progression-ipad/` (17 PNGs, 2064×2752). Each folder includes `metadata.json` identifying source bundle, individual test, device, capture timestamp, dimensions, SHA-256, and passing individual-test outcome. These are unedited simulator captures. The older `screenshots/iphone/` and `screenshots/ipad/` folders are baseline images and should not be used for the new feature presentation.

Both current folders contain these key files:

- `release-01-free-home.png`
- `release-04-paywall.png`
- `progress-01-saved-free-round.png`
- `progress-02-placement-share-card.png`
- `progress-03-system-share-sheet.png`
- `progress-04-completed-placement.png`
- `challenge-01-created-link.png`
- `challenge-02-locked-inbound-link.png`
- `challenge-02-opened-deep-link.png`
- `challenge-03-invalid-link.png`

Visual inspection confirmed readable card text, correct mode and /100 rating labels, usable compact Challenge links, and no clipping of the inspected home, paywall, progress, result card, Library, or Practice content. Share sheets were opened only for verification and dismissed; no messages were sent.

## Configuration and scope

Product `com.srqtennis.TennisIQ.fullunlock` is a $9.99 US nonconsumable. Canonical and test-bundle catalogs are byte-identical, with current SHA-256 `ffce91427bcbf107a8cd216f4e90b657612f93f7ef2535b981644c47205d95c3`. The current name is Full Game Unlock and its description is 42 characters. The earlier baseline used the previous catalog copy; product ID, price, and nonconsumable type did not change.

There are ten unique UI test methods in `TennisIQUITests/TennisIQStoreKitUITests.swift`. This evidence establishes local simulator/StoreKit behavior, not App Store Connect product availability, real-account sandbox behavior, signed device distribution, production purchases, or third-party receipt of a shared card. Full challenge ordering and progression algorithms are covered by the separate engine/codec tests; UI tests compare the displayed first question.

## Repeat

```sh
xcodebuild test -project TennisIQ.xcodeproj -scheme TennisIQ -destination 'platform=iOS Simulator,id=5C429BEC-AF57-45BD-834B-D4B6940EFE3F' -derivedDataPath DerivedData/StoreKitUITests -parallel-testing-enabled NO -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO
```

Use iPad destination `FEEF4993-DD19-4D0D-95E8-15C2B280DAFA` for that device. Add `-only-testing:TennisIQUITests/TennisIQStoreKitUITests/<method>` to run a targeted case. Screenshot smoke method: `testReleaseScreenshots`. Feature methods: `testNewProgressPlacementShareAndPersistence` and `testNewChallengeCreateInvalidPasteAndDeepLink`.
