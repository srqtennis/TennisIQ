# Apple account steps

The source and an unsigned archive can be prepared before enrollment. An unsigned archive cannot be uploaded. These steps require the account holder.

1. Enroll at https://developer.apple.com/programs/enroll/ using the Apple Account that will own Tennis IQ. Decide individual versus organization using your actual legal entity. Apple may require identity verification; organization enrollment can require business verification. Complete enrollment and its membership fee directly with Apple.
2. In Xcode Settings → Accounts, sign in to that account. Select its paid team under TennisIQ → Signing & Capabilities. Keep automatic signing enabled. Register `com.srqtennis.TennisIQ` or resolve any identifier conflict before proceeding.
3. In App Store Connect, complete required agreements, including the Paid Apps agreement for IAP; supply applicable tax and banking details directly. Set the app itself to Free.
4. Create Tennis IQ for iOS using the same bundle ID. Use `release/APP_STORE_LISTING.md` for copy and review notes. Fill the current privacy and age-rating forms, review territories and applicable trader declarations, and supply the account holder's current review contact.
5. Create a Non-Consumable product with exact ID `com.srqtennis.TennisIQ.fullunlock`. Set the U.S. base price to $9.99 and review local equivalents. Add its title, description and purchase-screen review screenshot. This is a one-time unlock, not a subscription.
6. Build a signed archive using Xcode Product → Archive or `bash scripts/archive-for-upload.sh YOUR_ACTUAL_TEAM_ID`. The script validates its argument, creates a timestamped archive and runs packaging/signing checks. It does not upload. In Organizer, run Validate App and address all findings.
7. Upload the validated archive to App Store Connect for TestFlight. Test using Apple's sandbox against the real configured product: free access, purchase, cancel, pending approval, restore on a second installation, offline existing ownership and refund/revocation. Local StoreKit tests do not replace this verification.
8. Select the processed build for version 1.0. Attach the first in-app purchase to this version, complete all metadata and screenshots, and submit only when ready. Manual release after approval gives you control of the launch.

No credentials, payment details or tax information should be placed in this repository or sent in chat. Enrollment, signed archive validation, live product configuration and live sandbox evidence remain required even when local tests pass.
