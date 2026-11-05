"""Estrae i 13 Collegi di magia dal testo OCR (pagine PDF 42-85) in una struttura JSON."""
import re, json, sys

RAW = open('/home/claude/dq/magic_raw.txt').read()

COLLEGI = [
 (36, "Ensorcelments and Enchantments", "Incantamenti e Ammaliamenti", "Thaumaturgies"),
 (37, "Sorceries of the Mind", "Stregonerie della Mente", "Thaumaturgies"),
 (38, "Illusions", "Illusioni", "Thaumaturgies"),
 (39, "Naming Incantations", "Incantesimi dei Nomi", "Thaumaturgies"),
 (40, "Air Magics", "Magie dell'Aria", "Elementals"),
 (41, "Water Magics", "Magie dell'Acqua", "Elementals"),
 (42, "Fire Magics", "Magie del Fuoco", "Elementals"),
 (43, "Earth Magics", "Magie della Terra", "Elementals"),
 (44, "Celestial Magics", "Magie Celesti", "Elementals"),
 (45, "Necromantic Conjurations", "Evocazioni Negromantiche", "Entities"),
 (46, "Summoning", "Evocazioni", "Entities"),
 (47, "Shaping Magics", "Magie della Forgiatura", "Entities"),
 (48, "Rune Magics", "Magie delle Rune", "Entities"),
]

# correzioni puntuali di titoli storpiati dall'OCR (verificate sulle scansioni)
CORREZIONI = [
 ("7. Spell of Speaking With Aquatic\nMamunals (G-", "7. Spell of Speaking With Aquatic Mammals (G-7)\n"),
 ("Ae i of Controlling Sea Mammals", "7. Spell of Controlling Sea Mammals (S-7)"),
 ("4, Fire and Brimstone Spell\n", "4, Fire and Brimstone Spell (G-4)\n"),
 (". Spell of Communication\nvith Fantastical Beasts (S-1)", "1. Spell of Communication with Fantastical Beasts (S-1)"),
 ("4. Ritual of Shaping Flesh Golems (S-4)", "4. Ritual of Shaping Flesh Golems (R-4)"),
 ("6. Ritual of Sending (Q-7)", "6. Ritual of Sending (Q-6)"),
 ("3 Spel of Molecular Rearrangement\n\u201c5", "5. Spell of Molecular Rearrangement (S-5)"),
 ("\n46.5] General Knowledge Rituals", "\n[46.5] General Knowledge Rituals"),
 ("2. Spell of Creating Shadow-Starsword\n(62)", "2. Spell of Creating Shadow-Starsword (S-2)"),
]
for a, b in CORREZIONI:
    if a not in RAW:
        print("ATTENZIONE: correzione non applicata:", a[:40])
    RAW = RAW.replace(a, b)

# ripulisce i numeri di pagina e normalizza gli errori OCR piu comuni
t = re.sub(r'@@PAGE\d+\n', '', RAW)
t = t.replace('—', '-').replace('–', '-').replace('~', '-')
lines = [l.rstrip() for l in t.split('\n')]

starts = {}
for i, l in enumerate(lines):
    m = re.match(r'^(3[6-9]|4[0-8])\. THE COLLEGE OF', l)
    if m and int(m.group(1)) not in starts:
        starts[int(m.group(1))] = i
fine = next(i for i, l in enumerate(lines) if l.startswith('49. NOTES ON MAGIC'))

CAMPI = [
 ('range', r'^(R\s*[a-zA-Z]{2,4}[eE]|RANGE|Rance|Ranpe|RaNnGe|Rance)\s*[:;]'),
 ('duration', r'^(D\w{3,8}[nN]|DURATION|Duration)\s*[:;]'),
 ('em', r'^(E\w*PERIENCE|EXPERIENCE|Experience|EPERIENCE|Exp)\b.*?(MULT|Mult|MuLT|Muttip|MUL|Multi)'),
 ('base', r'^(B\w{2,3}E|BASE|Base)\s*C\w+\s*[:;]'),
 ('resist', r'^(R\w{3,5}[tT]|RESIST|Resist)\s*[:;]'),
 ('effects', r'^(E\w{3,6}[tT][sS]|EFFECTS|Errects|Errecrs|Effects)\s*[:;]'),
]

import difflib
ETICHETTE = {'range': ['range'], 'duration': ['duration'], 'em': ['experiencemultiple', 'experience', 'expmultiple'],
             'base': ['basechance'], 'resist': ['resist'],
             'effects': ['effects', 'errecrs', 'errects', 'errscts', 'ereecrs', 'estecrs', 'esrecrs', 'esrects', 'errecis']}

def campo(l):
    m = re.match(r'^([A-Za-z][A-Za-z .]{2,26}?)\s*[:;]', l)
    if not m:
        m = re.match(r'^((?:B\w{2,4}\s+C\w{4,6}))\s', l)
        if not m:
            return None
    lab = re.sub(r'[^a-z]', '', m.group(1).lower())
    migliore, punteggio = None, 0.0
    for k, nomi in ETICHETTE.items():
        for n in nomi:
            r = difflib.SequenceMatcher(None, lab, n).ratio()
            if r > punteggio:
                migliore, punteggio = k, r
    return migliore if punteggio >= 0.62 else None

voce_re = re.compile(r'^(\d{1,2})\s*[.,]\s*(.+)$')
codice_re = re.compile(r'[\(\{]\s*\(?\s*([TGSRQ58O¥F])\s*-\s*(\d+)\s*[\)\}]\s*\S{0,2}$')
MAPPA_COD = {'5': 'S', '8': 'S', 'O': 'Q', '¥': 'T', 'F': 'T'}
sez_re = re.compile(r'^\[(\d\d)\.(\d)\]\s*(.*)$')

out = []
nums = sorted(starts)
for idx, n in enumerate(nums):
    a = starts[n]
    b = starts[nums[idx + 1]] if idx + 1 < len(nums) else fine
    blocco = lines[a:b]
    meta = next(c for c in COLLEGI if c[0] == n)
    coll = {"num": n, "name": meta[1], "nome": meta[2], "branch": meta[3], "sections": {}, "entries": []}
    sezione = None
    cur = None
    buf_sez = []
    pend_title = None
    for l in blocco[1:]:
        s = l.strip()
        if not s:
            continue
        ms = sez_re.match(s)
        if ms and ms.group(1) == str(n):
            if sezione is not None and cur is None:
                coll['sections'][sezione] = ' '.join(buf_sez).strip()
            sezione = ms.group(2)
            buf_sez = [ms.group(3)]
            cur = None
            pend_title = None
            continue
        # titolo di voce (eventualmente su due righe)
        cand = (pend_title + ' ' + s) if pend_title else s
        mv = voce_re.match(cand)
        if mv and codice_re.search(cand):
            mc = codice_re.search(cand)
            code = MAPPA_COD.get(mc.group(1), mc.group(1))
            cur = {"section": sezione, "code": f"{code}-{mc.group(2)}", "n": int(mv.group(1)),
                   "title": codice_re.sub('', mv.group(2)).strip(), "fields": {}, "body": []}
            coll['entries'].append(cur)
            pend_title = None
            continue
        if mv and not codice_re.search(cand) and len(s) < 60 and pend_title is None and sezione in ('3','4','5','6','7'):
            pend_title = s
            continue
        if pend_title:
            # non era un titolo: rimette il testo nel corpo
            (cur['body'] if cur else buf_sez).append(pend_title)
            pend_title = None
        if cur is None:
            buf_sez.append(s)
            continue
        k = campo(s)
        if k:
            val = re.split(r'[:;]', s, maxsplit=1)[1].strip() if re.search(r'[:;]', s) else re.sub(r'^\S+\s+\S+\s*', '', s)
            if k == 'em':
                val = re.sub(r'^[^0-9]*', '', s)
            cur['fields'][k] = val
            cur['_last'] = k
        else:
            k2 = cur.get('_last')
            if k2:
                cur['fields'][k2] += ' ' + s
            else:
                cur['body'].append(s)
    if sezione is not None and cur is None:
        coll['sections'][sezione] = ' '.join(buf_sez).strip()
    for e in coll['entries']:
        e.pop('_last', None)
        for k in list(e['fields']):
            v = re.sub(r'(\w)- (\w)', r'\1\2', e['fields'][k])
            e['fields'][k] = re.sub(r'\s+', ' ', v).strip()
        e['body'] = re.sub(r'(\w)- (\w)', r'\1\2', ' '.join(e['body'])).strip()
    out.append(coll)

json.dump(out, open('/home/claude/dq/magia_grezza.json', 'w'), ensure_ascii=False, indent=1)
for c in out:
    from collections import Counter
    cnt = Counter(e['code'][0] for e in c['entries'])
    print(c['num'], c['name'], dict(cnt), 'sez:', sorted(c['sections']))

# ---- seconda passata: etichette finite in mezzo alle righe ("... resisted. Errecrs: ...")
def classifica(lab, soglia):
    lab = re.sub(r'[^a-z]', '', lab.lower())
    if len(lab) < 4:
        return None
    best, sc = None, 0.0
    for k, nomi in ETICHETTE.items():
        for n in nomi:
            r = difflib.SequenceMatcher(None, lab, n).ratio()
            if r > sc:
                best, sc = k, r
    return best if sc >= soglia else None

ORDINE = ['range', 'duration', 'em', 'base', 'resist', 'effects']
tok = re.compile(r'(?:(?<=^)|(?<=[\s._]))_?([A-Z][A-Za-z&]{2,11}(?:\s[A-Za-z&]{4,10}){0,2})\s*([:;,.])\s*')
for c in out:
    for e in c['entries']:
        if e['code'][0] not in 'GS':
            continue
        NOMI_PIENI = {'range': 'RANGE', 'duration': 'DURATION', 'em': 'EXPERIENCE MULTIPLE', 'base': 'BASE CHANCE', 'resist': 'RESIST', 'effects': 'EFFECTS'}
        testo = ' '.join(f"{NOMI_PIENI[k]}: {e['fields'][k]}" for k in ORDINE if k in e['fields'])
        if e['body']:
            testo = (e['body'] + ' ' + testo).strip()
        pezzi = []
        for m in tok.finditer(testo):
            k = classifica(m.group(1), 0.8 if m.group(2) in ',.' else 0.62)
            if k:
                pezzi.append((m.start(), m.end(), k))
        if not pezzi:
            continue
        nuovi = {}
        pre = testo[:pezzi[0][0]].strip()
        for i, (a, b, k) in enumerate(pezzi):
            fine_p = pezzi[i + 1][0] if i + 1 < len(pezzi) else len(testo)
            v = testo[b:fine_p].strip()
            if k == 'em':
                v = re.sub(r'^[^0-9]*', '', v)
            if k in nuovi:
                nuovi[k] += ' ' + v
            else:
                nuovi[k] = v
        e['fields'] = nuovi
        e['body'] = pre
json.dump(out, open('/home/claude/dq/magia_grezza.json', 'w'), ensure_ascii=False, indent=1)
