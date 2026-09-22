# Accounts, sign-in and purchase (v2)

Replaces the device-bound single-use code flow in `UNLOCK.md` (kept for legacy buyers).

## Supabase project
Tennis IQ has its **own** Supabase project: `tennis-iq` (`flskzrfmwheucskovaut`, us-east-2). It is not in srq-data — consumer accounts stay separate from ops data. The Tennis IQ tables were dropped from srq-data on 2026-09-22; the three old edge functions there (`tennis-iq-issue/redeem/paypal`) are dead and can be deleted in the dashboard.

## Layout
- `/` — landing page (`web/index.html`): marketing, 3-question sample, Google/Apple sign-in, PayPal checkout, legacy code claim.
- `/play/` — the PWA. Reads the same Supabase session. Locked modes send the user to `/#own`.
- `web/play/auth.js` — shared auth module (`window.TIQ`): Supabase Auth (PKCE), `entitlement()`, `claimCode()`.

## Data
- `public.tennis_iq_entitlements` — one row per paying email. Unique on `lower(email)` and `(source, source_ref)`.
  RLS: signed-in user reads own row (by `user_id` or matching JWT email).
- Trigger `tennis_iq_link_entitlement` on `auth.users` insert backfills `user_id` when a buyer signs in later with the same email.
- RPC `tennis_iq_claim_code(p_code)` — signed-in user attaches a legacy `SRQ-XXXX-XXXX` code to their account. Same-email codes already redeemed on a phone are allowed once.
- `public.tennis_iq_codes` — legacy (5 test rows copied over); `tennis-iq-issue` / `tennis-iq-redeem` remain deployed but the app no longer calls redeem.

## Purchase flow
1. User signs in (Step 1) → we know `user.id` + `email`.
2. PayPal Smart Button creates an order with `custom_id = "<user_id>|<email>"`, amount 9.99 USD.
3. PayPal webhook `PAYMENT.CAPTURE.COMPLETED` → edge function `tennis-iq-paypal` (deployed) verifies the signature with PayPal, inserts the entitlement (idempotent on capture id / email).
4. Landing page polls `entitlement()` for ~18 s, then shows "Open Tennis IQ".

## One-time setup (Michael)
### Supabase → Authentication → Providers
- **Google**: create an OAuth client in Google Cloud Console (Web application). Authorized redirect URI:
  `https://flskzrfmwheucskovaut.supabase.co/auth/v1/callback`. Paste client id/secret into Supabase.
- **Apple**: Apple Developer → Identifiers → Services ID (e.g. `com.srqtennis.tennisiq.web`), enable Sign in with Apple, return URL = the same callback. Create a Key with Sign in with Apple (.p8). Supabase needs Services ID, Team ID, Key ID and the key. Apple client secrets expire every 6 months — calendar it.
- **URL configuration**: Site URL `https://tennisiq.srqtennis.com`; Redirect URLs add `https://tennisiq.srqtennis.com/**` and `http://localhost:8000/**`.

### PayPal
- developer.paypal.com → Apps & Credentials → **Live** → Create app "Tennis IQ". Copy Client ID + Secret.
- Webhooks on that app: URL `https://flskzrfmwheucskovaut.supabase.co/functions/v1/tennis-iq-paypal`, event **Payment capture completed**. Copy the Webhook ID.
- Put the Client ID in `web/index.html` (`PAYPAL_CLIENT_ID`).
- Supabase → Edge Functions → Secrets: `PAYPAL_CLIENT_ID`, `PAYPAL_CLIENT_SECRET`, `PAYPAL_WEBHOOK_ID`, `PAYPAL_ENV=live` (use `sandbox` + sandbox creds to test first).

### Netlify
- Publish dir stays `web/`. `_redirects` sends `/play` → `/play/`. Deploy.

## Support
- Grant manually: `insert into tennis_iq_entitlements (email, source, source_ref) values ('x@y.com','manual','reason');`
- Revoke: `update tennis_iq_entitlements set revoked_at = now() where lower(email)='x@y.com';`
- Legacy phone-reset SQL in `UNLOCK.md` is no longer needed — tell the buyer to sign in and enter their code.

## Not done yet
- iOS app has no paywall/sign-in. Plan: Sign in with Apple via Supabase Swift SDK, read the same entitlement; StoreKit only if you go App Store.
- Score/streak sync across devices (still localStorage / UserDefaults).
- `tests/legacy/unlock.test.cjs` targets the retired device-code flow; new tests needed for claim RPC + webhook.
