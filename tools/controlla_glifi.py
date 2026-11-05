"""Controlla che ogni carattere delle stringhe nel codice e nei JSON esista nei font del gioco.
Uso: python3 tools/controlla_glifi.py  (richiede fonttools)"""
import glob, json, os, re, sys
from fontTools.ttLib import TTFont

RADICE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
font = {os.path.basename(f): set(TTFont(f).getBestCmap()) for f in glob.glob(os.path.join(RADICE, "assets/font/*.ttf"))}
testi = []
for f in glob.glob(os.path.join(RADICE, "scripts/*.gd")) + glob.glob(os.path.join(RADICE, "tests/*.gd")):
    for riga in open(f, encoding="utf-8"):
        codice = riga.split("#")[0] if '"' not in riga.split("#")[0] else riga
        testi += re.findall(r'"((?:[^"\\]|\\.)*)"', codice)
def raccogli(o):
    if isinstance(o, str): testi.append(o)
    elif isinstance(o, dict): [raccogli(v) for v in o.values()]
    elif isinstance(o, list): [raccogli(v) for v in o]
for f in glob.glob(os.path.join(RADICE, "data/*.json")):
    raccogli(json.load(open(f, encoding="utf-8")))
mancanti = {}
for t in testi:
    for ch in t:
        if ch in "\n\t": continue
        for nome, cmap in font.items():
            if ord(ch) not in cmap:
                mancanti.setdefault(nome, set()).add(ch)
if mancanti:
    for nome, chars in mancanti.items():
        print(f"{nome}: mancano {' '.join(sorted(repr(c) for c in chars))}")
    sys.exit(1)
print(f"Glifi OK: {len(font)} font, {len(testi)} stringhe controllate.")
