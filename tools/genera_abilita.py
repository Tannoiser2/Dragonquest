"""Genera json/skills.json: abilità del Libro Terzo (52-66) e abilità d'avventura (87)."""
import json
_ = None
COSTI = {  # Experience Point Cost Chart 91.8 (p. 146), Rank 0-10
 "Speak Language": [200, 75, 125, 300, 550, 850, 1350, 1700, 2250, 2900, 3500],
 "Read & Write Language": [250, 100, 150, 350, 700, 950, 1500, 1850, 2500, 3200, 4000],
 "Alchemist": [800, 350, 1200, 2650, 4350, 6500, 8650, 11100, 12750, 14500, 17000],
 "Assassin": [600, 250, 750, 1700, 2900, 4200, 5750, 7550, 9500, 11700, 14100],
 "Astrologer": [400, 150, 500, 1150, 2050, 3100, 4400, 5900, 7500, 9400, 11500],
 "Beast Master": [600, 250, 750, 1650, 2800, 4300, 5600, 7350, 9300, 11400, 13750],
 "Courtier": [250, 100, 200, 500, 950, 1450, 2050, 2800, 3600, 6300, 8000],
 "Healer": [1000, 400, 1600, 3500, 5800, 8400, 11400, 14700, 18500, 22500, 26750],
 "Mechanician": [600, 250, 650, 1500, 2600, 3900, 5300, 7000, 8850, 10900, 13000],
 "Merchant": [300, 125, 300, 850, 1400, 2200, 3400, 4200, 5300, 6800, 9500],
 "Military Scientist": [300, 125, 350, 950, 1500, 2350, 3100, 4150, 5400, 6750, 10000],
 "Navigator": [400, 150, 400, 900, 1550, 2400, 3350, 4450, 5750, 7100, 10500],
 "Ranger": [600, 250, 800, 1650, 2750, 4100, 5650, 7350, 9300, 11400, 13250],
 "Spy": [500, 200, 600, 1400, 2400, 3600, 5000, 6600, 8400, 10400, 12600],
 "Thief": [750, 300, 1050, 2350, 4000, 5750, 7900, 10250, 12900, 14850, 16000],
 "Troubador": [250, 100, 200, 500, 1050, 1450, 2100, 2800, 3900, 4600, 7000],
}
ABILITA = [
 ("speak_language", "Speak Language", "Parlare una lingua", "53", None, "Ogni personaggio parla il Comune a Rank 8; i non umani anche la lingua della razza. Se il Rank nel parlato supera quello nella scrittura, la scrittura costa metà XP (e viceversa)."),
 ("read_write", "Read & Write Language", "Leggere e scrivere una lingua", "53", None, "Umani e mutaforma leggono e scrivono il Comune a Rank 8; gli altri devono impararlo."),
 ("alchemist", "Alchemist", "Alchimista", "54", None, "Analisi chimica da Rank 0; miscele standard da Rank 3, una capacità in più ai Rank 5, 7 e 9: medicine, antidoti, veleni, pozioni (con un Adept o un Healer). Serve un laboratorio e i componenti."),
 ("assassin", "Assassin", "Assassino", "55", "Rank 1 con Sap o Garotte prima di superare il Rank 2", "Ferita grave più probabile in sorpresa (+2%/Rank); danno extra da dietro in mischia; +2/Rank al Knockout col Sap; +2/Rank alla furtività; maneggia veleni senza rischio; interrogatori e memoria addestrata."),
 ("astrologer", "Astrologer", "Astrologo", "56", None, "Previsioni generali e risposte a domande specifiche (fino a Rank al mese); determina l'aspetto di un essere osservandolo; consuma Fatica."),
 ("beast_master", "Beast Master", "Domatore", "57", "Willpower almeno 15", "Addomestica e addestra animali e mostri (un tipo ai Rank 0, 5 e 10); prove di lealtà delle creature."),
 ("courtier", "Courtier", "Cortigiano", "58", "Deve generare la Bellezza fisica (4D5+3)", "Un'abilità sociale per Rank (musica, canto, danza, etichetta); vantaggi e svantaggi di rango a corte; compenso in base al Rank."),
 ("healer", "Healer", "Guaritore", "59", None, "Rank 0 empatia; 1 cura infezioni e malattie; 2 calma il dolore e prolunga la vita; 3 cura ferite (D10 + Rank-5 di Resistenza, fuori dal combattimento) e trasferisce Fatica; 4 neutralizza veleni; 5-7 ripara muscoli, ossa, organi; 8 resuscita; 9-10 rigenera. Ogni uso costa Fatica pari al Rank dell'abilità. Ferma le emorragie delle ferite gravi."),
 ("mechanician", "Mechanician", "Meccanico", "60", "MD sotto 15: +10% XP; MD sopra 22: -10% XP", "Costruisce trappole, serrature e casseforti fino al proprio Rank; trappole magiche con un Adept; congegni utili su richiesta del GM."),
 ("merchant", "Merchant", "Mercante", "61", None, "Compra sotto prezzo, rincara oggetti rari, stima il valore esatto; specializzazioni ogni 3 Rank."),
 ("military_scientist", "Military Scientist", "Stratega", "62", None, "Somma il Rank al tiro d'iniziativa se è il leader, non stordito e non ingaggiato (dal Rank 8 +1 anche ingaggiato); guida e rianima le truppe; intuisce le tattiche nemiche."),
 ("navigator", "Navigator", "Navigatore", "63", None, "Orientamento con le stelle, lettura delle mappe, pilotaggio di navi fino a 25 + 25 x Rank piedi, previsioni del tempo in mare."),
 ("ranger", "Ranger", "Ranger", "64", None, "Senso dell'orientamento; scopre imboscate e trappole con (3 x Percezione + 5 x Rank)%; segue tracce; riconosce piante e prodotti animali; specializzazione in un ambiente."),
 ("spy", "Spy", "Spia", "65", None, "Scassina, trova e disinnesca trappole, passaggi segreti, borseggio, memoria fotografica; +2%/Rank alla furtività. Se il Rank da spia supera quello da ladro, il ladro costa metà XP."),
 ("thief", "Thief", "Ladro", "65", None, "Come la spia per serrature, trappole e borseggio; +1%/Rank alla furtività; contatti nella malavita."),
 ("troubador", "Troubador", "Trovatore", "66", None, "Un'abilità per Rank; +2/Rank alla magia minore; Illusionisti +1/Rank al lancio; +2/Rank alla Percezione sugli umanoidi; travestimento; voce bardica che ammalia."),
]
out = {"_source": "DragonQuest 3e TSR, Book Three, rules 52-66 e Experience Point Cost Chart (p. 146)",
  "rules": {
    "max_rank": 10, "max_success_pct": "90 + Rank",
    "xp_cost": "Costo della tabella per passare al Rank, x moltiplicatore di razza; -10% con maestro di Rank superiore, +25% senza aiuto",
    "starting_option_8_6": "Prima della prima avventura un'abilità a Rank 0 costa solo 100 XP",
    "time": "8 settimane per il Rank 0; poi settimane pari al Rank; maestro 150 x Rank monete",
    "practice_52_6": "Un giorno al mese per abilità, altrimenti si perde un Rank"},
  "skills": [{"id": i, "name": n, "nome": it, "rule": r, "requirement": req, "summary_it": s, "xp_costs": COSTI[n]} for i, n, it, r, req, s in ABILITA],
  "adventure_abilities_87": [
    {"id": "stealth", "name": "Stealth", "nome": "Furtività", "formula": "(3 x Agilità) + (5 x Rank) %", "xp_costs": [0, 500, 1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000], "start_rank": 0,
     "modifiers": "Elfi +10%, Halfling +20%; armatura (Stealth Adjustment); Assassino +2/Rank, Spia +2/Rank, Ladro +1/Rank; si sottrae la Percezione più alta di chi osserva (x3 se è all'erta)"},
    {"id": "horsemanship", "name": "Horsemanship", "nome": "Equitazione", "formula": "(AG modificata + WP)/2 + 8 x Rank", "xp_costs": [0, 125, 250, 375, 500, 625, 750, 875, 1000, 1125, 1250], "start_rank": 0}]}
json.dump(out, open('/home/claude/dq/json/skills.json', 'w'), ensure_ascii=False, indent=2)
print(len(out['skills']), 'abilità')
