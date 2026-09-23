# Single-use unlocks

The web source was recovered from the deployed tennisiq.srqtennis.com site because Git contained only the HTML shell and manifest; the supplied Downloads copy predates the paid unlock flow. Netlify publishes `web/` on site `tennis-iq-gr9t` (37403f76-9d5c-471e-a7c8-631ac52d1964).

## Existing Supabase backend

Project: `srq-data` (`ymasbdyfcgbombveutpt`). The existing `public.tennis_iq_codes` table has `code`, `contact_id`, `email`, `status`, `issued_at`, `redeemed_at`, and `device_id`, plus purchase metadata. `code` is unique; RLS is enabled. No table migration is needed.

The existing `tennis-iq-issue` function is preserved in this repo. GHL sends POST JSON containing `contact_id`, `email`, and optionally `first_name`, `order_id`, `amount` to:

`https://ymasbdyfcgbombveutpt.supabase.co/functions/v1/tennis-iq-issue`

The `x-tennis-iq-secret` header must match Supabase's `TENNIS_IQ_ISSUE_SECRET`. Keep that secret in the GHL workflow and Supabase secrets only. The response contains `{ "code": "SRQ-XXXX-XXXX" }`. The workflow must deliver a link like `https://tennisiq.srqtennis.com/?code=SRQ-XXXX-XXXX` using the actual returned code. Issuance is not called by the browser. Its existing order lookup does not enforce concurrent order idempotency at the database level.

## Redemption

`tennis-iq-redeem` accepts POST `{ "code": "SRQ-XXXX-XXXX", "device_id": "<browser UUID>" }`. Its atomic UPDATE matches both code and `status = 'issued'`. The first claim sets `status`, `redeemed_at`, and `device_id`; every later claim returns `{ "ok": false, "reason": "used" }`, even from the same device. Database errors return 503.

The app persists the device ID before requesting redemption, then stores `tennis-iq-unlock-v2` only after `{ "ok": true }`. Reloads use that local record and do not redeem again. Old `tennis-iq-owned` flags, the old hardcoded code, and `owned`/`unlock` query flags no longer grant access. Existing legacy unlocks therefore require an issued code. The URL code is removed immediately and referrers are suppressed.

A strict single-use code can be consumed if the success response is lost or local storage fails after redemption. The UI directs the buyer to request a reset. Clearing browser storage also requires a reset. This is a browser-local unlock for an offline static app, not server-enforced content DRM. Resetting a row does not revoke an offline unlock already stored on the previous phone.

## Phone swap / recovery

In the Supabase SQL editor, substitute the purchaser's verified code:

```sql
update public.tennis_iq_codes
set status = 'issued', redeemed_at = null, device_id = null
where code = 'SRQ-XXXX-XXXX';
```

The new phone can then redeem the same code once.

## Verification

Run `node --test tests/unlock.test.cjs` (Node 22.13+). Coverage includes removed bypasses, manual and URL redemption, persistence, duplicate submission, storage/network errors, atomic claims, repeat denial, malformed bodies, and CORS. Live synthetic tests check concurrent redemption and repeat denial; synthetic rows are deleted afterwards.

The purchase button opens `https://link.fastpaydirect.com/payment-link/6ab1e0e39f7ff2c808a76e64`. A paid checkout and GHL delivery workflow were not configured or verified by this change.
