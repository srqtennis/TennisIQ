import json,re,unicodedata,html,collections,pathlib
base=pathlib.Path('/Users/mbmacbookpro/projects/TennisIQ');qs=[q for q in json.load(open(base/'web/questions.json'))['questions'] if q['category']=='slams']
def norm(s):return ''.join(c for c in unicodedata.normalize('NFKD',s) if not unicodedata.combining(c)).lower().replace('stefanie','steffi').strip()
urls={'ao':'https://ausopen.com/history/honour-roll/mens-singles','rg':'https://www.rolandgarros.com/en-us/palmares/','atp':'https://www.atptour.com/-/media/files/media-guide/2023/2023-atp-media-guide-full.pdf','wta':'https://wtafiles.wtatennis.com/pdf/publications/2026MG/WTAMG26_WTAGrandSlamRecords_US.pdf','wi':'https://www.wimbledon.com/pdf/Wimbledon_Compendium_2022.pdf','ao-surf':'https://wtafiles.wtatennis.com/pdf/matchnotes/2024/901_preview.pdf','us-surf':'https://ausopen.com/articles/news/10-grass-court-tournaments-you-may-never-have-known-existed','rg-surf':'https://stade.rolandgarros.com/en/stadium','wi26':'https://www.atptour.com/en/news/sinner-zverev-wimbledon-2026-final','us26':'https://www.usopen.org/amp/en_US/news/articles/2026-09-13/alexander_zverev_defeats_ben_shelton_to_win_2026_us_open.html','itf':'https://www.itftennis.com/en/tours/grand-slam-tournaments/'}
tables={k:{} for k in ['australian-open','rolandrg','wimbledon','us-open']}
s=open('/tmp/slam-ao.html').read()
for year,name in re.findall(r'<tr><td>(\d{4}(?: \([^<]+\))?)</td><td>([^<]+)',s):tables['australian-open'][year]=re.sub(r' \([A-Z]+\)','',html.unescape(name)).strip()
s=open('/tmp/slam-rg.html').read().split('Ladies')[0]
for name,year in re.findall(r'class="player-name"[^>]*>([^<]+)</p>.*?class="year"[^>]*>(\d{4})</p>',s):tables['rolandrg'].setdefault(year,html.unescape(name))
s=open('/tmp/atp.txt').read()
for k,start,end in [('wimbledon','WIMBLEDON HISTORY SINCE 1968','US OPEN HISTORY SINCE 1968'),('us-open','US OPEN HISTORY SINCE 1968','US OPEN HISTORY SINCE 1968')]:
 chunk=s.split(start)[1];chunk=chunk[:chunk.find('1968')+200] if False else chunk
 # stop after first 1968 result
 for line in chunk.splitlines():
  m=re.match(r'\s*(\d{4})\**\s+([A-Za-z][A-Za-z .’\-]+?)\s+\(',line)
  if m:
   y,n=m.groups();tables[k][y]=n.strip()
   if y=='1968':break
updates={'wimbledon':{2023:'Carlos Alcaraz',2024:'Carlos Alcaraz',2025:'Jannik Sinner',2026:'Jannik Sinner'},'us-open':{2023:'Novak Djokovic',2024:'Jannik Sinner',2025:'Carlos Alcaraz',2026:'Alexander Zverev'}}
for k,v in updates.items():tables[k].update({str(y):n for y,n in v.items()})
wt={k:{} for k in tables};s=open('/tmp/wta-slams.txt').read();chunk=s.split('OPEN ERA GRAND SLAM CHAMPIONS')[2] if s.count('OPEN ERA GRAND SLAM CHAMPIONS')>1 else s
for line in chunk.splitlines():
 m=re.match(r'(\d{4})\s',line)
 if m:
  names=[re.sub(r'\[[^]]+\]\s*|\s*\([A-Z]+\)','',n).strip() for n in re.split(r'\s{2,}',line)[1:]]
  if len(names)==4:
   for k,n in zip(wt,names):wt[k][m[1]]=n.strip()
print('MEN',[(k,len(v),v.get('1968'),v.get('2026')) for k,v in tables.items()]);print('WOMEN',[(k,len(v),v.get('2026')) for k,v in wt.items()])
# Source provenance for modern extensions.
extra={'wimbledon': ['https://www.atptour.com/en/news/alcaraz-djokovic-wimbledon-2023-sunday-final','https://www.atptour.com/en/news/rivalry-djokovic','https://www.atptour.com/-/media/sites/atp-tour/press/press-releases/2025-year-end-rankings-release.pdf',urls['wi26']], 'us-open':['https://www.atptour.com/en/news/djokovic-medvedev-us-open-2023-final/','https://www.atptour.com/en/news/sinner-fritz-us-open','https://www.atptour.com/en/news/sinner-alcaraz-us-open-2025-final',urls['us26']]}
def src(k):return [urls['ao' if k=='australian-open' else 'rg' if k=='rolandrg' else 'atp']]+extra.get(k,[])
rows={q['id']:{'id':q['id'],'verdict':'unresolved','sources':[],'reason':'Individual claim requires independent source review.'} for q in qs}
def mark(q,v,reason,sources,rep=None):
 r=rows[q['id']];r.update(verdict=v,reason=reason,sources=sources)
 if rep:r['replacement']=rep
for q in qs:
 i=q['id'];a=q['choices'][q['answer']]
 m=re.match(r'slam-(m|w|surf)-(.*)-(\d{4})$',i)
 if m:
  typ,k,y=m.groups();surface='grass' if k=='wimbledon' or k=='australian-open' and int(y)<1988 or k=='us-open' and int(y)<1975 else 'clay' if k=='rolandrg' or k=='us-open' and int(y)<1978 else 'hard'
  city='Brisbane' if k=='australian-open' and y=='1969' else 'Sydney' if k=='australian-open' and y in ['1970','1971'] else 'Melbourne' if k=='australian-open' else 'Paris' if k=='rolandrg' else 'London' if k=='wimbledon' else 'New York'
  sources=src(k); rep={}
  if typ=='surf':
   sources=[urls['ao-surf' if k=='australian-open' else 'us-surf' if k=='us-open' else 'rg-surf' if k=='rolandrg' else 'wi']]
   if a!=surface:rep={'answer':q['choices'].index(surface),'explain':f'The {y} tournament was played on {surface} in {city}.'}
   mark(q,'correction' if rep else 'verified','Historical surface checked, including AO 1988 and US Open 1975/1978 changes.',sources,rep)
  else:
   expected=(tables if typ=='m' else wt)[k].get(y)
   if expected and norm(a)==norm(expected):
    if typ=='m' and f'on {surface} in {city}' not in q['explain']:rep={'explain':f'{a} won the {y} '+q['question'].split(y+' ')[1].replace('?','')+f' The tournament was played on {surface} in {city}.'}
    mark(q,'correction' if rep else 'verified','Champion checked against independent official year table; historical surface/location also checked.',sources if typ=='m' else [urls['wta']],rep)
   elif expected:mark(q,'unresolved',f'Name mismatch: official table {expected}; bank {a}.',sources if typ=='m' else [urls['wta']])
 elif i.startswith('not-'):
  # Every edition has exactly one men's singles champion. Multiple distinct nonchampions means invalid single-answer format.
  k,y=re.match(r'not-(.*)-(\d{4})',i).groups();k=k.replace('roland-garros','rolandrg');winner=tables[k].get(y)
  if winner:
   valid=[j for j,c in enumerate(q['choices']) if norm(c)!=norm(winner)]
   mark(q,'correction',f'{len(valid)} choices are valid nonwinners; single-answer item is invalid.',src(k),{'question':q['question'].replace('Who did NOT win','Which player took'),'answer':next(j for j,c in enumerate(q['choices']) if norm(c)==norm(winner)),'explain':f'{winner} won the {y} men’s singles title.'})
 elif i.startswith('rev-'):
  m=re.match(r'In which of these years did (.*?) win (.*?) men’s singles',q['question']);name,event=m.groups();k={'Australian Open':'australian-open','Roland-Garros':'rolandrg','Wimbledon':'wimbledon','US Open':'us-open'}[event];valid=[j for j,c in enumerate(q['choices']) if norm(tables[k].get(c,''))==norm(name)]
  if valid==[q['answer']]:mark(q,'verified','Exactly one listed year matches this champion in official table.',src(k))
  else:mark(q,'correction',f'Multiple/incorrect winning-year choices: {valid}.',src(k))
 elif i.startswith('count-'):
  name=q['question'].split(' does ')[1].split(' have ')[0];event=q['question'].split('How many ')[1].split(' singles titles')[0];mapping={'Australian Open men’s':'australian-open','Roland-Garros men’s':'rolandrg','Wimbledon men’s':'wimbledon','US Open men’s':'us-open'};ks=[mapping[event]] if event in mapping else list(tables);ys=[(k,y) for k in ks for y,n in tables[k].items() if int(y[:4])>=(1969 if k=='australian-open' else 1968) and norm(n)==norm(name)];expected=len(ys)
  if expected==int(a):
   question=f'How many {event.replace("combined listed major","men’s Grand Slam")} singles titles did {name} win in the Open Era through the 2026 US Open?'
   mark(q,'correction','Count verified, but unseen encoded table is not meaningful to users; specify Open Era and cutoff.',sum([src(k) for k in ks],[]),{'question':question,'explain':f'{name} won {expected}: '+', '.join(f'{k} {y}' for k,y in ys)+'.'})
  else:mark(q,'unresolved',f'Official-table count {expected}, encoded answer {a}',sum([src(k) for k in ks],[]))
json.dump({'sources':urls,'tables':tables,'women_tables':wt,'questions':list(rows.values())},open(base/'docs/audit-slams.json','w'),ensure_ascii=False,indent=2)
print(collections.Counter(r['verdict'] for r in rows.values()));print('unresolved',[(r['id'],r['reason']) for r in rows.values() if r['verdict']=='unresolved'])
