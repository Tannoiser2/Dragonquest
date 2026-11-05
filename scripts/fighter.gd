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

# --- magia e abilità (Libri Secondo e Terzo)
var collegio := 0             # numero del Collegio (36-48), 0 = nessuno
var scuola_celeste := ""      # Star Mage, Dark Mage, Shadow Weaver (solo Magie Celesti)
var incantesimi: Array = []   # [{"code": "S-2", "rank": 3}]
var abilita: Dictionary = {}  # id abilità -> Rank
var rank_furtivita := 0
var rank_equitazione := 0
var aspetto := ""
var bellezza := 0

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
var azioni := 0               # azioni rimaste nel Pulse (2 se accelerato)
var ferite: Array = []        # testi delle ferite gravi (per la scheda)
var infezione := 0            # probabilita di infezione accumulata [24]
var emorragia_rank_guaritore := 0
# magia in combattimento
var preparato := ""           # codice dell'incantesimo preparato
var effetti: Array = []       # effetti magici attivi: {"tipo", "fine", ...}
var addormentato := false     # sonno o svenimento magico
var sveglia_impossibile := false
var isterico := false
var intralciato := 0          # Pass ancora necessari per liberarsi
var in_fuga := 0              # Pulse di fuga rimasti
var fuga_da: Fighter = null
var furia_contro: Fighter = null
var muto := false
var amnesia := false
var mod_ma := 0
var mod_wp := 0
var mod_cast := 0
var salta_pulse := false      # lentezza: agisce un Pulse sì e uno no


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
	if not effetto("rapidita").is_empty():
		t *= 2
	if not effetto("lentezza").is_empty() or not effetto("accecamento").is_empty():
		t = int(t / 2)
	return max(1, t)


func protezione() -> int:
	var p := int(dati_armatura().get("protection", 0)) - protezione_persa
	p += int(effetto("protezione").get("assorbe", 0))
	return max(0, p)


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
	var bonus := 0
	var e_arma := effetto("arma")
	if not e_arma.is_empty() and (quale == "mischia" or (quale == "" and preparata == "mischia")):
		bonus += int(e_arma.get("sc", 0))
	if not effetto("accecamento").is_empty():
		bonus -= 50
	var e_ag := effetto("agonia")
	if not e_ag.is_empty():
		bonus += int(e_ag.get("sc", -10))
	if r < 0 or amnesia:
		return base + bonus
	return base + mdm + 4 * r + bonus


func valore_iniziativa() -> int:
	## Initiative Value [12.3].
	var v := ag_modificata() + pc_attuale()
	if not arma_caduta:
		v += max(0, rank_arma())
	if not effetto("rapidita").is_empty():
		v += 10
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
	var e_arma := effetto("arma")
	if not e_arma.is_empty() and quale != "distanza":
		v += int(e_arma.get("danno", 0))
	return v


func puo_agire() -> bool:
	return not (morto or svenuto or addormentato)


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
	if addormentato:
		s.append("addormentato")
	if isterico:
		s.append("isterico")
	if in_fuga > 0:
		s.append("in fuga")
	if intralciato > 0:
		s.append("intralciato")
	if preparato != "":
		s.append("incantesimo pronto")
	for e in effetti:
		s.append(String(e.get("nome", e["tipo"])))
	if postura == "schiva":
		s.append("schiva")
	elif postura == "resiste":
		s.append("resiste alla magia")
	elif postura == "ritirata":
		s.append("in ritirata")
	return ", ".join(s) if s.size() > 0 else "pronto"


# ------------------------------------------------------------ magia

const ARMATURE_METALLICHE := ["Scale", "Chainmail", "Partial Plate", "Full Plate", "Improved Plate"]
const ARMI_SENZA_FERRO := ["quarterstaff", "crude_club", "war_club", "giant_club", "torch", "sap", "sling", "short_bow",
	"long_bow", "composite_bow", "giant_bow", "blowgun", "boomerang", "net", "bola", "whip", "cestus", "rock", "garotte"]


func ramo() -> String:
	if collegio == 0:
		return ""
	return String(Rules.collegio(collegio).get("branch", ""))


func ma_attuale() -> int:
	return max(1, ma + mod_ma)


func wp_attuale() -> int:
	return max(1, wp + mod_wp)


func ferro_freddo() -> bool:
	## 29.1: niente magia a contatto con ferro freddo (armatura metallica o arma di ferro impugnata).
	if ARMATURE_METALLICHE.has(armatura):
		return true
	var id := arma_distanza if preparata == "distanza" else arma_mischia
	if id != "" and not arma_caduta and not ARMI_SENZA_FERRO.has(id):
		return true
	if scudo == "Tower Shield" or scudo == "Main-Gauche":
		return true
	return false


func rank_incantesimo(codice: String) -> int:
	for i in incantesimi:
		if i["code"] == codice:
			return int(i["rank"])
	return -1


func conosce(codice: String) -> bool:
	return rank_incantesimo(codice) >= 0


func costo_fatica(codice: String) -> int:
	var c := 1 if codice.begins_with("G") else 2
	c += int(Rules.spec_combattimento(collegio, codice).get("fatica_extra", 0))
	return c


func cast_chance(codice: String, bersaglio: Fighter = null) -> int:
	## Cast Chance [27.7]: Base + (MA - 15) + 3 x Rank, più i modificatori del Collegio.
	var v := Rules.voce_magica(collegio, codice)
	var base = v.get("base_chance", 0)
	var cc := int(base) if base != null else 0
	cc += ma_attuale() - 15 + 3 * max(0, rank_incantesimo(codice)) + mod_cast
	if collegio == 37 and bersaglio != null:
		var diff := wp_attuale() - bersaglio.wp_attuale()
		cc += diff if diff > 0 else 2 * diff
	if collegio == 38:
		cc += 2 * (wp_attuale() - 15)
	return cc


func incantesimi_da_combattimento() -> Array:
	var out: Array = []
	for i in incantesimi:
		if not Rules.spec_combattimento(collegio, i["code"]).is_empty():
			out.append(i["code"])
	return out


func magic_resistance(lanciatore: Fighter) -> int:
	## Resistenza: Volontà + modificatori di ramo [31.4, 34.1].
	var r := wp_attuale()
	if collegio == 0:
		r += 20
	else:
		r += Rules.relazione_rami(ramo(), lanciatore.ramo())
	return r


func effetto(tipo: String) -> Dictionary:
	for e in effetti:
		if e["tipo"] == tipo:
			return e
	return {}


func rank_abilita(id: String) -> int:
	return int(abilita.get(id, -1))
