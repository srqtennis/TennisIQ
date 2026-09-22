const CAT_LABEL = {
  court: "Court",
  equipment: "Gear",
  scoring: "Scoring",
  rules: "Rules",
  history: "History",
  slams: "Slams",
  lingo: "Lingo",
  strategy: "Strategy",
  tour: "Tour",
};
const IQ_CATS = new Set(["court", "equipment", "scoring", "rules", "history", "lingo", "strategy", "tour"]);
const IQ_MIX = 0.75;
const DIFF_LABEL = { rookie: "Rookie", club: "Club", tour: "Tour" };
const LETTERS = ["A", "B", "C", "D"];
const FREE_BALLS = 4;
// Purchase happens on the landing page (PayPal -> account entitlement).
const PAY_URL = "../#own";

const store = {
  get(k, fallback) {
    try { return JSON.parse(localStorage.getItem("tennis-iq-" + k)) ?? fallback; }
    catch { return fallback; }
  },
  set(k, v) { localStorage.setItem("tennis-iq-" + k, JSON.stringify(v)); }
};

const state = {
  bank: [],
  screen: "land",
  mode: "rally",
  filterCat: "all",
  filterDiff: "all",
  deck: [],
  i: 0,
  score: 0,
  streak: 0,
  picked: null,
  timed: false,
  seconds: 20,
  timerId: null,
  result: null,
};

const $app = document.getElementById("app");

function shuffle(arr) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

function deal(q) {
  const idx = q.choices.map((_, i) => i);
  const order = shuffle(idx);
  return {
    ...q,
    choices: order.map(i => q.choices[i]),
    answer: order.indexOf(q.answer),
  };
}

const auth = { user: null, entitled: false, loaded: false };

function owned() { return !!auth.entitled; }

async function refreshAuth(force) {
  try {
    auth.user = await TIQ.user();
    auth.entitled = auth.user ? !!(await TIQ.entitlement(force)) : false;
  } catch {
    auth.entitled = false;
  }
  auth.loaded = true;
}

let redeemPending = false;
async function redeemCode(value) {
  if (redeemPending) return;
  const code = String(value).trim().toUpperCase().replace(/\s+/g, "");
  const button = $app.querySelector("[data-code]");
  const message = $app.querySelector("#code-message");
  const report = text => { if (message) message.textContent = text; };
  if (!/^SRQ-[A-Z0-9]{4}-[A-Z0-9]{4}$/.test(code)) {
    report("Enter the unlock code from your purchase email.");
    return;
  }
  if (!auth.user) { report("Sign in first, then enter your code — it attaches to your account."); return; }
  redeemPending = true;
  if (button) button.disabled = true;
  report("Attaching this code to your account…");
  try {
    const result = await TIQ.claimCode(code);
    if (!result || result.ok !== true) {
      report(result && result.reason === "used"
        ? "This code was already used by another account. Contact SRQ Tennis."
        : "That code could not be redeemed. Check your purchase email and try again.");
      return;
    }
    await refreshAuth(true);
    state.screen = "home";
    render();
  } catch {
    report("Could not reach the server. Check your connection and try again.");
  } finally {
    redeemPending = false;
    if (button) button.disabled = false;
  }
}

function stats() {
  return {
    best: store.get("best", 0),
    played: store.get("played", 0),
    streak: store.get("streak", 0),
    seen: store.get("seen", []),
    sampleDone: store.get("sampleDone", false),
    owned: owned(),
  };
}

function markSeen(id) {
  const seen = store.get("seen", []);
  if (!seen.includes(id)) {
    seen.push(id);
    store.set("seen", seen);
  }
}

function render() {
  const s = stats();
  if (state.screen === "land") return land(s);
  if (state.screen === "home") return home(s);
  if (state.screen === "setup") return setup();
  if (state.screen === "play") return play();
  if (state.screen === "done") return done();
  if (state.screen === "library") return library();
  if (state.screen === "own") return own();
}

function land(s) {
  const signedIn = !!auth.user;
  const who = signedIn ? escapeHtml(auth.user.email || "") : "";
  $app.innerHTML = `
    <div class="brand">
      <div class="mark"><div class="ball"></div></div>
      <div>
        <h1>Tennis IQ</h1>
        <p class="sub">Know the court. Win the argument.</p>
      </div>
    </div>
    <div class="card">
      <p class="kicker">Four free balls</p>
      <h2>Sample the hopper. Then own it.</h2>
      <p>Rules, The Code, scoring, court specs. Four questions. Then $9.99 once — not a membership.</p>
      <button class="btn btn-primary" data-sample>Play the sample</button>
    </div>
    ${signedIn ? `
    <div class="card">
      <p class="kicker">Signed in</p>
      <h2>${who}</h2>
      <p>This account doesn't own Tennis IQ yet. One payment unlocks every phone you sign in on.</p>
      <button class="btn btn-clay" data-pay>Own Tennis IQ — $9.99</button>
      <button class="btn btn-ghost" data-signout>Sign out</button>
    </div>
    <p class="tiny center">Bought before accounts? Enter the code from your purchase email.</p>
    <div class="card">
      <input id="code" aria-label="Unlock code" autocomplete="off" autocapitalize="characters" placeholder="SRQ-XXXX-XXXX" style="width:100%;padding:12px;border-radius:12px;border:1px solid var(--line);background:#102418;color:var(--text);font:inherit" />
      <button class="btn btn-ghost" data-code>Attach code to my account</button>
      <p id="code-message" role="status" aria-live="polite"></p>
    </div>` : `
    <div class="card">
      <p class="kicker">Own it</p>
      <h2>Sign in to play the full hopper</h2>
      <p>Your purchase lives on your account, so a new phone or a cleared browser never locks you out.</p>
      <button class="btn btn-primary" data-signin="google">Continue with Google</button>
      <button class="btn btn-ghost" data-signin="apple">Continue with Apple</button>
      <p class="tiny center" style="margin-top:10px">$9.99 once. No subscription.</p>
    </div>`}
  `;
  $app.querySelector("[data-sample]").onclick = () => startGame({ mode: "sample", n: FREE_BALLS, timed: false });
  $app.querySelectorAll("[data-signin]").forEach(b => {
    b.onclick = () => { b.disabled = true; TIQ.signIn(b.dataset.signin).catch(() => { b.disabled = false; }); };
  });
  const so = $app.querySelector("[data-signout]");
  if (so) so.onclick = async () => { await TIQ.signOut(); await refreshAuth(true); render(); };
  const pay = $app.querySelector("[data-pay]");
  if (pay) pay.onclick = () => { window.location.href = PAY_URL; };
  const codeBtn = $app.querySelector("[data-code]");
  if (codeBtn) {
    codeBtn.onclick = () => redeemCode($app.querySelector("#code").value);
    $app.querySelector("#code").onkeydown = event => { if (event.key === "Enter") codeBtn.click(); };
  }
}

function home(s) {
  $app.innerHTML = `
    <div class="brand">
      <div class="mark"><div class="ball"></div></div>
      <div>
        <h1>Tennis IQ</h1>
        <p class="sub">Know the court. Win the argument.</p>
      </div>
    </div>
    <div class="stats">
      <div class="stat"><b>${s.best}</b><span>Best rally</span></div>
      <div class="stat"><b>${s.played}</b><span>Sessions</span></div>
      <div class="stat"><b>${s.streak}</b><span>Best streak</span></div>
    </div>
    <div class="card">
      <p class="kicker">Match night</p>
      <h2>Daily Rally</h2>
      <p>Ten balls. 75% tennis IQ — rules, scoring, court, history, calls — 25% slams. The point is the explanation.</p>
      <button class="btn btn-primary" data-go="rally">${s.owned ? "Play 10" : "Locked — own it"}</button>
    </div>
    <div class="card">
      <p class="kicker">Pressure</p>
      <h2>Shot Clock</h2>
      <p>Twenty seconds a question. Miss or timeout and the rally ends the point.</p>
      <button class="btn btn-clay" data-go="timed">${s.owned ? "Timed 10" : "Locked — own it"}</button>
    </div>
    <div class="grid">
      <div class="card">
        <h2>Practice</h2>
        <p>Pick a topic and a level.</p>
        <button class="btn btn-green" data-go="setup">Drill</button>
      </div>
      <div class="card">
        <h2>Library</h2>
        <p>${state.bank.length.toLocaleString()} in the hopper.</p>
        <button class="btn btn-ghost" data-go="library">Browse</button>
      </div>
    </div>
    <div class="card">
      <p class="kicker">${s.owned ? "Account" : "Own it"}</p>
      <h2>${s.owned ? escapeHtml(auth.user && auth.user.email || "Unlocked") : "$9.99 once"}</h2>
      <p>${s.owned ? "Owned. Sign in on any phone to play." : "Not a subscription. One account, every device."}</p>
      <button class="btn btn-ghost" data-go="own">${s.owned ? "Account" : "How it works"}</button>
    </div>
    <p class="tiny center" style="margin-top:16px">ITF + Friend at Court 2026. Add to Home Screen for the app feel.</p>
  `;
  $app.querySelectorAll("[data-go]").forEach(b => {
    b.onclick = () => {
      const go = b.dataset.go;
      if (!owned() && go !== "own") { state.screen = "own"; render(); return; }
      if (go === "rally") startGame({ mode: "rally", n: 10, timed: false });
      if (go === "timed") startGame({ mode: "timed", n: 10, timed: true });
      if (go === "setup") { state.screen = "setup"; render(); }
      if (go === "library") { state.screen = "library"; render(); }
      if (go === "own") { state.screen = "own"; render(); }
    };
  });
}

function own() {
  $app.innerHTML = `
    <button class="back" data-home>← Home</button>
    <div class="card" style="margin-top:14px">
      <p class="kicker">Pricing</p>
      <h2>One-time. Not a membership.</h2>
      <p>League players will pay ten dollars to settle a line call. They will not add another monthly charge next to court time.</p>
    </div>
    <div class="card">
      <h2>What you own</h2>
      <p>Full question library, Daily Rally, Shot Clock, Practice filters, offline hopper. Purchase lives on your account; scores stay on the phone.</p>
    </div>
    <div class="card">
      <h2>What comes later</h2>
      <p>Optional later Tour Pass only if we ship new packs. Never paywall the rules you already bought.</p>
      ${owned() ? `<button class="btn btn-ghost" data-signout>Sign out</button>` : `<button class="btn btn-clay" data-pay>Pay $9.99</button>`}
      <button class="btn btn-primary" data-home>Back</button>
    </div>
  `;
  const so = $app.querySelector("[data-signout]");
  if (so) so.onclick = async () => { await TIQ.signOut(); await refreshAuth(true); state.screen = "land"; render(); };
  $app.querySelectorAll("[data-home]").forEach(b => {
    b.onclick = () => { state.screen = owned() ? "home" : "land"; render(); };
  });
  const pay = $app.querySelector("[data-pay]");
  if (pay) pay.onclick = () => { window.location.href = PAY_URL; };
}

function setup() {
  const cats = ["all", ...Object.keys(CAT_LABEL)];
  const diffs = ["all", "rookie", "club", "tour"];
  $app.innerHTML = `
    <button class="back" data-home>← Home</button>
    <div class="card" style="margin-top:14px">
      <p class="kicker">Practice court</p>
      <h2>Pick a surface</h2>
      <p>Filter the hopper, then play a set of 8.</p>
      <p class="tiny" style="margin-top:14px">TOPIC</p>
      <div class="chip-row" id="cats"></div>
      <p class="tiny">LEVEL</p>
      <div class="chip-row" id="diffs"></div>
      <button class="btn btn-primary" data-start>Start drill</button>
    </div>
  `;
  const catBox = $app.querySelector("#cats");
  cats.forEach(c => {
    const el = document.createElement("button");
    el.className = "chip" + (state.filterCat === c ? " on" : "");
    el.textContent = c === "all" ? "Mixed IQ" : CAT_LABEL[c];
    el.onclick = () => { state.filterCat = c; setup(); };
    catBox.appendChild(el);
  });
  const dBox = $app.querySelector("#diffs");
  diffs.forEach(d => {
    const el = document.createElement("button");
    el.className = "chip" + (state.filterDiff === d ? " on" : "");
    el.textContent = d === "all" ? "Any level" : DIFF_LABEL[d];
    el.onclick = () => { state.filterDiff = d; setup(); };
    dBox.appendChild(el);
  });
  $app.querySelector("[data-home]").onclick = () => { state.screen = "home"; render(); };
  $app.querySelector("[data-start]").onclick = () => startGame({
    mode: "practice", n: 8, timed: false,
    cat: state.filterCat, diff: state.filterDiff
  });
}

function pool(cat, diff) {
  return state.bank.filter(q =>
    (cat === "all" || q.category === cat) &&
    (diff === "all" || q.difficulty === diff) &&
    Array.isArray(q.choices) && q.choices.length >= 2
  );
}

function pickMix(list, n, mode, cat) {
  const useIqMix = (mode === "rally" || mode === "timed") && cat === "all";
  let raw;
  if (!useIqMix) raw = shuffle(list).slice(0, Math.min(n, list.length));
  else {
    const iq = shuffle(list.filter(q => IQ_CATS.has(q.category)));
    const slams = shuffle(list.filter(q => q.category === "slams"));
    const nIq = Math.round(n * IQ_MIX);
    raw = iq.slice(0, nIq).concat(slams.slice(0, n - nIq));
    if (!raw.length) raw = shuffle(list).slice(0, n);
    raw = shuffle(raw);
  }
  return raw.map(deal);
}

function startGame({ mode, n, timed, cat = "all", diff = "all" }) {
  clearInterval(state.timerId);
  let list = pool(cat, diff);
  if (list.length < n) list = pool("all", "all");
  state.mode = mode;
  state.timed = timed;
  state.deck = pickMix(list, n, mode, cat);
  state.i = 0;
  state.score = 0;
  state.streak = 0;
  state.picked = null;
  state.screen = "play";
  render();
}

function tick() {
  state.seconds -= 1;
  const el = document.getElementById("clock");
  if (el) {
    el.textContent = state.seconds + "s";
    if (state.seconds <= 5) el.classList.add("clock-hot");
  }
  if (state.seconds <= 0) {
    clearInterval(state.timerId);
    if (state.picked === null) lockAnswer(-1);
  }
}

function play() {
  const q = state.deck[state.i];
  const pct = Math.round((state.i / state.deck.length) * 100);
  if (state.timed && state.picked === null) {
    clearInterval(state.timerId);
    state.seconds = 20;
    state.timerId = setInterval(tick, 1000);
  }
  $app.innerHTML = `
    <div class="meta">
      <span>${CAT_LABEL[q.category] || q.category} · ${DIFF_LABEL[q.difficulty] || q.difficulty}</span>
      <span>${state.timed ? `<b id="clock">${state.seconds}s</b> · ` : ""}Q ${state.i + 1}/${state.deck.length} · ${state.score}</span>
    </div>
    <div class="progress"><i style="width:${pct}%"></i></div>
    <p class="q">${escapeHtml(q.question)}</p>
    <div id="choices"></div>
    <div id="after"></div>
  `;
  const box = $app.querySelector("#choices");
  q.choices.forEach((c, idx) => {
    const b = document.createElement("button");
    b.className = "choice";
    b.innerHTML = `<span class="ltr">${LETTERS[idx] || idx + 1}</span><span>${escapeHtml(c)}</span>`;
    b.onclick = () => lockAnswer(idx);
    if (state.picked !== null) {
      if (idx === q.answer) b.classList.add("right");
      else if (idx === state.picked) b.classList.add("wrong");
      else b.classList.add("idle");
      b.disabled = true;
    }
    box.appendChild(b);
  });
  if (state.picked !== null) {
    const after = $app.querySelector("#after");
    after.innerHTML = `
      <div class="explain">${escapeHtml(q.explain || "")}</div>
      <button class="btn btn-primary" id="next">${state.i + 1 === state.deck.length ? "See the number" : "Next ball"}</button>
    `;
    after.querySelector("#next").onclick = next;
  }
}

function lockAnswer(idx) {
  if (state.picked !== null) return;
  clearInterval(state.timerId);
  const q = state.deck[state.i];
  markSeen(q.id);
  state.picked = idx;
  if (idx === q.answer) {
    state.score += state.timed ? 12 + Math.max(0, state.seconds) : 10;
    state.streak += 1;
    if (state.streak > store.get("streak", 0)) store.set("streak", state.streak);
  } else {
    state.streak = 0;
  }
  render();
}

function next() {
  state.picked = null;
  if (state.i + 1 >= state.deck.length) finish();
  else { state.i += 1; render(); }
}

function finish() {
  clearInterval(state.timerId);
  const max = state.deck.length * (state.timed ? 32 : 10);
  const raw = Math.round((state.score / Math.max(max, 1)) * 100);
  if (state.score > store.get("best", 0)) store.set("best", state.score);
  store.set("played", store.get("played", 0) + 1);
  if (state.mode === "sample") store.set("sampleDone", true);
  state.result = { raw, max };
  state.screen = "done";
  render();
}

function grade(pct) {
  if (pct >= 90) return "Tour brain. Take the chair.";
  if (pct >= 75) return "Club champion. Tight margins.";
  if (pct >= 55) return "Solid league player. Keep drilling.";
  return "First-ball project. Read the explanation and go again.";
}

function done() {
  const pct = state.result.raw;
  $app.innerHTML = `
    <div class="card center">
      <span class="badge">${state.mode}</span>
      <div class="score-big">${pct}</div>
      <p>Tennis IQ</p>
      <p style="color:var(--gold);margin-top:10px;font-family:Fraunces,serif">${grade(pct)}</p>
      <p class="tiny" style="margin-top:8px">${state.score} points on the board</p>
      ${!owned() ? `<button class="btn btn-clay" data-pay>Own the other ${Math.max(0, state.bank.length - FREE_BALLS).toLocaleString()} balls — $9.99</button>` : `<button class="btn btn-primary" data-again>Play again</button>`}
      <button class="btn btn-ghost" data-home>Home</button>
    </div>
  `;
  const again = $app.querySelector("[data-again]");
  if (again) again.onclick = () => {
    if (!owned()) { state.screen = "own"; render(); return; }
    if (state.mode === "practice") startGame({ mode: "practice", n: 8, timed: false, cat: state.filterCat, diff: state.filterDiff });
    else startGame({ mode: state.mode, n: 10, timed: state.mode === "timed" });
  };
  $app.querySelector("[data-home]").onclick = () => { state.screen = owned() ? "home" : "land"; render(); };
  const pay = $app.querySelector("[data-pay]");
  if (pay) pay.onclick = () => { window.location.href = PAY_URL; };
}

function library() {
  const groups = {};
  state.bank.forEach(q => {
    groups[q.category] = groups[q.category] || [];
    groups[q.category].push(q);
  });
  $app.innerHTML = `
    <button class="back" data-home>← Home</button>
    <div class="card" style="margin-top:14px">
      <p class="kicker">Hopper</p>
      <h2>Question library</h2>
      <p>${state.bank.length.toLocaleString()} items. Tap a topic to drill it.</p>
      <div id="list"></div>
    </div>
  `;
  const list = $app.querySelector("#list");
  Object.keys(CAT_LABEL).forEach(cat => {
    if (!groups[cat]) return;
    const row = document.createElement("div");
    row.className = "list-item";
    row.innerHTML = `<div><b>${CAT_LABEL[cat]}</b><div class="tiny">${groups[cat].length} questions</div></div><span>›</span>`;
    row.onclick = () => {
      state.filterCat = cat;
      state.filterDiff = "all";
      startGame({ mode: "practice", n: Math.min(8, groups[cat].length), timed: false, cat, diff: "all" });
    };
    list.appendChild(row);
  });
  $app.querySelector("[data-home]").onclick = () => { state.screen = "home"; render(); };
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, m => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
  }[m]));
}

const launchUrl = new URL(location.href);
const launchCode = launchUrl.searchParams.get("code");
for (const key of ["code", "owned", "unlock"]) launchUrl.searchParams.delete(key);
history.replaceState(null, "", launchUrl.pathname + launchUrl.search + launchUrl.hash);

$app.innerHTML = `<div class="card"><h2>Loading the hopper…</h2></div>`;
Promise.all([
  fetch("./questions.json").then(r => r.json()),
  refreshAuth(false),
]).then(([data]) => {
  state.bank = data.questions || [];
  if (owned()) state.screen = "home";
  render();
  if (launchCode && !owned() && auth.user) {
    const input = $app.querySelector("#code");
    if (input) input.value = launchCode;
    void redeemCode(launchCode);
  }
  TIQ.onChange(async () => {
    const was = owned();
    await refreshAuth(true);
    if (owned() !== was || state.screen === "land") { state.screen = owned() ? "home" : "land"; render(); }
  });
}).catch(err => {
  $app.innerHTML = `<div class="card"><h2>Could not load the hopper</h2><p>${escapeHtml(String(err))}</p></div>`;
});

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("./sw.js").catch(() => {});
}
