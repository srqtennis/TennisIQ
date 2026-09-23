// Tennis IQ: redeem a single-use unlock code from the app. Public endpoint (CORS open to the app origin).
// POST { code, device_id } -> { ok: true } | { ok: false, reason }
// Every repeat redemption is denied, including requests from the original device.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const ORIGINS = new Set(["https://tennisiq.srqtennis.com", "http://localhost:8000", "http://127.0.0.1:8000"]);
function cors(req: Request) {
  const o = req.headers.get("origin") ?? "";
  return {
    "Access-Control-Allow-Origin": ORIGINS.has(o) ? o : "https://tennisiq.srqtennis.com",
    "Access-Control-Allow-Headers": "content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Content-Type": "application/json",
  };
}
const json = (req: Request, body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers: cors(req) });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: cors(req) });
  if (req.method !== "POST") return json(req, { ok: false, reason: "method" }, 405);

  let body: { code?: string; device_id?: string } = {};
  try { body = await req.json(); } catch { return json(req, { ok: false, reason: "bad_json" }, 400); }
  if (!body || typeof body.code !== "string" || typeof body.device_id !== "string") return json(req, { ok: false, reason: "invalid" }, 400);
  const code = String(body.code ?? "").trim().toUpperCase().replace(/\s+/g, "");
  const device = String(body.device_id ?? "").trim().slice(0, 64);
  if (!/^SRQ-[A-Z0-9]{4}-[A-Z0-9]{4}$/.test(code) || !device) return json(req, { ok: false, reason: "invalid" });

  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  // Atomic first-claim: only flips if still 'issued'.
  const { data: claimed, error: claimError } = await sb.from("tennis_iq_codes")
    .update({ status: "redeemed", redeemed_at: new Date().toISOString(), device_id: device })
    .eq("code", code).eq("status", "issued")
    .select("code").maybeSingle();
  if (claimError) return json(req, { ok: false, reason: "unavailable" }, 503);
  if (claimed) return json(req, { ok: true });

  const { data: row, error: readError } = await sb.from("tennis_iq_codes").select("status, device_id").eq("code", code).maybeSingle();
  if (readError) return json(req, { ok: false, reason: "unavailable" }, 503);
  if (!row) return json(req, { ok: false, reason: "unknown" });
  if (row.status === "redeemed") return json(req, { ok: false, reason: "used" });
  return json(req, { ok: false, reason: "revoked" });
});
