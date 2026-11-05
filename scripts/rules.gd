extends Node
## Autoload "Rules": carica le tabelle del Libro Primo (cartella data/) e offre le ricerche.

var personaggi: Dictionary = {}
var armi: Dictionary = {}          # id -> scheda arma
var armi_ordine: Array = []        # id nell'ordine del manuale
var armature: Dictionary = {}      # nome -> scheda
var scudi: Dictionary = {}         # nome -> scheda
var combattimento: Dictionary = {}
var ingombro: Dictionary = {}
var costi_xp: Dictionary = {}      # nome arma -> Array costi Rank 0-10
var magia: Dictionary = {}         # magic.json completo
var collegi: Dictionary = {}       # numero collegio -> scheda
var magia_combat: Dictionary = {}  # magia_combattimento.json
var abilita: Dictionary = {}       # skills.json


func _ready() -> void:
	carica()


func carica() -> void:
	personaggi = _leggi("res://data/characters.json")
	var doc_armi := _leggi("res://data/weapons.json")
	armi.clear()
	armi_ordine.clear()
	for a in doc_armi.get("weapons", []):
		armi[a["id"]] = a
		armi_ordine.append(a["id"])
	var doc_prot := _leggi("res://data/armor_shields.json")
	for a in doc_prot.get("armor", []):
		armature[a["name"]] = a
	for s in doc_prot.get("shields", []):
		scudi[s["name"]] = s
	combattimento = _leggi("res://data/combat_tables.json")
	ingombro = _leggi("res://data/encumbrance.json")
	costi_xp = _leggi("res://data/xp_weapon_ranks.json").get("weapons", {})
	magia = _leggi("res://data/magic.json")
	collegi.clear()
	for c in magia.get("colleges", []):
		collegi[int(c["num"])] = c
	magia_combat = _leggi("res://data/magia_combattimento.json")
	abilita = _leggi("res://data/skills.json")


func _leggi(percorso: String) -> Dictionary:
	var f := FileAccess.open(percorso, FileAccess.READ)
	if f == null:
		push_error("Impossibile aprire " + percorso)
		return {}
	var dati = JSON.parse_string(f.get_as_text())
	if typeof(dati) != TYPE_DICTIONARY:
		push_error("JSON non valido: " + percorso)
		return {}
	return dati


# ------------------------------------------------------------ caratteristiche

func generazione_punti(tiro_2d10: int) -> Dictionary:
	return personaggi["point_generation_5_1"]["table"][str(tiro_2d10)]


func fatigue_da_endurance(en: int) -> int:
	for r in personaggi["fatigue_from_endurance_5_3"]:
		if en >= r["en_min"] and en <= r["en_max"]:
			return int(r["ft"])
	return 16 if en < 3 else 24


func tmr_da_agilita(ag: int) -> int:
	if ag < 3:
		return 1
	for r in personaggi["tmr_from_modified_agility_5_6"]:
		if ag >= r["ag_min"] and ag <= r["ag_max"]:
			return int(r["tmr"])
	return 8


func razza(nome: String) -> Dictionary:
	return personaggi["races_6_3"].get(nome, personaggi["races_6_3"]["Human"])


func da_tabella(tabella: Array, tiro: int) -> Dictionary:
	for r in tabella:
		if tiro >= int(r["min"]) and tiro <= int(r["max"]):
			return r
	return tabella[tabella.size() - 1]


# ------------------------------------------------------------ armi e protezioni

func arma(id: String) -> Dictionary:
	return armi.get(id, {})


func costo_rank(id_arma: String, rank: int) -> int:
	## Costo XP per passare a quel Rank (null nel manuale = -1, non ottenibile).
	var a := arma(id_arma)
	var nome: String = a.get("name", id_arma)
	var riga = costi_xp.get(nome, null)
	if riga == null or rank < 0 or rank >= riga.size() or riga[rank] == null:
		return -1
	return int(riga[rank])


func costo_rank_scudo(rank: int) -> int:
	var riga = costi_xp.get("Shield", null)
	if riga == null or rank < 0 or rank >= riga.size() or riga[rank] == null:
		return -1
	return int(riga[rank])


func perdita_ingombro(ps: int, carico: float) -> int:
	var tab: Dictionary = ingombro
	var perdite: Array = tab["agility_loss"]
	for r in tab["rows"]:
		if ps >= int(r["ps_min"]) and ps <= int(r["ps_max"]):
			var colonne: Array = (r["loads"] as Array).duplicate()
			colonne.append(r["max"])
			# carico arrotondato all'entrata più vicina; a meta strada si prende la maggiore
			var migliore := 0
			var distanza := INF
			for i in colonne.size():
				var d: float = abs(carico - float(colonne[i]))
				if d < distanza or (d == distanza and i > migliore):
					distanza = d
					migliore = i
			return int(perdite[migliore])
	return 0


# ------------------------------------------------------------ tabelle di combattimento

func danno_speciale(sc_mod: int) -> Dictionary:
	## Riga della Special Damage Chart per una Modified Strike Chance.
	for r in combattimento["special_damage_18_2"]["table"]:
		if sc_mod >= int(r["sc_min"]) and sc_mod <= int(r["sc_max"]):
			return r
	return {"sc_min": 0, "sc_max": 0, "grievous_max": null, "endurance_max": 0}


func ferita_grave(tiro: int) -> Dictionary:
	for r in combattimento["grievous_injury_18_3"]["table"]:
		if tiro >= int(r["min"]) and tiro <= int(r["max"]):
			return r
	return {}


func intervallo_classe(classe: String) -> Array:
	return combattimento["grievous_injury_18_3"]["class_ranges"].get(classe, [])


# ------------------------------------------------------------ magia

const NOMI_RAMI := {"Thaumaturgies": "Taumaturgie", "Elementals": "Elementali", "Entities": "Entità"}


func collegio(num: int) -> Dictionary:
	return collegi.get(num, {})


func voce_magica(num: int, codice: String) -> Dictionary:
	for v in collegio(num).get("entries", []):
		if v["code"] == codice:
			return v
	return {}


func spec_combattimento(num: int, codice: String) -> Dictionary:
	return magia_combat.get("incantesimi", {}).get("%d:%s" % [num, codice], {})


func ma_richiesta(num: int) -> int:
	## 34.7: l'Attitudine magica deve bastare per la Conoscenza generale (incantesimi e rituali generali
	## più i due controincantesimi). I Nomi (39) sono esenti.
	if num == 39:
		return 0
	return int(collegio(num).get("general_knowledge_count", 0)) + 2


func relazione_rami(ramo_a: String, ramo_b: String) -> int:
	## Modificatore alla Magic Resistance [34.1]: stesso ramo +20, opposti -20, neutri 0.
	if ramo_a == "" or ramo_b == "":
		return 0
	if ramo_a == ramo_b:
		return 20
	if (ramo_a == "Thaumaturgies" and ramo_b == "Entities") or (ramo_a == "Entities" and ramo_b == "Thaumaturgies"):
		return -20
	return 0


func costo_rank_magia(em: int, rank: int, generale: bool, ma: int) -> int:
	## 91.4: Experience Multiple x Rank da raggiungere; per la Conoscenza generale -5% per punto di MA oltre 15.
	if em <= 0 or rank <= 0:
		return 0
	var c := float(em * rank)
	if generale and ma > 15:
		c *= max(0.0, 1.0 - 0.05 * (ma - 15))
	return int(ceil(c))


func abilita_scheda(id: String) -> Dictionary:
	for a in abilita.get("skills", []):
		if a["id"] == id:
			return a
	for a in abilita.get("adventure_abilities_87", []):
		if a["id"] == id:
			return a
	return {}
