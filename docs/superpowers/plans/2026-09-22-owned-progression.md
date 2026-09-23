# Owned progression implementation plan

Goal: implement native local knowledge rating/placement, persistent earned badges, shareable result cards and serverless same-question challenges as owned functionality. Daily Rally remains free; no Tour Pass or account/server dependency.

Design:
- Progression uses first attempts at distinct questions; last100 first attempts feed smoothed0–100 knowledge score. First30distinctquestions provisional. It is not psychological IQ or a tennis playing rating.
- Placement is a30question balanced Rookie/Club/Tour round, preferring unseen questions. Everyday completed rounds also contribute first attempts. Abandoned rounds do not record results.
- Six achievable badges with permanent unlocks. Persist summary/progression as Codable local UserDefaults; record each roundUUIDonce.
- Owned Progress screen shows rating/status, evidencecount, badges and placement. Free Daily Rally can earn progress before purchase; viewing the premium progression tools requires permanent unlock.
- Every completed owned round can share a square branded scorecard through native share sheet. No automatic messaging.
- Challenge links use tennisiq://challenge#base64urlJSON with10orderedquestionIDs,bankversion andcontentfingerprint. Strict bounded decoding; mismatched banks rejected with readableerror. Ownership gate applies to challengeplay; importedlinkpreview confirms beforestart. Linkcontains noidentity oranswers and needs no server. Friendly/unverified results disclosed.
- Challenge rounds use exactlinkorder; sharecurrent10questionround or createfresh10. Inbound URLs reach Challenge screen, preservinggate. No universal-link/server promise.

Files: new Models/Progression.swift, Models/Challenge.swift; new Views/ProgressView.swift (named PlayerProgressView to avoid SwiftUI collision), PlacementView.swift, ChallengeView.swift, ResultShareView.swift; integrate GameStore, QuizView, HomeView, RootView, AboutView, PaywallView and project URLscheme.

Verification: pure engine/codec tests; build; real UI owned/free gates, placementcompletion/progression,badges,cardrender, valid/invalidchallenge import andmatchingorder, persistence. Refresh release archive, publicsupport text and screenshots after tests. Retain enrollment/liveStoreKit blockers.

## Implementation outcome

Implemented the owned local features and ownership gates. Pure progression checks (42), challenge codec assertions (31) and audited bank tests (4) passed. iPhone and iPad exercised placement, persistent progress/badges, native image sharing, generated and inbound challenge links, invalid-link rejection and purchase gating. Fixed placement navigation to use a direct destination and limited long challenge input to three visible lines. Updated native/public privacy and support copy and preserved the existing srq.tennis site. The latest unsigned release archive is `release/TennisIQ-Owned-Unsigned.xcarchive`; all 12 packaging checks passed. Apple enrollment, signing and real App Store Connect product validation remain separate release blockers.
