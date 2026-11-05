"""Traduce in italiano i campi portata, durata e resistenza delle voci magiche.

Uso: from traduci_campi import portata, durata, resistenza
Prima pulisce gli errori di OCR più frequenti, poi applica regole regex,
infine una tabella di casi particolari scritti a mano.
"""
import re

# Casi particolari (testo originale ripulito -> traduzione)
SPECIALI = {
    # portata
    "Works at any range": "Qualunque distanza",
    "Works at any": "Qualunque distanza",
    "Unlimited within sight": "Illimitata, entro il campo visivo",
    "Caster must touch target": "L'incantatore deve toccare il bersaglio",
    "Caster must touch spell's target": "L'incantatore deve toccare il bersaglio",
    "Caster must touch the water": "L'incantatore deve toccare l'acqua",
    "Caster must touch object to be mended": "L'incantatore deve toccare l'oggetto da riparare",
    "Caster must shape object and touch it to cast spell": "L'incantatore deve modellare l'oggetto e toccarlo",
    "Can be cast over self only": "Solo su se stessi",
    "Can only be cast over self": "Solo su se stessi",
    "Can only be cast over self or adjacent character": "Solo su se stessi o su un personaggio adiacente",
    "Can only be cast over an adjacent character": "Solo su un personaggio adiacente",
    "Adept must touch": "L'Adept deve toccare il bersaglio",
    "Adept must touch target": "L'Adept deve toccare il bersaglio",
    "Adept must touch subject": "L'Adept deve toccare il soggetto",
    "Adept must touch target with": "L'Adept deve toccare il bersaglio con la Bacchetta runica",
    "Adept must touch the water to be transmuted": "L'Adept deve toccare l'acqua da trasmutare",
    "Adept must touch water": "L'Adept deve toccare l'acqua",
    "Adept must touch substance from which water is drawn": "L'Adept deve toccare la sostanza da cui estrae l'acqua",
    "Adept must touch the target's eyes": "L'Adept deve toccare gli occhi del bersaglio",
    "Adept must touch target's throat": "L'Adept deve toccare la gola del bersaglio",
    "Adept must touch object or entity over which spell is cast": "L'Adept deve toccare l'oggetto o l'entità",
    "Adept must touch Runestick used and it must remain in sight": "L'Adept deve toccare il Bastoncino runico, che deve restare in vista",
    "Adept must touch element with": "L'Adept deve toccare l'elemento con il Bastoncino runico",
    "Must touch object or substance": "Bisogna toccare l'oggetto o la sostanza",
    "Touch subject until Rank 10": "Contatto fino al Rank 10",
    "Adept with less than Rank 10 must touch subject. From Rank 10 and above, 10 feet (+1/Rank above 10)":
        "Contatto sotto il Rank 10; dal Rank 10, 10 piedi (+1 per Rank oltre il 10)",
    "Touch of": "Tocco della Bacchetta runica",
    "Touch with": "Tocco della Bacchetta runica",
    "Substance must be touched with": "La sostanza va toccata con il Bastoncino runico",
    "Target must be painted with": "Il bersaglio va dipinto con la runa",
    "Target must be touched with Runesticks DURATION: So long as Runesticks are worn":
        "Il bersaglio va toccato con i Bastoncini runici",
    "15 feet +15 feet for every 2 or fraction of 2": "15 piedi (+15 piedi ogni 2 Rank o frazione)",
    "25 feet X": "25 piedi x Rank",
    "10 feet + additional/Rank": "10 piedi (+10 per Rank)",
    "20 feet 20 additional/Rank": "20 piedi (+20 per Rank)",
    "10 feet (+5/Rank) X1, if unranked": "10 piedi (+5 per Rank)",
    "30 feet +30 additional per The entity is pinpointed whenever his thoughts are read":
        "30 piedi (+30 per Rank)",
    "30 feet +30 additional/Rank All objects and entities within 20 feet of the vortex must successfully resist or they are sucked into the eye of the vortex and down to the seabottom. This spell will only be effective if cast over a large body of water (sea, ocean, or lake)":
        "30 piedi (+30 per Rank). Funziona solo su una grande distesa d'acqua (mare, oceano o lago)",
    # durata
    "Concentration/no maximum": "Concentrazione, senza limite",
    "Concentration: no maximum": "Concentrazione, senza limite",
    "Concentration/maximum: 15": "Concentrazione, massimo 15 minuti (+15 per Rank)",
    "Concentration/maximum of 1 hour2*": "Concentrazione, massimo 1 ora (+2 per Rank)",
    "Concentration/maximum of 1 hour + additional per Rank": "Concentrazione, massimo 1 ora (+1 per Rank)",
    "Until dispelled": "Finché non viene dissolto",
    "Until dispelled by the appropriate counterspell": "Finché non viene dissolto dal controincantesimo adatto",
    "Until dispelled or broken": "Finché non viene dissolto o spezzato",
    "Permanent until dispelled": "Permanente finché non viene dissolto",
    "Infinite until dispelled": "Illimitata finché non viene dissolto",
    "Variable according to": "Variabile secondo il tipo",
    "Depends on type of golem": "Dipende dal tipo di golem",
    "Immediate Experience": "Immediato",
    "Immediate": "Immediato",
    "Immediate (during Pulse, if desired)": "Immediato (nel Pulse, se si vuole)",
    "1 hour+1 additional per Rank (until dispelled at Rank 20)":
        "1 ora (+1 per Rank); al Rank 20 finché non viene dissolto",
    "Ranks 1-10 =a fortnight; Ranks 1119=3 months; Rank 20= dispelled":
        "Rank 1-10: due settimane; Rank 11-19: 3 mesi; Rank 20: finché non viene dissolto",
    "3 hours+30 additional minutes/": "3 ore (+30 minuti per Rank)",
    "30 seconds * (D -2)X": "30 secondi x (D10-2) x Rank",
    "15 minutes * Rank unranked)": "15 minuti x Rank (x1 senza Rank)",
    "D10 hours* Rank unranked)": "D10 ore x Rank (x1 senza Rank)",
    "1 minute +10 additional seconds/2 Ranks (or fraction)": "1 minuto (+10 secondi ogni 2 Rank o frazione)",
    "Rank X6 minutes (6 minutes, if unranked)": "Rank x 6 minuti (6 minuti senza Rank)",
    "5 minutes * DIOX Rank (X1, if unranked)": "5 minuti x D10 x Rank (x1 senza Rank)",
    # resistenza
    "No/Yes": "Variabile",
    "Variable (see below)": "Variabile (vedi testo)",
}

UNITA = {
    "feet": "piedi", "foot": "piede", "Feet": "piedi", "miles": "miglia", "mile": "miglio",
    "hours": "ore", "hour": "ora", "minutes": "minuti", "minute": "minuto",
    "seconds": "secondi", "second": "secondo", "days": "giorni", "day": "giorno",
    "weeks": "settimane", "week": "settimana", "years": "anni", "year": "anno",
}
U = r"(feet|foot|Feet|miles|mile|hours|hour|minutes|minute|seconds|second|days|day|weeks|week|years|year)"


def pulisci(s):
    s = s.strip().lstrip(";").strip()
    s = s.replace("¥", "X").replace("®", "").replace("%1", "*1").replace("X14", "X1")
    s = s.replace("*X", "X").replace("{", "(").replace("+S", "+5").replace("ne maximum", "no maximum")
    s = s.replace("1. additional", "1 additional").replace("1 hour)", "1 hour").replace("/Rank))", "/Rank)")
    s = re.sub(r"\s+", " ", s)
    s = s.rstrip(" ,.'a").rstrip()
    s = s.replace("Concentration: No maximum", "Concentration: no maximum")
    return s


def _unita(s):
    return re.sub(r"\b" + U + r"\b", lambda m: UNITA[m.group(1)], s)


def _formula(s):
    """Traduce le formule numeriche comuni."""
    t = s
    # "X +Y additional per Rank" / "X +Y additional/Rank" / "X (+Y/Rank)"
    t = re.sub(r"(\d+) " + U + r" ?\+ ?(\d+) additional ?(?:per ?|/ ?)[Rr]ank",
               lambda m: f"{m.group(1)} {UNITA[m.group(2)]} (+{m.group(3)} per Rank)", t)
    t = re.sub(r"(\d+) " + U + r" ?\+ ?(\d+) additional " + U + r" ?/ ?Rank",
               lambda m: f"{m.group(1)} {UNITA[m.group(2)]} (+{m.group(3)} {UNITA[m.group(4)]} per Rank)", t)
    t = re.sub(r"(\d+) " + U + r" \( ?\+ ?(\d+)/Rank\)",
               lambda m: f"{m.group(1)} {UNITA[m.group(2)]} (+{m.group(3)} per Rank)", t)
    t = re.sub(r"(\d+) " + U + r" \( ?\+ ?(\d+) " + U + r"/Rank\)",
               lambda m: f"{m.group(1)} {UNITA[m.group(2)]} (+{m.group(3)} {UNITA[m.group(4)]} per Rank)", t)
    t = re.sub(r"(\d+) " + U + r" \+ ?(\d+) " + U + r"/Rank",
               lambda m: f"{m.group(1)} {UNITA[m.group(2)]} (+{m.group(3)} {UNITA[m.group(4)]} per Rank)", t)
    # moltiplicazioni con dado: "20 seconds X (D -5) X Rank (1, if unranked)"
    t = re.sub(r"(\d+|D10) " + U + r" ?[X*x] ?[\[(]? ?D ?-? ?(\d)[\])]? ?[X*x¥] ?Rank.*",
               lambda m: f"{m.group(1)} {UNITA[m.group(2)]} x (D10-{m.group(3)}) x Rank (x1 senza Rank)", t)
    t = re.sub(r"(\d+|D10) " + U + r" ?[X*x] ?D10 ?[X*x] ?Rank.*",
               lambda m: f"{m.group(1)} {UNITA[m.group(2)]} x D10 x Rank (x1 senza Rank)", t)
    t = re.sub(r"^(D10) " + U + r" ?[X*x] ?Rank.*",
               lambda m: f"D10 {UNITA[m.group(2)]} x Rank (x1 senza Rank)", t)
    t = re.sub(r"(\d+) " + U + r" ?[X*x/] ?Rank.*",
               lambda m: f"{m.group(1)} {UNITA[m.group(2)]} x Rank (x1 senza Rank)", t)
    t = re.sub(r"^(\d+) " + U + r" ?[X*x] ?Rank$", lambda m: f"{m.group(1)} {UNITA[m.group(2)]} x Rank", t)
    t = re.sub(r"D10 " + U + r" \+(\d+) additional per Rank",
               lambda m: f"D10 {UNITA[m.group(1)]} (+{m.group(2)} per Rank)", t)
    t = _unita(t)
    return t


def portata(s):
    if not s:
        return s
    p = pulisci(s)
    if p in SPECIALI:
        return SPECIALI[p]
    return _formula(p)


def durata(s):
    if not s:
        return s
    p = pulisci(s)
    if p in SPECIALI:
        return SPECIALI[p]
    if re.fullmatch(r"[Ii]mmediate \(during [Pp]ulse\)", p):
        return "Immediato (nel Pulse)"
    m = re.match(r"Concentration ?[/:;] ?(?:maximum|max)(?: of|:)? (.*)", p)
    if m:
        return "Concentrazione, massimo " + _formula(m.group(1))
    return _formula(p)


def resistenza(s):
    if not s:
        return s
    p = pulisci(s)
    if p in SPECIALI:
        return SPECIALI[p]
    p = p.replace("actively.", "actively").replace("actively and", "actively &").replace("actively or", "actively &")
    meta = "(then suffers half damage)" in p or "(then suffers half damage" in p
    base = p.split("(")[0].strip()
    tab = {
        "Cannot be resisted": "Non si può resistere",
        "Can be actively & passively resisted": "Resistenza attiva e passiva",
        "Can only be passively resisted": "Solo resistenza passiva",
        "Can be passively resisted": "Resistenza passiva",
        "Can only passively resist": "Solo resistenza passiva",
        "Can be actively resisted": "Resistenza attiva",
        "Can only be actively resisted": "Solo resistenza attiva",
        "Must be disbelieved instead of resisted": "Si deve non credere invece di resistere",
    }
    t = tab.get(base, p)
    if meta:
        t += " (chi resiste subisce metà danno)"
    return t


if __name__ == "__main__":
    import json, sys
    d = json.load(open(sys.argv[1] if len(sys.argv) > 1 else "json/magic.json"))
    for c in d["colleges"]:
        for e in c["entries"]:
            for f, fn in (("range", portata), ("duration", durata), ("resist_text", resistenza)):
                if e.get(f):
                    print(f, "|", e[f], "=>", fn(e[f]))
