# Store screenshots

Use the current native captures in `progression-iphone/` (21 PNGs, 1320×2868) and `progression-ipad/` (17 PNGs, 2064×2752). They show free Daily Rally, the permanent in-app unlock, My IQ, placement, result cards, and offline Challenge links. The older `iphone/`, `ipad/`, and `assets/app-store` captures are baseline material.

Suggested product-page order (these filenames exist in both current device folders):

1. `release-01-free-home.png`
2. `release-02-free-gameplay.png`
3. `release-03-answer-explanation.png`
4. `progress-04-completed-placement.png` — My IQ rating, distinct questions, and badges.
5. `progress-02-placement-share-card.png` — actual result and generated share card.
6. `challenge-01-created-link.png` — compact challenge link, Play, and Share controls.
7. `release-06-library.png`
8. `release-07-practice.png`

`release-04-paywall.png` is the in-app purchase review screenshot (local StoreKit US price $9.99). `release-05-unlocked-home.png` shows purchased access. My IQ, placement, result cards, Challenge, Library, and Practice require the permanent unlock; Daily Rally remains free.

Additional verification captures include `progress-03-system-share-sheet.png`, `challenge-02-locked-inbound-link.png`, `challenge-02-opened-deep-link.png`, and `challenge-03-invalid-link.png`. Sharing was opened and dismissed without sending anything.

These are unedited app screenshots from XCTest using Apple's local StoreKit environment. Each folder's `metadata.json` links every image to its passing individual test, result bundle, device, capture time, dimensions, and SHA-256. The captures do not establish live App Store Connect product availability. See `../STOREKIT-UI-VALIDATION.md` for final acceptance and baseline evidence.
