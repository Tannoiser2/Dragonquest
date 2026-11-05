"""Regole meccaniche degli incantesimi usabili nell'arena, ricavate dal testo degli effetti (Libro Secondo).
Campi:
  tipo        danno | cura | sonno | svenimento | lentezza | rapidita | intralcio | paura | accecamento |
              arma | protezione | scudo | agonia | prosciuga | vigore | maledizione
  bersaglio   singolo | linea_primo | linea_tutti | area | multipli | se_stesso | tocco | alleato | frontali
  portata     [piedi base, piedi per Rank]  (5 piedi = 1 esagono); "tocco" = adiacente
  danno       [modificatore al D10, divisore del Rank per il +1] (1 = +1 per Rank, 3 = +1 ogni 3 Rank o frazione)
  durata      pulse: [base, per Rank] oppure formula "dado": [secondi, sottrazione dal D10] = secondi x (D10 - n) x Rank
  armatura    true se il danno è fisico (assorbito dall'armatura), altrimenti energia magica (18.4)
"""
import json

S = {}
def s(college, code, **k):
    S[f"{college}:{code}"] = k

# Incantamenti e Ammaliamenti (36)
s(36, "G-3", tipo="sonno", bersaglio="singolo", portata=[15, 15], nota="Bersaglio addormentato; un alleato adiacente lo sveglia con un Pass (dal Rank 10 non si sveglia).")
s(36, "S-2", tipo="danno", bersaglio="linea_primo", portata=[15, 15], danno=[-5, 1])
s(36, "S-5", tipo="intralcio", bersaglio="linea_tutti_fino", portata=[15, 15], quanti="rank", nota="Intralciati: fermi, agiscono un Pulse sì e uno no; due Pass consecutivi per liberarsi.")
s(36, "S-9", tipo="protezione", bersaglio="alleato", portata=[15, 15], penalita_per_rank=2, solo_corazzati=True, durata="combattimento")
s(36, "S-11", tipo="lentezza", bersaglio="multipli", portata=[15, 15], quanti=[1, 2], durata={"dado": [10, 5]})
s(36, "S-12", tipo="rapidita", bersaglio="alleati_multipli", portata=[15, 15], quanti=[1, 3], durata={"dado": [10, 5]})
# Stregonerie della Mente (37)
s(37, "S-1", tipo="svenimento", bersaglio="singolo", portata=[15, 15], durata={"pulse": [2, 2]})
s(37, "S-6", tipo="scudo", bersaglio="se_stesso", base_bonus=5, per_rank=1, durata="combattimento")
s(37, "S-7", tipo="cura", bersaglio="tocco", cura=[2, 1])
# Illusioni (38)
s(38, "G-1", tipo="accecamento", bersaglio="frontali", portata=[15, 15], fatica_extra=2, durata={"pulse": [4, 0]}, nota="Colpisce chi guarda verso l'Adept: -50 alla Strike Chance e metà TMR.")
# Magie dell'Aria (40)
s(40, "S-6", tipo="danno", bersaglio="multipli", portata=[25, 5], quanti=[1, 1], danno=[-3, 1], armatura=True, infezione=10)
s(40, "S-7", tipo="danno", bersaglio="linea_tutti", lunghezza=12, danno=[5, 3], stordisce=True)
s(40, "S-13", tipo="danno", bersaglio="linea_primo", portata=[35, 10], danno=[-1, 1], dimezza_se_resiste=True, infezione=20)
# Magie del Fuoco (42)
s(42, "S-2", tipo="danno", bersaglio="linea_primo", portata=[25, 25], danno=[-5, 1], resistenza_mod=-10)
s(42, "S-3", tipo="danno", bersaglio="area", portata=[20, 20], raggio=2, danno=[-4, 2])
s(42, "S-7", tipo="arma", bersaglio="alleato", portata=[5, 5], sc=[1, 1], danno_arma=3, durata={"dado": [20, 5]})
# Magie della Terra (43)
s(43, "S-1", tipo="danno", bersaglio="singolo", portata=[25, 10], danno=[-5, 1], armatura=True)
s(43, "S-3", tipo="vigore", bersaglio="alleato_non_se", portata=[10, 0], per_rank=1, durata="combattimento")
s(43, "S-4", tipo="protezione", bersaglio="alleato", portata=[10, 0], penalita_per_rank=2, durata="combattimento")
# Magie Celesti (44)
s(44, "S-1", tipo="cura", bersaglio="se_stesso", cura=[1, 2])
s(44, "S-3", tipo="danno", bersaglio="linea_primo", portata=[30, 15], danno=[-4, 1])
s(44, "S-13", tipo="paura", bersaglio="singolo", portata=[15, 15])
# Evocazioni Negromantiche (45)
s(45, "G-6", tipo="agonia", bersaglio="singolo", portata=[15, 15], durata={"pulse": [2, 2]}, sc=-10)
s(45, "S-1", tipo="danno", bersaglio="singolo", portata=[15, 5], danno=[-4, 1], infezione=10)
s(45, "S-4", tipo="paura", bersaglio="singolo", portata=[15, 15])
s(45, "S-9", tipo="arma", bersaglio="alleato", portata=[5, 5], sc=[1, 2], danno_arma=3, durata={"dado": [20, 5]})
# Evocazioni (46)
s(46, "G-14", tipo="prosciuga", bersaglio="tocco", quantita=[1, 3])
# Forgiatura (47)
s(47, "G-2", tipo="arma", bersaglio="alleato", portata=[10, 5], sc=[1, 1], danno_arma=3, durata={"dado": [30, 2]})
s(47, "G-3", tipo="protezione", bersaglio="alleato", portata=[10, 10], penalita_per_rank=2, assorbe=[1, 10], solo_corazzati=True, durata="combattimento")
# Rune (48)
s(48, "G-5", tipo="maledizione", bersaglio="tocco", pc=-5, nota="Ranks 1-5: allucinazioni, Percezione -5.")
s(48, "S-7", tipo="danno", bersaglio="tocco", danno=[-3, 1])

BACKFIRE = [  # 30.1, p. 38
 {"min": 1, "max": 10, "tipo": "fatica", "x": 1, "testo": "L'incantesimo fallisce e perdi altra Fatica pari a quella spesa."},
 {"min": 11, "max": 17, "tipo": "fatica", "x": 2, "testo": "Fallisce e perdi il doppio della Fatica spesa."},
 {"min": 18, "max": 22, "tipo": "fatica", "x": 3, "testo": "Fallisce e perdi il triplo della Fatica spesa."},
 {"min": 23, "max": 24, "tipo": "fatica", "x": 4, "testo": "Fallisce e perdi quattro volte la Fatica spesa."},
 {"min": 25, "max": 25, "tipo": "fatica", "x": 5, "testo": "Fallisce e perdi cinque volte la Fatica spesa."},
 {"min": 26, "max": 35, "tipo": "inverso", "testo": "L'incantesimo si ritorce contro di te."},
 {"min": 36, "max": 45, "tipo": "inverso", "fatica": 1, "testo": "Si ritorce contro di te e perdi altra Fatica pari a quella spesa."},
 {"min": 46, "max": 50, "tipo": "casuale", "testo": "Colpisce una figura a caso entro la portata."},
 {"min": 51, "max": 55, "tipo": "casuale", "doppio": True, "testo": "Colpisce una figura a caso entro la portata, con effetto doppio."},
 {"min": 56, "max": 60, "tipo": "mezzo", "testo": "Ha effetto, ma a metà potenza."},
 {"min": 61, "max": 63, "tipo": "cecita", "testo": "Maledizione: cieco per settimane (-50 a colpire, metà TMR)."},
 {"min": 64, "max": 66, "tipo": "sordita", "testo": "Maledizione: sordo per settimane."},
 {"min": 67, "max": 69, "tipo": "muto", "testo": "Maledizione: muto per settimane, niente incantesimi."},
 {"min": 70, "max": 72, "tipo": "insonnia", "testo": "Maledizione: insonnia, recuperi metà Fatica dormendo."},
 {"min": 73, "max": 75, "tipo": "malattia", "pb": -10, "wp": -3, "testo": "Malattia della pelle: Bellezza -10, Volontà -3."},
 {"min": 76, "max": 80, "tipo": "spasmi", "md": -5, "en_meta": True, "testo": "Spasmi muscolari: Destrezza -5 e Resistenza dimezzata."},
 {"min": 81, "max": 85, "tipo": "emicrania", "wp": -1, "ma": -3, "testo": "Emicranie: Volontà -1, Attitudine magica -3."},
 {"min": 86, "max": 90, "tipo": "artrite", "ft_meta": True, "md": -4, "ag": -3, "testo": "Artrite: Fatica dimezzata, Destrezza -4, Agilità -3."},
 {"min": 91, "max": 95, "tipo": "senilita", "ma": -2, "cast": -10, "testo": "Senilità: Attitudine magica -2, -10 a ogni lancio."},
 {"min": 96, "max": 100, "tipo": "amnesia", "testo": "Amnesia: niente magia e armi senza Rank per giorni."},
]
PAURA = [  # 44.8, p. 57
 {"min": 1, "max": 20, "tipo": "esitazione", "testo": "Esita: -5 a colpire per il resto del Pulse."},
 {"min": 21, "max": 25, "tipo": "furia", "testo": "Furia cieca: carica chi l'ha spaventato; +10 ai colpi suoi e contro di lui."},
 {"min": 26, "max": 76, "tipo": "fuga", "testo": "Fugge il più lontano possibile dalla fonte del terrore."},
 {"min": 77, "max": 90, "tipo": "paralisi", "testo": "Paralizzato come se fosse stordito."},
 {"min": 91, "max": 95, "tipo": "isteria", "testo": "Isterico: resta fermo a urlare finché qualcuno non lo scuote."},
 {"min": 96, "max": 100, "tipo": "catatonia", "testo": "Catatonico, come stordito."},
 {"min": 101, "max": 106, "tipo": "svenimento", "testo": "Sviene per D10+6 minuti."},
 {"min": 107, "max": 110, "tipo": "svenimento", "testo": "Infarto: sviene e non si muove da solo per il resto del giorno."},
 {"min": 111, "max": 999, "tipo": "infarto", "testo": "Infarto: muore entro 12 Pulse senza cure."},
]
json.dump({"_source": "Libro Secondo: effetti degli incantesimi, Backfire Table 30.1, Fright Table 44.8",
           "note_casa": ["Nessun modificatore ambientale dei Collegi nell'arena (luce, acqua, cielo).",
                          "Gli effetti con durata in minuti o ore valgono per tutto il combattimento.",
                          "Paura istantanea (Magie Celesti S-13): la fuga dura D10 Pulse."],
           "incantesimi": S, "backfire_30_1": BACKFIRE, "paura_44_8": PAURA},
          open('/home/claude/dq/json/magia_combattimento.json', 'w'), ensure_ascii=False, indent=1)
print(len(S), "incantesimi da combattimento")
