// Tennis IQ auth: Supabase Auth (Google + Apple) + entitlement lookup.
// Loaded by both / (landing) and /play/ (app). Exposes window.TIQ.
(function () {
  const SUPABASE_URL = "https://flskzrfmwheucskovaut.supabase.co";
  const SUPABASE_KEY = "sb_publishable_l7-HQ_K5B4Fkbgkquojtdw_i5CFrVYZ";
  const SDK = "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js";

  let client = null;
  let entitlementCache = null; // { email, granted_at } | false

  function ready() {
    if (client) return Promise.resolve(client);
    return new Promise((resolve, reject) => {
      const boot = () => {
        client = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY, {
          auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true, flowType: "pkce" },
        });
        resolve(client);
      };
      if (window.supabase) return boot();
      const s = document.createElement("script");
      s.src = SDK; s.async = true;
      s.onload = boot;
      s.onerror = () => reject(new Error("auth sdk failed to load"));
      document.head.appendChild(s);
    });
  }

  async function session() {
    const sb = await ready();
    const { data } = await sb.auth.getSession();
    return data.session || null;
  }

  async function user() {
    const s = await session();
    return s ? s.user : null;
  }

  // provider: "google" | "apple". Returns to `redirectTo` (defaults to current page).
  async function signIn(provider, redirectTo) {
    const sb = await ready();
    const { error } = await sb.auth.signInWithOAuth({
      provider,
      options: { redirectTo: redirectTo || location.origin + location.pathname },
    });
    if (error) throw error;
  }

  async function signOut() {
    const sb = await ready();
    entitlementCache = null;
    await sb.auth.signOut();
  }

  // Server truth: does this account own Tennis IQ?
  async function entitlement(force) {
    if (!force && entitlementCache !== null) return entitlementCache;
    const sb = await ready();
    const u = await user();
    if (!u) return (entitlementCache = false);
    const { data, error } = await sb
      .from("tennis_iq_entitlements")
      .select("email, granted_at, source")
      .is("revoked_at", null)
      .limit(1)
      .maybeSingle();
    if (error) throw error;
    return (entitlementCache = data || false);
  }

  // Legacy SRQ-XXXX-XXXX code -> attach to this account.
  async function claimCode(code) {
    const sb = await ready();
    const { data, error } = await sb.rpc("tennis_iq_claim_code", { p_code: code });
    if (error) throw error;
    if (data && data.ok) entitlementCache = null;
    return data;
  }

  function onChange(fn) {
    ready().then(sb => sb.auth.onAuthStateChange((_e, s) => { entitlementCache = null; fn(s); }));
  }

  window.TIQ = { ready, session, user, signIn, signOut, entitlement, claimCode, onChange, SUPABASE_URL };
})();
