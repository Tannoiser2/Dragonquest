class_name Fighter
extends RefCounted
## Una figura sull'arena: caratteristiche, equipaggiamento, stato e valori derivati [17.1, 17.5, 12.3, 5.6].

# --- identita
var nome := "Senza nome"
var lato := 0                 # 0 = giocatore, 1 = nemici
var razza := "Human"
var femmina := false
var mano := "destra"

# --- caratteristiche (valori finali dopo razza e sesso)
var ps := 10
var md := 10
var ag := 10
var en := 10
var ma := 10
var wp := 10
var ft := 18
var pc := 8

# --- equipaggiamento
var arma_mischia := "broadsword"
var rank_mischia := -1        # -1 = senza Rank
var arma_distanza := ""       # "" = nessuna
var rank_distanza := -1
var scudo := ""               # nome nella Shield Chart, "" = nessuno
var rank_scudo := -1
var armatura := "Leather"

# --- stato in combattimento
var hex := Vector2i.ZERO
var facing := 0
var fatica := 18              # Fatigue Points attuali
var resistenza := 10          # Endurance attuale
var preparata := "mischia"    # "mischia" o "distanza"
var carica_pronta := false    # arma da tiro caricata
var passi_carica := 0         # Pass gia fatti per caricare
var stordito := false
var prono := false
var non_si_rialza := false
var svenuto := false
var morto := false
var postura := ""             # "", "schiva", "ritirata", "movimento"
var arma_caduta := false
var arma_rotta := false
var braccio_primario_inutile := false
var conficcate := 0           # armi di Classe A conficcate (-3 AG ciascuna) [20.4]
var emorragia_ft := 0         # punti per Pulse da Fatigue (poi Endurance)
var emorragia_en := 0         # punti per Pulse da Endurance
var emorragia_fino_svenimento := false
var pass_obbligato := 0
var mod_ag := 0               # penalita temporanee da ferite gravi
var mod_md := 0
var mod_tmr := 0
var mod_pc := 0
var protezione_persa := 0
var ha_agito := false
var ferite: Array = []        # testi delle ferite gravi (per la scheda)
var infezione := 0            # probabilita di infezione accumulata [24]


func prepara_combattimento() -> void:
	fatica = ft
	resistenza = en
	carica_pronta = false
	preparata = "mischia"


# ------------------------------------------------------------ dati equipaggiamento

func dati_arma(quale: String = "") -> Dictionary:
	if quale == "":
		quale = preparata
	if quale == "distanza":
		return Rules.arma(arma_distanza)
	return Rules.arma(arma_mischia)


func rank_arma(quale: String = "") -> int:
	if quale == "":
		quale = preparata
	return rank_distanza if quale == "distanza" else rank_mischia


func dati_scudo() -> Dictionary:
	return Rules.scudi.get(scudo, {})


func dati_armatura() -> Dictionary:
	return Rules.armature.get(armatura, Rules.armature.get("Cloth / Heavy Furs", {}))


func scudo_utilizzabile() -> bool:
	## Lo scudo conta solo con un'arma a una mano preparata [20].
	if scudo == "" or preparata != "mischia":
		return false
	var a := dati_arma("mischia")
	return a.get("hands", "1") != "2"


func numero_taglia() -> float:
	var n: float = float(Rules.razza(razza).get("size_number", 6))
	return n - 0.5 if femmina else n


func peso_trasportato() -> float:
	var p := 0.0
	p += float(dati_armatura().get("weight_mult", 1)) * numero_taglia()
	for id in [arma_mischia, arma_distanza]:
		if id != "":
			var w = Rules.arma(id).get("weight_lb", 0)
			if typeof(w) == TYPE_FLOAT or typeof(w) == TYPE_INT:
				p += float(w)
	if scudo != "":
		p += float(dati_scudo().get("weight_lb", 0))
	return p


# ------------------------------------------------------------ valori derivati

func ag_modificata() -> int:
	var v := ag + int(dati_armatura().get("ag_loss", 0)) - Rules.perdita_ingombro(ps, peso_trasportato())
	v += mod_ag - 3 * conficcate
	return max(1, v)


func md_modificata() -> int:
	var v := md + mod_md
	if scudo_utilizzabile():
		v += int(dati_scudo().get("md_loss", 0))
	return max(1, v)


func pc_attuale() -> int:
	return max(1, pc + mod_pc)


func tmr() -> int:
	var t := Rules.tmr_da_agilita(ag_modificata())
	t += int(Rules.razza(razza)["mods"].get("TMR", 0)) + mod_tmr
	return max(1, t)


func protezione() -> int:
	return max(0, int(dati_armatura().get("protection", 0)) - protezione_persa)


func difesa(da_dietro: bool, tipo: String) -> int:
	## Defense Rating [17.5]: AG modificata + scudo (non da dietro, non in Close, Main-Gauche non contro il tiro).
	if stordito or svenuto or morto:
		return 0
	var d := ag_modificata()
	if scudo_utilizzabile() and not da_dietro and tipo != "close" and rank_scudo >= 0:
		var s := dati_scudo()
		if not (tipo == "ranged" and s.get("no_def_vs_fire", false)):
			d += rank_scudo * int(s.get("def_per_rank", 0))
	if postura == "ritirata" and scudo_utilizzabile():
		d += 20
	return d


func strike_chance(quale: String = "") -> int:
	## Strike Chance [17.1]: Base + MD modificata + 4 x Rank (senza Rank: solo Base).
	var a := dati_arma(quale)
	var base := int(a.get("base_chance", 0))
	var md_min := int(a.get("min_md", 0))
	var mdm := md_modificata()
	if mdm < md_min:
		base -= 5 * (md_min - mdm)
	var r := rank_arma(quale)
	if r < 0:
		return base
	return base + mdm + 4 * r


func valore_iniziativa() -> int:
	## Initiative Value [12.3].
	var v := ag_modificata() + pc_attuale()
	if not arma_caduta:
		v += max(0, rank_arma())
	return v


func modificatore_danno(quale: String = "") -> int:
	var a := dati_arma(quale)
	var m = a.get("damage_mod", 0)
	var v := 0
	if typeof(m) == TYPE_INT or typeof(m) == TYPE_FLOAT:
		v = int(m)
	var ps_min := int(a.get("min_ps", 0))
	if ps < ps_min:
		v -= ps_min - ps
	if a.get("hands", "1") == "1-2" and scudo == "":
		v += 1
	return v


func puo_agire() -> bool:
	return not (morto or svenuto)


func in_piedi_e_attivo() -> bool:
	return puo_agire() and not stordito


func ha_arma_distanza() -> bool:
	return arma_distanza != ""


func descrizione_stato() -> String:
	var s: Array = []
	if morto:
		return "morto"
	if svenuto:
		s.append("svenuto")
	if stordito:
		s.append("stordito")
	if prono:
		s.append("a terra")
	if arma_caduta:
		s.append("disarmato")
	if emorragia_ft > 0 or emorragia_en > 0:
		s.append("sanguina")
	if postura == "schiva":
		s.append("schiva")
	elif postura == "ritirata":
		s.append("in ritirata")
	return ", ".join(s) if s.size() > 0 else "pronto"
