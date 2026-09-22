exec(open('/tmp/audit_slams.py').read().split("json.dump({'sources'")[0])
byid={q['id']:q for q in qs}
def v(ids,key,reason='Checked against official records.'):
 for i in ids.split():mark(byid[i],'verified',reason,[urls.get(key,key)])
def c(i,rep,reason,key):mark(byid[i],'correction',reason,[urls.get(key,key)],rep)
v('slam-01 card-17 city-Roland-Garros','rg-surf');v('slam-02 card-18 city-Wimbledon','wi');v('slam-04 slam-05 card-23 card-24 wh-13','itf');v('slam-08 card-21','rg');v('slam-09 card-22 match-1 match-3','wi');v('slam-13 card-37 card-38','us-surf');v('slam-10 extra-8 extra-9 extra-10 extra-11 extra-12 wh-24 wh-26 wh-34 wh-36 wh-48 wh-49 wh-50 wh-51 wh-67 wh-69 wd-02 wd-03 wd-07 wd-09 wd-10 wd-17 wd-20 wd-25','wta')
# Remove subjective/unsupported side assertions even where the key is correct.
c('slam-10',{'explain':'Margaret Court won 24 major singles titles; Serena Williams won 23 and Steffi Graf won 22. Court’s total includes amateur-era titles.'},'Remove unsupported weaker-era judgment.','wta')
c('wh-12',{'explain':'Court won 24 major singles titles: 11 in Australia, five in France, three at Wimbledon and five at the US championships. Serena Williams holds the Open Era women’s record with 23.'},'Remove subjective weaker-field commentary.','wta')
c('slam-11',{'explain':'Isner won the fifth set 70–68. The first-round match lasted 11 hours 5 minutes across three days.'},'Record correct; unsupported causal claim about all deciding-set tiebreaks removed.','wi')
for i in ['slam-06','card-25','wh-29']:
 q=byid[i];c(i,{'question':q['question'].replace('in singles','in women’s singles outside wheelchair tennis').replace('only player','only non-wheelchair singles player'),'explain':'Steffi Graf won all four women’s singles majors and Olympic singles gold in 1988. Diede de Groot also achieved a calendar Golden Slam in wheelchair singles in 2021.'},'Original universal only-player/singles claim excludes wheelchair Golden Slams; scope explicitly.','itf')
c('oly-2',{'question':'A calendar-year Golden Slam adds what to the four major singles titles?'},'Golden Slam needs explicit calendar-year qualifier.','itf')
c('wh-56',{'question':'Through the 2026 US Open, who holds the Open Era women’s record for Grand Slam singles match wins?','explain':'Serena Williams leads the official WTA Open Era table with 367 wins. Martina Navratilova has 306 and Chris Evert 299.'},'Specify table scope; remove misleading Venus-next implication.','wta')
c('wh-62',{'question':'Which woman completed a career Golden Slam in singles by winning Olympic gold in 2012?','choices':['Serena Williams','Venus Williams','Maria Sharapova','Victoria Azarenka'],'answer':0,'explain':'Serena Williams completed the career Golden Slam with Olympic singles gold at London 2012. Venus has won Wimbledon and the US Open in singles, but neither the Australian Open nor Roland-Garros.'},'Venus missing two majors, not only RG. Original answer oddly framed.','wta')
c('wd-13',{'question':'How many women’s doubles major titles did Louise Brough and Margaret Osborne duPont each win?','choices':['21 each','14 and 15','31 each','12 and 16'],'answer':0,'explain':'Brough and duPont each won 21 women’s doubles majors. They won 20 major titles together.'},'Original keyed 14 and 15 contradicts actual 21 each.','wta')
c('wd-14',{'question':'How many major titles did Elizabeth Ryan win in women’s doubles?','choices':['17','19','21','26'],'answer':0,'explain':'Ryan won 17 women’s doubles majors and nine mixed doubles majors, for 26 in total. Her 19 Wimbledon titles combined women’s doubles and mixed doubles.'},'19 Wimbledon combined titles was confused with all-major women’s doubles total 17.','wta')
c('wd-15',{'explain':'Fernández and Zvereva won 14 women’s doubles majors together. Zvereva won 18 individually; Navratilova won 31 and Shriver 21 in the Open Era.'},'Zvereva is third, not second, in Open Era individual doubles table.','wta')
c('wd-06',{'question':'Which woman completed the 1963 mixed doubles calendar Grand Slam with Ken Fletcher?','choices':['Margaret Court','Billie Jean King','Martina Navratilova','Doris Hart'],'answer':0,'explain':'Margaret Court, then Margaret Smith, and Ken Fletcher won all four mixed doubles majors in 1963. Owen Davidson also completed a mixed doubles calendar Grand Slam in 1967.'},'Only player is wrong (Fletcher and Davidson); avoid shared-1965 title counting ambiguity.','itf')
c('wd-04',{'question':'How many women’s doubles Grand Slam titles did Martina Navratilova and Pam Shriver win as a team?','explain':'They won 20 majors as a team, including all four in 1984. They won eight consecutive majors from Wimbledon 1983 through Roland-Garros 1985.'},'Specify women’s doubles; generic only pairing ignores 1951 men’s pair.','wta')
c('wd-18',{'explain':'Krejčíková and Siniaková won all four women’s doubles majors, Olympic doubles gold in Tokyo, and the 2021 WTA Finals together. Krejčíková also won singles titles at Roland-Garros 2021 and Wimbledon 2024.'},'Original claims they split singles majors, and unspecified active-title leader, are misleading/unsupported.','https://www.itftennis.com/en/news-and-media/articles/krejcikova-and-siniakova-named-itf-world-champions-for-a-third-time/')
c('wd-01',{'explain':'Court won 64 major titles: 24 singles, 19 women’s doubles and 21 mixed doubles. This count includes shared Australian mixed doubles titles in 1965 and 1969.'},'Avoid universal most-majors-by-anyone claim across wheelchair categories.','wta')
c('wh-22',{'explain':'Billie Jean King won 12 singles majors: six Wimbledon, four US, one Australian and one French title. She completed her singles career Grand Slam at Roland-Garros in 1972.'},'Keep verified singles breakdown; remove erroneous 1973 Wimbledon triple crown (King lost singles semifinal).','wta')
c('wh-31',{'explain':'Graf won 22 singles majors: seven Wimbledon, six French, five US and four Australian titles. She is the only non-wheelchair singles player to win each major at least four times.'},'Scope universal claim explicitly.','wta')
c('wh-35',{'explain':'The sisters met in nine Grand Slam singles finals; Serena won seven. Serena won their four consecutive finals from Roland-Garros 2002 through the Australian Open 2003.'},'Remove unsupported relative-ranking aside.','https://www.wtatennis.com/news/2768410/wta-honors-inspirational-career-of-serena-williams-press-release-after-loss')
v('wd-24','https://www.usopen.org/en_US/visit/history/xdchamps.html')
v('wh-53','https://www.wtatennis.com/news/2546840/world-no1-ashleigh-barty-announces-retirement')
# Stable scoped counts from complete current official tables.
for i in ['slam-07','card-20']:
 c(i,{'question':'Through the 2026 US Open, which man had won the most Grand Slam singles titles?','explain':'Novak Djokovic had won 24, Rafael Nadal 22 and Roger Federer 20.'},'Replace vague mid-2020s qualifier with explicit cutoff.','ao')
# WTA honor rolls verify women nationality (country represented, not birthplace).
for n in range(5,9):
 q=byid[f'id-{n}'];c(q['id'],{'question':q['question'].replace('Which country is','Which country does').replace(' from?',' represent in tennis?')},'Country represented avoids Rybakina birthplace/citizenship ambiguity.','wta')
for n in range(5):v(f'id-{n}','ao')
v('id-9','https://www.atptour.com/en/players/rafael-nadal/n409/overview')
v('id-10','https://www.atptour.com/en/players/roger-federer/f324/overview')
v('id-11','https://www.atptour.com/players/novak-djokovic/d643/overview')
v('wh-22','https://www.wtatennis.com/news/4496793/legend-bio-billie-jean-king')
rows['wh-22'].pop('replacement',None)
v('wh-53','https://www.wtatennis.com/news/2546891/wta-world-no1-ashleigh-barty-announces-retirement-from-professional-tennis')
c('wh-30',{'explain':'Graf won the 1988 Roland-Garros final 6–0, 6–0 in about 32 minutes of playing time.'},'Keep independently verified score and duration; remove unneeded all-season and subjective claims.','https://ausopen.com/articles/news/bradtke-reflects-on-1988-roland-garros-semifinal-run')
c('wh-55',{'question':'How many Grand Slam singles finals did Chris Evert reach?','explain':'Chris Evert reached 34 major singles finals and won 18. She reached at least the semifinals at 52 of her 56 major appearances.'},'Specify direct count rather than unsourced cross-era superlative.','wta')
rows['wh-55']['sources'].append('https://www.wtatennis.com/legends/50020/-')
# Calendar normal order is supported by current official tournament calendar and parent supplement.
supp=json.load(open(base/'docs/audit-slams-supplement.json'))
print(type(supp))
for q in qs:
 if q['id'].startswith('rev-') and rows[q['id']]['verdict']=='correction':
  name,event=re.match(r'In which of these years did (.*?) win (.*?) men’s singles',q['question']).groups()
  k={'Australian Open':'australian-open','Roland-Garros':'rolandrg','Wimbledon':'wimbledon','US Open':'us-open'}[event]
  choices=list(q['choices']);used=set(choices)
  for j,year in enumerate(choices):
   if j!=q['answer'] and norm(tables[k].get(year,''))==norm(name):
    replacement=next(y for y,n in tables[k].items() if int(y[:4])>=1968 and y.isdigit() and y not in used and norm(n)!=norm(name))
    choices[j]=replacement;used.add(replacement)
  rows[q['id']]['replacement']={'choices':choices}
# Parent has sourced normal calendar-order question.
parent=next(r for r in supp['entries'] if r['id']=='slam-03')
mark(byid['card-19'],'correction','Specify normal annual order; exceptional pandemic calendar differed.',parent['sources'],{'question':'In a normal modern season, what is the calendar order of the four majors?'})
# Additional review remains explicitly unresolved where no source was read.
for r in rows.values():
 if r.get('replacement',{}).get('explain'):r['replacement']['explain']=r['replacement']['explain'].replace('title The tournament','title. The tournament')
json.dump({'sources':urls,'tables':tables,'women_tables':wt,'questions':list(rows.values())},open(base/'docs/audit-slams.json','w'),ensure_ascii=False,indent=2)
print(collections.Counter(r['verdict'] for r in rows.values()));print([r['id'] for r in rows.values() if r['verdict']=='unresolved'])
