// Tennis IQ: PayPal webhook -> grant account entitlement.
// Configure in PayPal Developer: webhook URL = https://flskzrfmwheucskovaut.supabase.co/functions/v1/tennis-iq-paypal
// Events: PAYMENT.CAPTURE.COMPLETED, CHECKOUT.ORDER.APPROVED (approved is ignored; capture is what grants).
// Secrets: PAYPAL_CLIENT_ID, PAYPAL_CLIENT_SECRET, PAYPAL_WEBHOOK_ID, PAYPAL_ENV ("live" | "sandbox")
// The landing page passes custom_id = "<supabase user id>|<email>" on the order so we know who paid.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const ENV = Deno.env.get("PAYPAL_ENV") === "sandbox" ? "sandbox" : "live";
const API = ENV === "sandbox" ? "https://api-m.sandbox.paypal.com" : "https://api-m.paypal.com";
const json = (b: unknown, s = 200) => new Response(JSON.stringify(b), { status: s, headers: { "Content-Type": "application/json" } });

async function token() {
  const id = Deno.env.get("PAYPAL_CLIENT_ID"), sec = Deno.env.get("PAYPAL_CLIENT_SECRET");
  if (!id || !sec) throw new Error("paypal creds unset");
  const r = await fetch(`${API}/v1/oauth2/token`, {
    method: "POST",
    headers: { Authorization: "Basic " + btoa(`${id}:${sec}`), "Content-Type": "application/x-www-form-urlencoded" },
    body: "grant_type=client_credentials",
  });
  if (!r.ok) throw new Error("paypal token " + r.status);
  return (await r.json()).access_token as string;
}

async function verify(req: Request, rawBody: string): Promise<boolean> {
  const webhookId = Deno.env.get("PAYPAL_WEBHOOK_ID");
  if (!webhookId) return false; // fail closed
  const h = (k: string) => req.headers.get(k) ?? "";
  const r = await fetch(`${API}/v1/notifications/verify-webhook-signature`, {
    method: "POST",
    headers: { Authorization: "Bearer " + await token(), "Content-Type": "application/json" },
    body: JSON.stringify({
      auth_algo: h("paypal-auth-algo"),
      cert_url: h("paypal-cert-url"),
      transmission_id: h("paypal-transmission-id"),
      transmission_sig: h("paypal-transmission-sig"),
      transmission_time: h("paypal-transmission-time"),
      webhook_id: webhookId,
      webhook_event: JSON.parse(rawBody),
    }),
  });
  if (!r.ok) return false;
  return (await r.json()).verification_status === "SUCCESS";
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "POST only" }, 405);
  const raw = await req.text();
  let ok = false;
  try { ok = await verify(req, raw); } catch (e) { return json({ error: String(e) }, 503); }
  if (!ok) return json({ error: "bad signature" }, 401);

  const evt = JSON.parse(raw);
  if (evt.event_type !== "PAYMENT.CAPTURE.COMPLETED") return json({ ignored: evt.event_type });

  const cap = evt.resource ?? {};
  const captureId: string = cap.id;
  const amount = cap.amount?.value != null ? Number(cap.amount.value) : null;
  const custom: string = cap.custom_id ?? "";
  const [userId, customEmail] = custom.split("|");
  const payerEmail: string | undefined = evt.resource?.payer?.email_address ?? evt.resource?.payee?.email_address;
  const email = (customEmail || payerEmail || "").trim().toLowerCase();
  if (!email) return json({ error: "no email on capture", capture: captureId }, 200); // ack so PayPal stops retrying; check logs

  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { error } = await sb.from("tennis_iq_entitlements").insert({
    user_id: userId && /^[0-9a-f-]{36}$/i.test(userId) ? userId : null,
    email, source: "paypal", source_ref: captureId, amount,
  });
  // 23505 = already entitled (email or capture id) — idempotent ack.
  if (error && error.code !== "23505") return json({ error: error.message }, 500);
  return json({ ok: true, email, duplicate: !!error });
});
