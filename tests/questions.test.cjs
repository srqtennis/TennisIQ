const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const crypto = require('node:crypto');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const read = p => fs.readFileSync(path.join(root, p));
const bankBytes = read('web/questions.json');
const bank = JSON.parse(bankBytes);
const audit = JSON.parse(read('docs/audit/final-ledger.json'));

test('native and web banks are identical and match the audited artifact', () => {
  assert.deepEqual(bankBytes, read('TennisIQ/Resources/questions.json'));
  assert.equal(crypto.createHash('sha256').update(bankBytes).digest('hex'), audit.bank_sha256);
});

test('every item has a unique ID, valid answer index, distinct choices and audit coverage', () => {
  const ids = new Set();
  const ledger = new Map(audit.entries.map(e => [e.id, e]));
  assert.equal(ledger.size, bank.questions.length);
  for (const q of bank.questions) {
    assert.ok(!ids.has(q.id), q.id); ids.add(q.id);
    assert.equal(q.choices.length, 4, q.id);
    assert.equal(new Set(q.choices.map(s => s.normalize('NFKC').trim().toLowerCase())).size, 4, q.id);
    assert.ok(Number.isInteger(q.answer) && q.answer >= 0 && q.answer < 4, q.id);
    assert.ok(q.question.trim() && q.explain.trim(), q.id);
    const e = ledger.get(q.id);
    assert.ok(e, q.id);
    assert.ok(['verified', 'corrected', 'contextual'].includes(e.status), q.id);
    if (e.status !== 'unresolved') assert.ok(e.sources.length, q.id);
  }
});

test('invalid multiple-answer negative-winner family is repaired', () => {
  for (const q of bank.questions.filter(q => q.id.startsWith('not-'))) {
    assert.ok(!/did NOT win/i.test(q.question), q.id);
    const entry = audit.entries.find(e => e.id === q.id);
    assert.equal(entry.status, 'corrected', q.id);
    assert.ok(q.explain.includes(q.choices[q.answer]), q.id);
  }
});

test('published corrections have not drifted from the reviewed fields', () => {
  const questions = new Map(bank.questions.map(q => [q.id, q]));
  const changes = JSON.parse(read('docs/audit/changes.json'));
  for (const change of changes) {
    for (const [key, value] of Object.entries(change.after)) {
      assert.deepEqual(questions.get(change.id)[key], value, `${change.id}: ${key}`);
    }
  }
});
