const { test } = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const { stripTypeScriptTypes } = require('node:module');
const source = fs.readFileSync('web/app.js', 'utf8');
const flush = () => new Promise(resolve => setImmediate(resolve));
async function browser({ search = '', data = new Map(), reply = { ok: true }, failStorage = false, networkError = false } = {}) {
  const nodes = new Map();
  const node = key => {
    if (!nodes.has(key)) nodes.set(key, { value: '', textContent: '', disabled: false, click() { return this.onclick(); } });
    return nodes.get(key);
  };
  const app = { innerHTML: '', querySelector: node, querySelectorAll: () => [] };
  const calls = [];
  let cleaned;
  const context = vm.createContext({
    document: { getElementById: () => app }, navigator: {},
    location: { href: 'https://tennisiq.srqtennis.com/' + search },
    history: { replaceState: (_, __, url) => { cleaned = url; } },
    localStorage: { getItem: k => data.get(k) ?? null, setItem(k,v) { if (failStorage) throw Error('blocked'); data.set(k,v); } },
    crypto: require('node:crypto').webcrypto, URL, URLSearchParams, AbortSignal,
    fetch: async (url, options) => {
      if (url === './questions.json') return { json: async () => ({ questions: [] }) };
      calls.push(JSON.parse(options.body));
      if (networkError) throw Error('offline');
      return { ok: true, json: async () => reply };
    },
  });
  vm.runInContext(source, context);
  await flush();
  return { context, calls, data, nodes, cleaned, owned: () => vm.runInContext('owned()', context), redeem: code => context.redeemCode(code) };
}
test('old URL flags and old local unlock never grant ownership', async () => {
  for (const search of ['?owned=1', '?unlock=1']) {
    const b = await browser({ search, data: new Map([['tennis-iq-owned', 'true']]) });
    assert.equal(b.owned(), false); assert.equal(b.calls.length, 0); assert.equal(b.cleaned, '/');
  }
});
test('hardcoded legacy code rejected without a request', async () => {
  const b = await browser(); await b.redeem('SRQACE'); assert.equal(b.owned(), false); assert.equal(b.calls.length, 0);
});
test('auto redeem, normalize, persist device and reload without second claim', async () => {
  const b = await browser({ search: '?code=srq-abcd-2345&campaign=test#app' });
  assert.equal(b.calls.length, 1); assert.equal(b.calls[0].code, 'SRQ-ABCD-2345'); assert.ok(b.calls[0].device_id);
  assert.equal(b.owned(), true); assert.equal(b.cleaned, '/?campaign=test#app');
  const reload = await browser({ data: b.data, search: '?code=SRQ-ABCD-2345' });
  assert.equal(reload.owned(), true); assert.equal(reload.calls.length, 0);
});
test('manual submission works and duplicate clicks send only one request', async () => {
  const b = await browser();
  b.nodes.get('#code').value = 'SRQ-ABCD-2345';
  await Promise.all([b.nodes.get('[data-code]').click(), b.nodes.get('[data-code]').click()]);
  assert.equal(b.calls.length, 1); assert.equal(b.owned(), true);
});
test('denied code or network failure never grants ownership', async () => {
  for (const options of [{ reply: { ok: false, reason: 'used' } }, { networkError: true }]) {
    const b = await browser(options); await b.redeem('SRQ-ABCD-2345');
    assert.equal(b.owned(), false); assert.equal(b.nodes.get('[data-code]').disabled, false);
    assert.ok(b.nodes.get('#code-message').textContent.length);
  }
});
test('blocked storage does not consume a code', async () => {
  const b = await browser({ failStorage: true }); await b.redeem('SRQ-ABCD-2345');
  assert.equal(b.calls.length, 0); assert.equal(b.owned(), false);
});
test('unlock record requires its matching device', async () => {
  const b = await browser({ data: new Map([['tennis-iq-unlock-v2', '{"device_id":"one"}'], ['tennis-iq-device-id', '"two"']]) });
  assert.equal(b.owned(), false);
});
function edge({ dbError = false } = {}) {
  let handler;
  const row = { code: 'SRQ-ABCD-2345', status: 'issued' };
  const code = stripTypeScriptTypes(fs.readFileSync('supabase/functions/tennis-iq-redeem/index.ts', 'utf8').replace(/^import .*;\n/gm, ''));
  vm.runInNewContext(code, {
    Request, Response, Set, Date,
    Deno: { env: { get: () => 'test' }, serve: fn => { handler = fn; } },
    createClient: () => ({ from: () => {
      let patch; const filters = [];
      return { update(v) { patch = v; return this; }, eq(k,v) { filters.push([k,v]); return this; }, select() { return this; }, async maybeSingle() {
        if (dbError) return { data: null, error: { message: 'offline' } };
        if (!filters.every(([k,v]) => row[k] === v)) return { data: null, error: null };
        if (patch) Object.assign(row, patch);
        return { data: { ...row }, error: null };
      } };
    } }),
  });
  return { handler, row, request: device => handler(new Request('https://example.test', { method: 'POST', headers: { 'Content-Type': 'application/json', Origin: 'https://tennisiq.srqtennis.com' }, body: JSON.stringify({ code: row.code, device_id: device }) })) };
}
test('atomic first claim wins; same and different device repeats fail', async () => {
  const e = edge(); const results = await Promise.all([e.request('one'), e.request('two')]);
  const bodies = await Promise.all(results.map(r => r.json()));
  assert.equal(bodies.filter(b => b.ok).length, 1); assert.equal(e.row.status, 'redeemed'); assert.ok(e.row.redeemed_at);
  assert.deepEqual(await (await e.request(e.row.device_id)).json(), { ok: false, reason: 'used' });
});
test('database failures are retryable and malformed bodies are rejected', async () => {
  assert.equal((await edge({ dbError: true }).request('one')).status, 503);
  const e = edge();
  for (const body of ['null', '{', '{}']) assert.equal((await e.handler(new Request('https://example.test', { method: 'POST', body }))).status, 400);
  const preflight = await e.handler(new Request('https://example.test', { method: 'OPTIONS', headers: { Origin: 'https://tennisiq.srqtennis.com' } }));
  assert.equal(preflight.headers.get('Access-Control-Allow-Origin'), 'https://tennisiq.srqtennis.com');
});
