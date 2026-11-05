class_name CharacterBuilder
extends RefCounted
## Generazione del personaggio, regole 5-8 del Libro Primo.

const PRIMARIE := ["PS", "MD", "AG", "EN", "MA", "WP"]
const NOMI_CARATT := {"PS": "Forza fisica", "MD": "Destrezza manuale", "AG": "Agilità", "EN": "Resistenza", "MA": "Attitudine magica", "WP": "Volontà"}
const RAZZE_TENTABILI := ["Dwarf", "Elf", "Halfling", "Orc"]
const NOMI_RAZZE := {"Human": "Umano", "Dwarf": "Nano", "Elf": "Elfo", "Halfling": "Halfling", "Orc": "Orco", "Giant": "Gigante", "Shape-Changer": "Mutaforma"}

var dadi: Dice
var punti := 0
var massimo := 0
var valori := {"PS": 5, "MD": 5, "AG": 5, "EN": 5, "MA": 5, "WP": 5}
var femmina := false
var mano := "destra"
var razza := "Human"
var tentativi_razza := 3
var razza_decisa := false
var stato_sociale := ""
var moltiplicatore_denaro := 1
var nascita := ""
var xp := 0
var denaro := 0
var registro: Array = []
# Libri Secondo e Terzo
var aspetto := ""
var bellezza := 0
var collegio := 0
var scuola_celeste := ""
var rank_magia: Dictionary = {}     # codice -> Rank (Conoscenza generale sempre presente a Rank 0)
var speciali: Array = []            # codici della Conoscenza speciale imparati
var rank_abilita: Dictionary = {}   # id -> Rank (-1 o assente = non posseduta)
var rank_furtivita := 0
var rank_equitazione := 0


func _init(d: Dice) -> void:
	dadi = d


# ------------------------------------------------------------ 5.1 - 5.2

func tira_punti() -> void:
	var t := dadi.nd10(2)
	var riga := Rules.generazione_punti(t)
	punti = int(riga["points"])
	massimo = int(riga["max"])
	for k in PRIMARIE:
		valori[k] = 5
	registro.append("2D10 = %d: %d punti caratteristica, massimo %d." % [t, punti, massimo])


func punti_assegnati() -> int:
	var s := 0
	for k in PRIMARIE:
		s += int(valori[k])
	return s


func errori_assegnazione() -> Array:
	## Controlla i limiti della regola 5.2. Restituisce un elenco di messaggi (vuoto = valido).
	var err: Array = []
	if punti == 0:
		return ["Tira prima i punti caratteristica."]
	var al_max := 0
	var max_1 := 0
	var max_2 := 0
	for k in PRIMARIE:
		var v := int(valori[k])
		if v < 5:
			err.append("%s sotto il minimo 5." % NOMI_CARATT[k])
		if v > massimo:
			err.append("%s sopra il massimo %d." % [NOMI_CARATT[k], massimo])
		if v == massimo:
			al_max += 1
		elif v == massimo - 1:
			max_1 += 1
		elif v == massimo - 2:
			max_2 += 1
	var lim_max := 1 if massimo > 20 else 2
	var lim_1 := 2
	var lim_2 := 3
	if al_max == 0:
		lim_1 += 1
		lim_2 += 1
	# gli slot max-1 non usati possono diventare slot max-2
	lim_2 += max(0, lim_1 - max_1)
	if al_max > lim_max:
		err.append("Troppe caratteristiche al massimo (%d, limite %d)." % [al_max, lim_max])
	if max_1 > lim_1:
		err.append("Troppe caratteristiche a massimo-1 (%d, limite %d)." % [max_1, lim_1])
	if max_2 > lim_2:
		err.append("Troppe caratteristiche a massimo-2 (%d, limite %d)." % [max_2, lim_2])
	var diff := punti - punti_assegnati()
	if diff > 0:
		err.append("Restano %d punti da assegnare." % diff)
	elif diff < 0:
		err.append("Hai assegnato %d punti di troppo." % -diff)
	return err


func distribuzione_automatica(priorita: Array) -> void:
	## Distribuisce i punti in modo bilanciato secondo un ordine di priorita, rispettando la regola 5.2.
	## Ogni punto va alla caratteristica piu "indietro" rispetto al suo peso.
	const PESI := [1.0, 0.95, 0.85, 0.8, 0.45, 0.1]
	for k in PRIMARIE:
		valori[k] = 5
	var tetti := [massimo, massimo - 1, massimo - 1, massimo - 2, massimo - 2, massimo - 2]
	if massimo <= 20:
		tetti = [massimo, massimo, massimo - 1, massimo - 1, massimo - 2, massimo - 2]
	var resto := punti - 30
	while resto > 0:
		var scelto := -1
		var rapporto_min := INF
		for i in priorita.size():
			var v := int(valori[priorita[i]])
			if v >= int(tetti[i]):
				continue
			var r: float = (v - 5) / float(PESI[i])
			if r < rapporto_min:
				rapporto_min = r
				scelto = i
		if scelto < 0:
			break
		valori[priorita[scelto]] = int(valori[priorita[scelto]]) + 1
		resto -= 1


# ------------------------------------------------------------ 6.1 - 6.3

func tira_mano() -> void:
	var a := dadi.d5()
	var b := dadi.d10()
	if b > a:
		mano = "destra"
	elif a > b:
		mano = "sinistra"
	else:
		mano = "ambidestro"
	registro.append("Mano primaria: D5 = %d, D10 = %d: %s." % [a, b, mano])


func tenta_razza(nome: String) -> bool:
	if razza_decisa or tentativi_razza <= 0:
		return false
	tentativi_razza -= 1
	var chance := int(Rules.razza(nome)["chance"])
	var t := dadi.d100()
	if t <= chance:
		razza = nome
		razza_decisa = true
		registro.append("Tentativo %s: D100 = %d contro %d. Riuscito!" % [NOMI_RAZZE[nome], t, chance])
		return true
	registro.append("Tentativo %s: D100 = %d contro %d. Fallito." % [NOMI_RAZZE[nome], t, chance])
	if tentativi_razza == 0:
		razza = "Human"
		razza_decisa = true
		registro.append("Tre tentativi falliti: il personaggio è umano.")
	return false


func accetta_umano() -> void:
	razza = "Human"
	razza_decisa = true


# ------------------------------------------------------------ 8.1 - 8.5

func tira_retaggio() -> void:
	var c: Dictionary = Rules.personaggi
	var t := dadi.d100()
	var riga := Rules.da_tabella(c["social_status_8_1"]["table"], t)
	stato_sociale = riga["status"]
	moltiplicatore_denaro = int(riga["money_mult"])
	var t2 := dadi.d100()
	var soglie: Array = c["order_of_birth_8_2"]["table"][stato_sociale]
	if t2 <= int(soglie[0]):
		nascita = "Bastard"
	elif t2 <= int(soglie[1]):
		nascita = "Legitimate"
	else:
		nascita = "First Child"
	var eff: Dictionary = c["birth_effects_8_3"][nascita]
	var t3 := dadi.d100()
	var t4 := dadi.d100()
	var tab: Array = c["starting_xp_and_money_8_5"]["table"]
	xp = int(round(float(Rules.da_tabella(tab, t3)["xp"]) * float(eff["xp"])))
	denaro = int(round(float(Rules.da_tabella(tab, t4)["sp"]) * moltiplicatore_denaro * float(eff["money"])))
	registro.append("Retaggio: %s (D100 %d), nascita %s (D100 %d), %d XP, %d monete d'argento." % [stato_sociale, t, nascita, t2, xp, denaro])


func tira_aspetto() -> void:
	var t := dadi.d100()
	aspetto = String(Rules.da_tabella(Rules.personaggi["aspects_7_1"]["table"], t)["aspect"])
	var b1 := 3
	for i in 4:
		b1 += dadi.d5()
	bellezza = b1
	registro.append("Aspetto: %s (D100 %d). Bellezza fisica 4D5+3 = %d." % [aspetto, t, bellezza])


# ------------------------------------------------------------ magia (34, 91.4)

func voci_generali() -> Array:
	var out: Array = []
	for v in Rules.collegio(collegio).get("entries", []):
		if v["type"] in ["talento", "incantesimo_generale", "rituale_generale"]:
			out.append(v)
	return out


func voci_speciali() -> Array:
	var out: Array = []
	for v in Rules.collegio(collegio).get("entries", []):
		if v["type"] == "incantesimo_speciale":
			out.append(v)
	return out


func conoscenze_basse() -> int:
	## Incantesimi e rituali a Rank 5 o meno: non possono superare l'Attitudine magica [34.6].
	if collegio == 0:
		return 0
	var n := 2 if collegio != 39 else 0     # i due controincantesimi del proprio Collegio
	for v in voci_generali():
		if v["type"] != "talento" and int(rank_magia.get(v["code"], 0)) <= 5:
			n += 1
	for codice in speciali:
		if int(rank_magia.get(codice, 0)) <= 5:
			n += 1
	return n


func costo_xp_magia() -> int:
	var tot := 0
	var ma_fin := valore_finale("MA")
	for codice in rank_magia:
		var v := Rules.voce_magica(collegio, codice)
		var em = v.get("experience_multiple", null)
		if em == null:
			continue
		var generale: bool = v.get("type", "") in ["talento", "incantesimo_generale", "rituale_generale"]
		for r in range(1, int(rank_magia[codice]) + 1):
			tot += Rules.costo_rank_magia(int(em), r, generale, ma_fin)
	return int(ceil(tot * moltiplicatore_xp()))


func costo_denaro_magia() -> int:
	## 91.4: imparare un incantesimo speciale costa 200 x numero d'ordine monete d'argento.
	var tot := 0
	for codice in speciali:
		tot += 200 * int(Rules.voce_magica(collegio, codice).get("n", 1))
	return tot


func errori_magia() -> Array:
	var err: Array = []
	if collegio == 0:
		return err
	var req := Rules.ma_richiesta(collegio)
	if valore_finale("MA") < req:
		err.append("Il Collegio richiede Attitudine magica %d (hai %d)." % [req, valore_finale("MA")])
	if conoscenze_basse() > valore_finale("MA"):
		err.append("Troppi incantesimi e rituali di Rank 5 o meno (%d, limite %d)." % [conoscenze_basse(), valore_finale("MA")])
	if collegio == 44 and scuola_celeste == "":
		err.append("Scegli la scuola delle Magie Celesti.")
	return err


# ------------------------------------------------------------ abilità (52-66, 87)

func costo_abilita(id: String, rank: int) -> int:
	## XP totali per portare un'abilità da zero a 'rank' (tabella p. 146, moltiplicatore di razza e casi speciali).
	if rank < 0:
		return 0
	var scheda := Rules.abilita_scheda(id)
	var costi: Array = scheda.get("xp_costs", [])
	var tot := 0.0
	for r in range(0, rank + 1):
		if r >= costi.size():
			return -1
		var c := float(costi[r])
		if id == "mechanician":
			if valore_finale("MD") < 15:
				c *= 1.1
			elif valore_finale("MD") > 22:
				c *= 0.9
		if (id == "thief" and r <= int(rank_abilita.get("spy", -1))) or (id == "spy" and r <= int(rank_abilita.get("thief", -1))):
			c *= 0.5
		tot += c
	return int(ceil(tot * moltiplicatore_xp()))


func costo_xp_abilita() -> int:
	var tot := 0
	var sconto_max := 0
	for id in rank_abilita:
		var r := int(rank_abilita[id])
		if r < 0:
			continue
		tot += costo_abilita(id, r)
		# 8.6: un'abilità a Rank 0 costa solo 100 XP prima della prima avventura
		var r0 := int(ceil(float(Rules.abilita_scheda(id)["xp_costs"][0]) * moltiplicatore_xp()))
		sconto_max = maxi(sconto_max, r0 - 100)
	tot -= sconto_max
	tot += costo_abilita("stealth", rank_furtivita) if rank_furtivita > 0 else 0
	tot += costo_abilita("horsemanship", rank_equitazione) if rank_equitazione > 0 else 0
	return tot


func errori_abilita() -> Array:
	var err: Array = []
	if int(rank_abilita.get("beast_master", -1)) >= 0 and valore_finale("WP") < 15:
		err.append("Domatore: serve Volontà 15.")
	return err


# ------------------------------------------------------------ costruzione della figura

func valore_finale(k: String) -> int:
	var v := int(valori.get(k, 0))
	var mods: Dictionary = Rules.razza(razza).get("mods", {})
	v += int(mods.get(k, 0))
	if femmina:
		v += int(Rules.personaggi["female_6_1"].get(k, 0))
	return max(1, v)


func crea_figura(nome: String, lato: int) -> Fighter:
	var f := Fighter.new()
	f.nome = nome
	f.lato = lato
	f.razza = razza
	f.femmina = femmina
	f.mano = mano
	f.ps = valore_finale("PS")
	f.md = valore_finale("MD")
	f.ag = valore_finale("AG")
	f.en = valore_finale("EN")
	f.ma = valore_finale("MA")
	f.wp = valore_finale("WP")
	var mods: Dictionary = Rules.razza(razza).get("mods", {})
	f.ft = Rules.fatigue_da_endurance(f.en) + int(mods.get("FT", 0))
	if femmina:
		f.ft += int(Rules.personaggi["female_6_1"].get("FT", 0))
	f.pc = int(Rules.personaggi["perception_start_5_4"]) + int(mods.get("PC", 0))
	f.aspetto = aspetto
	f.bellezza = bellezza
	f.collegio = collegio
	f.scuola_celeste = scuola_celeste
	f.incantesimi.clear()
	if collegio > 0:
		for v in voci_generali():
			f.incantesimi.append({"code": v["code"], "rank": int(rank_magia.get(v["code"], 0))})
		for codice in speciali:
			f.incantesimi.append({"code": codice, "rank": int(rank_magia.get(codice, 0))})
	f.abilita.clear()
	for id in rank_abilita:
		if int(rank_abilita[id]) >= 0:
			f.abilita[id] = int(rank_abilita[id])
	f.rank_furtivita = rank_furtivita
	f.rank_equitazione = rank_equitazione
	f.prepara_combattimento()
	return f


func moltiplicatore_xp() -> float:
	return float(Rules.razza(razza)["xp_multiplier"])


func costo_fino_a(id_arma: String, rank: int) -> int:
	## XP totali per portare un'arma da senza Rank a 'rank' (x moltiplicatore razziale). -1 = impossibile.
	var tot := 0
	for r in range(0, rank + 1):
		var c := Rules.costo_rank(id_arma, r)
		if c < 0:
			return -1
		tot += c
	return int(ceil(tot * moltiplicatore_xp()))


func costo_scudo_fino_a(rank: int) -> int:
	var tot := 0
	for r in range(0, rank + 1):
		var c := Rules.costo_rank_scudo(r)
		if c < 0:
			return -1
		tot += c
	return int(ceil(tot * moltiplicatore_xp()))


# ------------------------------------------------------------ PNG pronti

static func adept(d: Dice, nome: String, lato: int, razza_png: String, collegio_png: int, ranks: Dictionary, arma: String, rank_a: int, armatura: String, scuola: String = "") -> Fighter:
	## PNG Adept: Conoscenza generale del Collegio a Rank 0 più gli incantesimi indicati in 'ranks'.
	var b := CharacterBuilder.new(d)
	b.tira_punti()
	b.razza = razza_png
	b.razza_decisa = true
	b.distribuzione_automatica(["MA", "WP", "EN", "AG", "MD", "PS"])
	b.collegio = collegio_png
	b.scuola_celeste = scuola
	for codice in ranks:
		b.rank_magia[codice] = int(ranks[codice])
		if String(codice).begins_with("S"):
			b.speciali.append(codice)
	var f := b.crea_figura(nome, lato)
	f.arma_mischia = arma
	f.rank_mischia = rank_a
	f.armatura = armatura
	f.prepara_combattimento()
	return f


static func png(d: Dice, nome: String, lato: int, razza_png: String, priorita: Array, mischia: String, rank_m: int, armatura: String, scudo: String = "", rank_s: int = -1, distanza: String = "", rank_d: int = -1) -> Fighter:
	var b := CharacterBuilder.new(d)
	b.tira_punti()
	b.razza = razza_png
	b.razza_decisa = true
	b.distribuzione_automatica(priorita)
	var f := b.crea_figura(nome, lato)
	f.arma_mischia = mischia
	f.rank_mischia = rank_m
	f.armatura = armatura
	f.scudo = scudo
	f.rank_scudo = rank_s
	f.arma_distanza = distanza
	f.rank_distanza = rank_d
	f.prepara_combattimento()
	return f
