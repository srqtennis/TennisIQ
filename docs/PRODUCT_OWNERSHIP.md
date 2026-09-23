# Tennis IQ ownership and Tour Pass

This product decision preserves the current release plan. Tour Pass is a later service, not a replacement for the permanent unlock.

## Shipping first

- Free download, with solo Daily Rally free forever. This is more generous than requiring purchase for Daily Rally and preserves the current promise.
- US $9.99 once for the native Full Game Unlock, product `com.srqtennis.TennisIQ.fullunlock` (nonconsumable).
- The native unlock includes Shot Clock, Practice, the full Library/question bank with explanations, My IQ, placement, badges, result cards and friendly challenge links. Progress stays local.
- No recurring payment is required to retain purchased solo features. A refunded or revoked purchase is handled through Apple's verified ownership.
- The native app currently has no Tour Pass product, subscription paywall, club backend or recurring billing.

## Owned feature boundary

If it works on one phone without a service, it belongs to the permanent purchase. This includes the existing bank, Code explanations and offline modes, plus:

- Placement and a local IQ rating.
- Badges and result/share cards.
- Challenge links carrying ten question IDs and a bank compatibility fingerprint.

The native app implements these owned features. The 0–100 rating measures personal quiz knowledge from up to 100 first attempts at distinct questions; it is provisional until 30 distinct answers. It is not a psychological IQ or tennis playing rating. Repeated questions cannot farm the rating. Badges persist once earned. Free Daily Rally records progress before purchase, so unlocking reveals existing progress. Challenge links require matching bank content and are friendly, unverified rounds with no server leaderboard.

Never move old questions, explanations or previously purchased solo functionality behind a subscription. Daily Rally remains free even without the permanent unlock.

## Tour Pass: later pilot proposal

US $9.99 per year, optional. No monthly plan. Separate entitlement from the permanent unlock.

Candidate service features:

- Hosting club rooms and weekly ladders.
- Server challenge codes, verified results and rematch history.
- City/section boards and Tour seasons.
- Captain tools for room membership, sit-outs and weekly resets.
- Cross-device rating synchronization and current Tour sets.

Launch only after one real club is using a working room and the hosting/support costs are measured. The annual price is a product target, not evidence that the service will cover its costs. Do not sell or advertise a subscription for unavailable functionality.

## Captain-funded rooms

Recommended interpretation of the user's model: the captain needs an active Tour Pass to host a room; players who own Tennis IQ may join, compete and appear on that funded room's board without individual subscriptions. The room must not require eight separate passes for eight owners.

Accordingly, 'appearing on a club board' is covered by the captain's active room entitlement, not a mandatory player subscription. Any later individual city-board or synchronization offering needs its own explicit scope before implementation.

If a host's pass expires, preserve every member's owned app and local progress. Stop paid hosting/new weekly activity, preserve access to historical results, and allow renewal or transfer to another paid captain. Define retention and export limits before opening the service.

Proposed content-retention rule to settle during the pilot: questions and explanations already granted in a Tour pack remain available locally; an active pass is for receiving the next season and participating in live competition. Do not retroactively rent old questions.

## Messaging

Current release:

“Daily Rally is free forever. Unlock the full solo game, Library, knowledge rating, badges and friendly challenges with one purchase. No subscription required.”

Once the service exists:

“Tennis IQ — $9.99 once for the solo game. Tour Pass — $9.99/year for captains hosting clubs and new seasons. Skip the pass and the app you bought still works.”

Display localized StoreKit prices in the app. Do not change the current landing/paywall promise to monthly pricing. Do not imply all players need Tour Pass for a captain-funded room.

## Technical separation for later

Keep permanent StoreKit ownership and annual service entitlement independent. Expiration of a future annual entitlement must never overwrite or revoke the nonconsumable. No server outage or club/account state may block offline owned modes. Future server features need an actual design for identity, moderation, result validation, room limits, privacy, retention and deletion before launch.
