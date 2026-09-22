# Tennis IQ release readiness

The app is not yet upload-ready because Apple Developer enrollment and signing are unfinished.

## Verified locally

- Free Daily Rally; US $9.99 nonconsumable unlock for Shot Clock, Practice, Library, My IQ, placement, badges, result cards and friendly challenge links.
- Seven iPhone runtime tests passed with Apple's StoreKitTest: free completion, paid gates, empty restore, cancellation, purchase persistence, successful restore, refund/revocation, pending approval, failure/retry and timer expiration after backgrounding (some scenarios share a test).
- Current iPhone and iPad screenshot smoke tests passed. Thirty-eight captures and provenance metadata are under `release/screenshots/progression-iphone/` and `release/screenshots/progression-ipad/`; older capture folders are baseline evidence.
- Generic iOS Release archive `TennisIQ-Owned-Unsigned.xcarchive` and all 12 packaging checks pass, including the challenge URL scheme. The archive is intentionally unsigned and cannot be uploaded.
- Progression engine: 42 checks passed. Challenge codec: 31 assertions passed. Audited bank: 4 tests passed.
- iPhone and iPad runtime acceptance passed for free progress retention, placement completion, nonprovisional rating, badges, image sharing/dismissal and persistence. Challenge acceptance passed for matching questions, invalid links and purchase-gated inbound links. Compact link layout was verified on iPhone. See the current owned-feature UI report and screenshots for the final device evidence.
- App icon, privacy manifest and all 1,584 audited questions are packaged. No StoreKit test catalog or XCTest bundle ships inside the app.
- Public support and privacy pages are live at the dedicated srq.tennis paths, verified against source; existing website files and server function preserved.
- Store listing, IAP metadata, review notes, screenshot guidance and account handoff are prepared in `release/`.

## Remaining before upload/submission

1. Account holder enrolls in Apple Developer Program and signs into Xcode.
2. Configure the paid developer team; produce and validate a signed archive.
3. Create the App Store Connect app and nonconsumable; complete required agreements, tax/banking, availability, review contact, privacy and age-rating forms.
4. Verify the actual live product using Apple sandbox/TestFlight, including a real device and restore under the owning account. Local tests are not this evidence.
5. Attach final screenshots/build/IAP metadata and perform Apple validation. No upload or submission has occurred.

## Product decision

The permanent solo purchase will not become a subscription. Tour Pass is a later, optional US $9.99/year captain-focused hosting proposal, contingent on a real club pilot. No annual product or social backend is being shipped now. See `docs/PRODUCT_OWNERSHIP.md`.

## Evidence

- `release/STOREKIT-UI-VALIDATION.md`
- `release/Placement-Share-iPhone-Final.xcresult`
- `release/Challenge-iPhone-Final.xcresult`
- `release/Progression-iPad-Final.xcresult`
- `release/iphone-test-summary.json`
- `release/StoreKit-iPhone-Final.xcresult`
- `release/progression-archive-check.txt`
- `release/owned-feature-unit-validation.json`
- `release/website-deployment.json`
- `release/screenshots/`
- `release/ACCOUNT_HANDOFF.md`
