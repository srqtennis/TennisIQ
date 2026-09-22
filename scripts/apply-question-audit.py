import json,pathlib,collections,hashlib,datetime
root=pathlib.Path(__file__).resolve().parents[1]
files=['audit-rules.json','audit-history.json','audit-slams.json','audit-lingo.json','audit-lingo-second-review.json','audit-slams-supplement.json']
ledger={}
for f in files:
 d=json.loads((root/'docs'/f).read_text());rows=d.get('entries',d.get('questions',d.get('items',[])))
 for e in rows:
  e=dict(e);e['report']=f;ledger[e['id']]=e
original=json.loads((root/'docs/audit/original-bank.json').read_text())
ids={q['id'] for q in original['questions']}
assert set(ledger)==ids,(ids-set(ledger),set(ledger)-ids)
print('Coverage',len(ids),'verdicts',dict(collections.Counter(e['verdict'] for e in ledger.values())))
print('Unresolved',[(e['id'],e.get('rationale',e.get('reason'))) for e in ledger.values() if e['verdict']=='unresolved'])
if __import__('sys').argv[-1]!='--apply':raise SystemExit
original_bytes=(root/'docs/audit/original-bank.json').read_bytes()
allowed={hashlib.sha256(original_bytes).hexdigest()}
previous=root/'docs/audit/final-ledger.json'
if previous.exists(): allowed.add(json.loads(previous.read_text())['bank_sha256'])
for file in ['web/questions.json','TennisIQ/Resources/questions.json']:
    assert hashlib.sha256((root/file).read_bytes()).hexdigest() in allowed, f'{file} changed outside this audit; review before applying'
bank=json.loads(json.dumps(original));changes=[];final=[]
for q in bank['questions']:
 e=ledger[q['id']];replacement=e.get('replacement',{})
 if e['verdict']=='correction':assert replacement,q['id']
 for k in replacement:assert k in ['question','choices','answer','explain','tags','difficulty','category'],(q['id'],k)
 actual={k:v for k,v in replacement.items() if q[k]!=v}
 if actual:
  changes.append({'id':q['id'],'before':{k:q[k] for k in actual},'after':actual,'reason':e.get('rationale',e.get('reason','')),'sources':e['sources']})
  q.update(actual)
 status='corrected' if actual else e['verdict']
 if status=='correction':status='verified'
 final.append({'id':q['id'],'category':q['category'],'status':status,'sources':e['sources'],'rationale':e.get('rationale',e.get('reason','')),'report':e['report']})
 assert len(q['choices'])==4 and 0<=q['answer']<4,q['id']
bank['version']=7
bank['source']='Source-reviewed question bank. Per-question evidence, corrections and limitations: docs/audit/final-ledger.json and docs/QUESTION_AUDIT.md.'
b= (json.dumps(bank,ensure_ascii=False,indent=2)+'\n').encode()
for p in ['web/questions.json','TennisIQ/Resources/questions.json']:(root/p).write_bytes(b)
summary={'audited_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'original_bank_sha256':hashlib.sha256((root/'docs/audit/original-bank.json').read_bytes()).hexdigest(),'bank_sha256':hashlib.sha256(b).hexdigest(),'counts':dict(collections.Counter(e['status'] for e in final)),'entries':final}
(root/'docs/audit/final-ledger.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False)+'\n')
(root/'docs/audit/changes.json').write_text(json.dumps(changes,indent=2,ensure_ascii=False)+'\n')
print('Applied changes',len(changes),summary['counts'])
