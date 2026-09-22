// Tennis IQ: issue a single-use unlock code. Called by the GHL purchase workflow (webhook).
// Auth: header x-tennis-iq-secret must equal env TENNIS_IQ_ISSUE_SECRET. Fails closed if unset.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"; // no 0/O/1/I/L
function chunk(n: number) {
  const b = new Uint8Array(n);
  crypto.getRandomValues(b);
  return Array.from(b, (x) => ALPHABET[x % ALPHABET.length]).join("");
}
function makeCode() {
  return `SRQ-${chunk(4)}-${chunk(4)}`;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("POST only", { status: 405 });
  const secret = Deno.env.get("TENNIS_IQ_ISSUE_SECRET");
  if (!secret || req.headers.get("x-tennis-iq-secret") !== secret) {
    return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401, headers: { "Content-Type": "application/json" } });
  }
  let body: Record<string, unknown> = {};
  try { body = await req.json(); } catch { /* empty body ok */ }

  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const row = {
    contact_id: (body.contact_id ?? null) as string | null,
    email: (body.email ?? null) as string | null,
    first_name: (body.first_name ?? null) as string | null,
    order_id: (body.order_id ?? null) as string | null,
    amount: body.amount != null && body.amount !== "" ? Number(body.amount) : null,
  };

  // Idempotent on order_id: re-firing the same order returns the same code.
  if (row.order_id) {
    const { data: existing } = await sb.from("tennis_iq_codes").select("code").eq("order_id", row.order_id).maybeSingle();
    if (existing) return new Response(JSON.stringify({ code: existing.code, reused: true }), { headers: { "Content-Type": "application/json" } });
  }

  for (let attempt = 0; attempt < 5; attempt++) {
    const code = makeCode();
    const { error } = await sb.from("tennis_iq_codes").insert({ ...row, code });
    if (!error) return new Response(JSON.stringify({ code }), { headers: { "Content-Type": "application/json" } });
    if (error.code !== "23505") {
      return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: { "Content-Type": "application/json" } });
    }
  }
  return new Response(JSON.stringify({ error: "could not generate unique code" }), { status: 500, headers: { "Content-Type": "application/json" } });
});

