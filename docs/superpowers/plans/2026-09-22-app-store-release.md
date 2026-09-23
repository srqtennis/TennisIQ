# Tennis IQ App Store Release Implementation Plan

**Goal:** Free native download with Daily Rally free forever and a single US $9.99 nonconsumable unlock for Shot Clock, Practice and the full library; prepare an upload-ready release.

**Architecture:** StoreKit 2 verified current entitlements are the sole unlock authority. The app routes premium features through a shared gate; Daily Rally remains usable without store connectivity. Scores stay local. Privacy/support content lives in the app and on srq.tennis.

**Tech Stack:** SwiftUI, StoreKit 2, XCTest/StoreKitTest, static HTML.

- [x] PurchaseStore.swift: load localized product; verified entitlements; transaction updates; purchase, cancellation, pending, failure, restore and revocation. Never trust a local paid flag.
- [x] PaywallView.swift: one-time purchase, localized price, always-free Daily Rally, restore and retry, close without buying.
- [x] HomeView/RootView/App: inject store, refresh on foreground, gate Shot Clock/Practice/Library and their destinations. Preserve free Daily Rally.
- [x] PracticeView.swift: category/difficulty selection, untimed practice using existing QuizConfig.
- [x] QuizView/GameStore: scrolling, explicit answer feedback, deadline timing, rally-only high score, idempotent completion.
- [x] PrivacyInfo.xcprivacy: no tracking/collection; UserDefaults CA92.1. Recheck purchase privacy text.
- [x] AboutView and release/site: support contact, privacy policy, purchase/restore help; publish only approved dedicated paths on srq.tennis.
- [x] StoreKit local config + UI tests: real simulated purchase, free/paid navigation, cancellation, restore, revocation, cold launch, screenshots.
- [ ] Release archive: generic iOS Release archive; inspect bundled icon, privacy manifest, bank and signing. Unsigned compile is not an upload-ready archive.
- [x] Listing package: exact description, subtitle, keywords, screenshots, IAP metadata, review instructions, privacy and age questionnaire guidance.
- [ ] Developer enrollment and App Store Connect configuration: user enrollment/payment; signed archive; live product/agreements/tax/banking; sandbox verification. These require the enrolled account and are not satisfied by local StoreKit tests.

Verification: xcodebuild build/archive/test, node --test tests/questions.test.cjs, inspect exported screenshots and bundle. Completion requires all steps above with evidence; do not label unsigned artifacts upload-ready.

Product boundary: `docs/PRODUCT_OWNERSHIP.md` records the later captain-funded Tour Pass proposal. It does not expand this submission to unbuilt social features or recurring billing.

Verified local evidence: seven iPhone StoreKit/gameplay tests passed in `release/StoreKit-iPhone-Final.xcresult`; package checks passed in `release/archive-check.txt`. Archive is unsigned; account-dependent gates remain open.
