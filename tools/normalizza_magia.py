"""Normalizza magia_grezza.json in json/magic.json (valori numerici e categorie)."""
import json, re, sys
sys.path.insert(0, "/home/claude/dq/tools")
from nomi_magia_it import N as NOMI_IT, NOMI_EN_CORRETTI
d = json.load(open('/home/claude/dq/magia_grezza.json'))
TIPI = {'T': 'talento', 'G': 'incantesimo_generale', 'S': 'incantesimo_speciale', 'Q': 'rituale_generale', 'R': 'rituale_speciale'}

def num(s):
    if s is None: return None
    s = s.replace('—', '-').replace('~', '-').replace('O', '0').replace('o', '0')
    m = re.search(r'(-?)\s*-?\s*(\d+)', s)
    if not m: return None
    v = int(m.group(2))
    return -v if ('-' in s[:m.start(2)] ) else v

def resistenza(s):
    if not s: return None
    l = s.lower()
    if 'disbeliev' in l: return 'disbelief'
    if 'cannot' in l or l.startswith('no') and 'yes' not in l: return 'none'
    if 'active' in l and 'passive' in l and 'only' not in l: return 'active_passive'
    if 'actively' in l and 'not passively' in l: return 'active'
    if 'passive' in l: return 'passive'
    if 'active' in l: return 'active'
    return 'special'

def pulisci(t):
    t = re.sub(r'\s+', ' ', t or '').strip()
    return t.replace(' ,', ',').replace(' .', '.')

out = {"_source": "DragonQuest 3e TSR, Book Two (rules 36-48), estratto da OCR e verificato a campione",
       "branches": {"Thaumaturgies": "Taumaturgie", "Elementals": "Elementali", "Entities": "Entità"},
       "branch_alignment_34_1": {"same": 20, "opposed": -20, "neutral": 0, "non_adept_target": 20,
                                 "opposed_pairs": [["Thaumaturgies", "Entities"]]},
       "colleges": []}
problemi = []
for c in d:
    voci = []
    for e in c['entries']:
        f = e['fields']
        body = pulisci(e['body'])
        v = {"code": e['code'], "n": e['n'], "type": TIPI[e['code'][0]], "name": pulisci(e['title']).replace('Speil', 'Spell').replace('Hlusion', 'Illusion').replace('Eantastical', 'Fantastical').replace('Summonin ', 'Summoning ').rstrip(' (')}
        if e['code'][0] in 'GS':
            v.update({"range": pulisci(f.get('range')), "duration": pulisci(f.get('duration')),
                      "experience_multiple": num(f.get('em')), "base_chance": num(f.get('base')),
                      "resist": resistenza(f.get('resist')), "resist_text": pulisci(f.get('resist')),
                      "effects": pulisci(f.get('effects') or body)})
        else:
            testo = body
            m = re.search(r'Experience Multiple[^0-9]{0,40}?(\d{2,4})', testo, re.I)
            b = re.search(r'Base Chance[^0-9%]{0,60}?(-?\d{1,3})\s*%', testo, re.I)
            v.update({"experience_multiple": int(m.group(1)) if m else None,
                      "base_chance": int(b.group(1)) if b else None, "text": testo})
        if v.get('experience_multiple') is None and v['type'] != 'talento':
            problemi.append((c['num'], e['code'], 'EM'))
        voci.append(v)
    for v in voci:
        v['name'] = NOMI_EN_CORRETTI.get((c['num'], v['code']), v['name'])
        v['nome'] = NOMI_IT.get((c['num'], v['code']))
        if v['nome'] is None:
            problemi.append((c['num'], v['code'], 'NOME_IT'))
    gk = [v for v in voci if v['type'] in ('incantesimo_generale', 'rituale_generale')]
    out['colleges'].append({"num": c['num'], "name": c['name'], "nome": c['nome'], "branch": c['branch'],
        "requirements": pulisci(c['sections'].get('1', '')), "modifiers": pulisci(c['sections'].get('2', '')),
        "general_knowledge_count": len(gk), "entries": voci})
# rinvii del manuale: copia i dati dall'incantesimo di riferimento
def trova(num, code):
    for c in out['colleges']:
        if c['num'] == num:
            for v in c['entries']:
                if v['code'] == code:
                    return v
for (dn, dc), (sn, sc), campi, nota in [
        ((41, 'G-9'), (40, 'G-3'), ['range', 'duration', 'experience_multiple', 'base_chance', 'resist', 'resist_text', 'effects'], "Identico a Magie dell'Aria G-3."),
        ((44, 'S-7'), (44, 'S-6'), ['range', 'duration', 'experience_multiple', 'base_chance', 'resist', 'resist_text'], "Come S-6 ma colpisce solo creature della luce; solo Dark Mage o Shadow Weaver."),
        ((36, 'G-2'), (37, 'S-9'), ['base_chance'], "Base Chance come Stregonerie della Mente S-9.")]:
    d_, s_ = trova(dn, dc), trova(sn, sc)
    for k in campi:
        d_[k] = s_[k]
    d_['note'] = nota
# rituali di vincolo R-8..R-21 della Forgiatura (elencati in blocco nel manuale)
forg = next(c for c in out['colleges'] if c['num'] == 47)
VINCOLI = ["Shaping Magics", "Ensorcelments and Enchantments", "Sorceries of the Mind", "Illusionary Magics", "Naming Magics",
           "Air Magics", "Water Magics", "Fire Magics", "Earth Magics", "Celestial Magics", "Necromantic Conjurings",
           "Summoning Magics", "Rune Magics", "Non-Magical Abilities"]
VINCOLI_IT = ["Magie della Forgiatura", "Incantamenti e Ammaliamenti", "Stregonerie della Mente", "Magie illusorie", "Magie dei Nomi",
              "Magie dell'Aria", "Magie dell'Acqua", "Magie del Fuoco", "Magie della Terra", "Magie Celesti", "Evocazioni Negromantiche",
              "Magie di Evocazione", "Magie delle Rune", "Abilità non magiche"]
pos = next(i for i, v in enumerate(forg['entries']) if v['code'] == 'R-22')
for i, (en, it) in enumerate(zip(VINCOLI, VINCOLI_IT)):
    forg['entries'].insert(pos + i, {"code": f"R-{8 + i}", "n": 8 + i, "type": "rituale_speciale", "name": f"Ritual of Binding {en}",
        "nome": f"Rituale di Vincolo: {it}", "experience_multiple": 250, "base_chance": 50,
        "text": "Base Chance 50% (+2/Rank), Experience Multiple 250. Lega nell'oggetto preparato un'abilità di questo tipo."})
# correzioni verificate sulle scansioni
trova(42, 'S-6')['base_chance'] = 20          # l'OCR legge "20%" come "209%"
trova(36, 'S-4')['note'] = "Il manuale non riporta la Base Chance."
for c in out['colleges']:
    for v in c['entries']:
        for k in ('range', 'duration'):
            if isinstance(v.get(k), str):
                v[k] = re.sub(r'\b(additional )?per$', r'\1per Rank', v[k].strip()).replace('}', ')').rstrip('-').strip()
problemi = [p for p in problemi if not (p[0] == 41 and p[1] == 'G-9') and not (p[0] == 44 and p[1] == 'S-7')]
out['counterspells_31_3'] = {"range": "25 feet +25 additional/Rank", "duration": "(D10+5) minutes +1/Rank",
    "experience_multiple": {"general": 100, "special": 200}, "base_chance": 40, "resist": "passive",
    "effect": "+30 (+3/Rank) alla Magic Resistance contro gli incantesimi (generali o speciali) del Collegio, su una figura o su un'area di 7 esagoni",
    "learn_cost_sp": {"other_college": 2000, "namer": 500}}
out['casting_rules'] = {
    "fatigue_cost": {"general": 1, "special": 2}, "prepare_pulses": 1, "loose_pulses": 1,
    "cast_mods_27_7": {"per_ma_over_15": 1, "per_ma_under_15": -1, "per_rank": 3, "per_hour_preparation": 3, "max_hours": 10},
    "triple_if_roll_le_pct": 5, "double_if_roll_le_pct": 15,
    "backfire_if_roll_over_cast_by": {"combat": 30, "adventure": 40},
    "resistance_base": "Willpower", "concentration_check": "D100 <= 4 x WP",
    "max_spells_rank_le5": "Magical Aptitude", "max_rank": 20,
    "xp_cost_91_4": "Experience Multiple x Rank da raggiungere; per incantesimi e rituali generali -5% per ogni punto di MA oltre 15",
    "special_knowledge_learn": {"weeks": "ordinale/2 per eccesso", "sp": "200 x ordinale"},
    "cold_iron_29_1": "Niente incantesimi a contatto con ferro freddo (armature metalliche, armi di ferro/acciaio)"}
json.dump(out, open('/home/claude/dq/json/magic.json', 'w'), ensure_ascii=False, indent=1)
print('voci', sum(len(c['entries']) for c in out['colleges']))
for c in out['colleges']:
    print(c['num'], c['name'], 'GK', c['general_knowledge_count'])
print('senza EM:', problemi)
