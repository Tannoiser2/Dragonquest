extends Control
## Schermate del prototipo: creazione del personaggio e arena tattica.

const COL_SFONDO := Color(0.11, 0.09, 0.08)
const COL_PANNELLO := Color(0.18, 0.15, 0.12)
const COL_ORO := Color(0.85, 0.70, 0.35)
const COL_TESTO := Color(0.92, 0.88, 0.80)

var dadi := Dice.new()
var builder: CharacterBuilder
var font_titolo: Font
var font_grassetto: Font

# --- creazione
var radice_creazione: Control
var spin_caratt: Dictionary = {}
var lbl_punti: Label
var lbl_errori: Label
var lbl_finali: Label
var opt_sesso: OptionButton
var lbl_mano: Label
var opt_razza: OptionButton
var btn_tenta: Button
var lbl_razza: Label
var lbl_retaggio: Label
var edit_nome: LineEdit
var opt_mischia: OptionButton
var spin_rank_m: SpinBox
var opt_distanza: OptionButton
var spin_rank_d: SpinBox
var opt_armatura: OptionButton
var opt_scudo: OptionButton
var spin_rank_s: SpinBox
var lbl_spesa: Label
var btn_armi: Button
var log_creazione: RichTextLabel
var id_mischia: Array = []
var id_distanza: Array = [""]
var nomi_armature: Array = []
var nomi_scudi: Array = [""]
var retaggio_tirato := false
var mano_tirata := false

# --- arena
var radice_arena: Control
var combat: Combat
var vista: ArenaView
var lbl_scheda: RichTextLabel
var box_azioni: VBoxContainer
var log_arena: RichTextLabel
var lbl_sotto: Label
var timer_ia: Timer
var azione_corrente := ""
var bersagli_correnti: Array = []
var eroe: Fighter


func _ready() -> void:
	font_titolo = load("res://assets/font/Cinzel-Bold.ttf")
	font_grassetto = load("res://assets/font/Alegreya-Bold.ttf")
	var tema := Theme.new()
	tema.default_font = load("res://assets/font/Alegreya-Regular.ttf")
	tema.default_font_size = 17
	tema.set_color("font_color", "Label", COL_TESTO)
	tema.set_color("default_color", "RichTextLabel", COL_TESTO)
	tema.set_font("bold_font", "RichTextLabel", font_grassetto)
	theme = tema
	var sfondo := ColorRect.new()
	sfondo.color = COL_SFONDO
	sfondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sfondo)
	timer_ia = Timer.new()
	timer_ia.one_shot = true
	timer_ia.wait_time = 0.55
	timer_ia.timeout.connect(_passo_ia)
	add_child(timer_ia)
	mostra_creazione()


# ============================================================ utilità UI

func titolo(testo: String, dim: int = 22) -> Label:
	var l := Label.new()
	l.text = testo
	l.add_theme_font_override("font", font_titolo)
	l.add_theme_font_size_override("font_size", dim)
	l.add_theme_color_override("font_color", COL_ORO)
	return l


func etichetta(testo: String = "") -> Label:
	var l := Label.new()
	l.text = testo
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func bottone(testo: String, azione: Callable) -> Button:
	var b := Button.new()
	b.text = testo
	b.pressed.connect(azione)
	return b


func pannello(contenuto: Control) -> PanelContainer:
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = COL_PANNELLO
	st.border_color = Color(0.45, 0.36, 0.22)
	st.set_border_width_all(1)
	st.set_corner_radius_all(6)
	st.set_content_margin_all(14)
	p.add_theme_stylebox_override("panel", st)
	p.add_child(contenuto)
	return p


func riga(etich: String, ctrl: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	var l := etichetta(etich)
	l.custom_minimum_size.x = 170
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(l)
	ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if ctrl is OptionButton:
		(ctrl as OptionButton).clip_text = true
		ctrl.custom_minimum_size.x = 120
	h.add_child(ctrl)
	return h


func spin(minimo: int, massimo: int, valore: int) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = minimo
	s.max_value = massimo
	s.value = valore
	s.rounded = true
	return s


# ============================================================ creazione del personaggio

func mostra_creazione() -> void:
	if radice_arena:
		radice_arena.queue_free()
		radice_arena = null
	builder = CharacterBuilder.new(dadi)
	retaggio_tirato = false
	mano_tirata = false
	radice_creazione = MarginContainer.new()
	radice_creazione.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lato in ["left", "right", "top", "bottom"]:
		radice_creazione.add_theme_constant_override("margin_" + lato, 24)
	add_child(radice_creazione)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	radice_creazione.add_child(v)
	v.add_child(titolo("DragonQuest - Crea il tuo avventuriero", 30))
	v.add_child(etichetta("Regole del Libro Primo (DragonQuest 3a edizione). Segui i passi da sinistra a destra; ogni tiro compare nel registro."))
	var colonne := HBoxContainer.new()
	colonne.add_theme_constant_override("separation", 14)
	colonne.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(colonne)
	colonne.add_child(_colonna_caratteristiche())
	colonne.add_child(_colonna_origini())
	colonne.add_child(_colonna_equipaggiamento())
	var col_log := VBoxContainer.new()
	col_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_log.custom_minimum_size.x = 260
	col_log.add_child(titolo("Registro dei tiri", 18))
	log_creazione = RichTextLabel.new()
	log_creazione.bbcode_enabled = true
	log_creazione.scroll_following = true
	log_creazione.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col_log.add_child(log_creazione)
	var p := pannello(col_log)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	colonne.add_child(p)
	var fondo := HBoxContainer.new()
	fondo.add_theme_constant_override("separation", 12)
	fondo.add_child(bottone("Personaggio casuale", _personaggio_casuale))
	btn_armi = bottone("Alle armi!", _alle_armi)
	btn_armi.add_theme_font_override("font", font_titolo)
	fondo.add_child(btn_armi)
	v.add_child(fondo)
	aggiorna_creazione()


func _colonna_caratteristiche() -> Control:
	var v := VBoxContainer.new()
	v.custom_minimum_size.x = 330
	v.add_child(titolo("1. Caratteristiche", 18))
	v.add_child(bottone("Tira i punti (2D10)", _tira_punti))
	lbl_punti = etichetta("Punti non ancora tirati.")
	v.add_child(lbl_punti)
	for k in CharacterBuilder.PRIMARIE:
		var s := spin(5, 25, 5)
		s.value_changed.connect(func(val): _cambia_caratt(k, val))
		spin_caratt[k] = s
		v.add_child(riga(CharacterBuilder.NOMI_CARATT[k] + " (" + k + ")", s))
	v.add_child(bottone("Distribuisci da guerriero", func(): _distribuisci(["PS", "MD", "EN", "AG", "WP", "MA"])))
	v.add_child(bottone("Distribuisci da schermidore", func(): _distribuisci(["MD", "AG", "EN", "PS", "WP", "MA"])))
	lbl_errori = etichetta()
	lbl_errori.add_theme_color_override("font_color", Color(0.95, 0.55, 0.45))
	v.add_child(lbl_errori)
	return pannello(v)


func _colonna_origini() -> Control:
	var v := VBoxContainer.new()
	v.custom_minimum_size.x = 330
	v.add_child(titolo("2. Origini", 18))
	opt_sesso = OptionButton.new()
	opt_sesso.add_item("Maschio")
	opt_sesso.add_item("Femmina")
	opt_sesso.item_selected.connect(func(i): builder.femmina = i == 1; aggiorna_creazione())
	v.add_child(riga("Sesso", opt_sesso))
	var hm := HBoxContainer.new()
	lbl_mano = etichetta("Mano: da tirare")
	lbl_mano.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl_mano.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hm.add_child(lbl_mano)
	hm.add_child(bottone("Tira", _tira_mano))
	v.add_child(hm)
	opt_razza = OptionButton.new()
	for r in CharacterBuilder.RAZZE_TENTABILI:
		var ch := int(Rules.razza(r)["chance"])
		opt_razza.add_item("%s (%d%%)" % [CharacterBuilder.NOMI_RAZZE[r], ch])
	v.add_child(riga("Razza da tentare", opt_razza))
	var hr := HBoxContainer.new()
	btn_tenta = bottone("Tenta", _tenta_razza)
	hr.add_child(btn_tenta)
	hr.add_child(bottone("Resta umano", func(): builder.accetta_umano(); aggiorna_creazione()))
	v.add_child(hr)
	lbl_razza = etichetta()
	v.add_child(lbl_razza)
	v.add_child(titolo("3. Retaggio", 18))
	v.add_child(bottone("Tira retaggio, XP e denaro", _tira_retaggio))
	lbl_retaggio = etichetta("Non ancora tirato.")
	v.add_child(lbl_retaggio)
	v.add_child(titolo("Valori finali", 18))
	lbl_finali = etichetta()
	v.add_child(lbl_finali)
	return pannello(v)


func _colonna_equipaggiamento() -> Control:
	var v := VBoxContainer.new()
	v.custom_minimum_size.x = 420
	v.add_child(titolo("4. Equipaggiamento e addestramento", 18))
	edit_nome = LineEdit.new()
	edit_nome.text = "Rolf"
	edit_nome.text_changed.connect(func(_t): aggiorna_creazione())
	v.add_child(riga("Nome", edit_nome))
	opt_mischia = OptionButton.new()
	id_mischia.clear()
	for id in Rules.armi_ordine:
		var a: Dictionary = Rules.arma(id)
		if "M" in a["use"] and a.get("max_rank") != null and not ["Lance", "Garotte", "Torch", "Rock", "Net", "Whip", "Giant Axe", "Giant Club", "Giant Mace", "Giant Spear", "Giant Glaive", "Shield"].has(a["name"]):
			id_mischia.append(id)
			opt_mischia.add_item("%s  (Base %d, D%+d, PS %d, MD %d, %d m.a.)" % [a["name"], a["base_chance"], a["damage_mod"], a["min_ps"], a["min_md"], a["cost_sp"]])
	opt_mischia.select(id_mischia.find("broadsword"))
	opt_mischia.item_selected.connect(func(_i): aggiorna_creazione())
	v.add_child(riga("Arma da mischia", opt_mischia))
	spin_rank_m = spin(-1, 10, 0)
	spin_rank_m.value_changed.connect(func(_x): aggiorna_creazione())
	v.add_child(riga("Rank (-1 = nessuno)", spin_rank_m))
	opt_distanza = OptionButton.new()
	opt_distanza.add_item("Nessuna")
	id_distanza = [""]
	for id in Rules.armi_ordine:
		var a2: Dictionary = Rules.arma(id)
		if a2["group"] == "Missile" and a2["name"] != "Blowgun" and a2["name"] != "Giant Bow":
			id_distanza.append(id)
			opt_distanza.add_item("%s  (Base %d, gittata %d, %d m.a.)" % [a2["name"], a2["base_chance"], a2["range_hex"], a2["cost_sp"]])
	opt_distanza.item_selected.connect(func(_i): aggiorna_creazione())
	v.add_child(riga("Arma da tiro", opt_distanza))
	spin_rank_d = spin(-1, 10, -1)
	spin_rank_d.value_changed.connect(func(_x): aggiorna_creazione())
	v.add_child(riga("Rank (-1 = nessuno)", spin_rank_d))
	opt_armatura = OptionButton.new()
	nomi_armature = Rules.armature.keys()
	for n in nomi_armature:
		var ar: Dictionary = Rules.armature[n]
		opt_armatura.add_item("%s  (protezione %d, AG %d, %d m.a.)" % [n, ar["protection"], ar["ag_loss"], ar["cost_sp"]])
	opt_armatura.select(nomi_armature.find("Leather"))
	opt_armatura.item_selected.connect(func(_i): aggiorna_creazione())
	v.add_child(riga("Armatura", opt_armatura))
	opt_scudo = OptionButton.new()
	opt_scudo.add_item("Nessuno")
	nomi_scudi = [""]
	for n in Rules.scudi.keys():
		if n == "Main-Gauche":
			continue
		var sc: Dictionary = Rules.scudi[n]
		nomi_scudi.append(n)
		opt_scudo.add_item("%s  (+%d%% per Rank, MD %d, %d m.a.)" % [n, sc["def_per_rank"], sc["md_loss"], sc["cost_sp"]])
	opt_scudo.item_selected.connect(func(_i): aggiorna_creazione())
	v.add_child(riga("Scudo", opt_scudo))
	spin_rank_s = spin(-1, 4, -1)
	spin_rank_s.value_changed.connect(func(_x): aggiorna_creazione())
	v.add_child(riga("Rank scudo", spin_rank_s))
	lbl_spesa = etichetta()
	v.add_child(lbl_spesa)
	return pannello(v)


func _scrivi_log_creazione() -> void:
	log_creazione.clear()
	for r in builder.registro:
		log_creazione.append_text(r + "\n")


func _tira_punti() -> void:
	builder.tira_punti()
	for k in CharacterBuilder.PRIMARIE:
		spin_caratt[k].set_value_no_signal(5)
		spin_caratt[k].max_value = builder.massimo
	aggiorna_creazione()


func _cambia_caratt(k: String, val: float) -> void:
	builder.valori[k] = int(val)
	aggiorna_creazione()


func _distribuisci(priorita: Array) -> void:
	if builder.punti == 0:
		builder.tira_punti()
		for k in CharacterBuilder.PRIMARIE:
			spin_caratt[k].max_value = builder.massimo
	builder.distribuzione_automatica(priorita)
	for k in CharacterBuilder.PRIMARIE:
		spin_caratt[k].set_value_no_signal(builder.valori[k])
	aggiorna_creazione()


func _tira_mano() -> void:
	if mano_tirata:
		return
	builder.tira_mano()
	mano_tirata = true
	aggiorna_creazione()


func _tenta_razza() -> void:
	builder.tenta_razza(CharacterBuilder.RAZZE_TENTABILI[opt_razza.selected])
	aggiorna_creazione()


func _tira_retaggio() -> void:
	if retaggio_tirato:
		return
	builder.tira_retaggio()
	retaggio_tirato = true
	aggiorna_creazione()


func _personaggio_casuale() -> void:
	builder = CharacterBuilder.new(dadi)
	builder.tira_punti()
	builder.tira_mano()
	mano_tirata = true
	builder.tenta_razza(CharacterBuilder.RAZZE_TENTABILI[dadi.rng.randi_range(0, 3)])
	if not builder.razza_decisa:
		builder.accetta_umano()
	builder.tira_retaggio()
	retaggio_tirato = true
	builder.distribuzione_automatica(["PS", "MD", "EN", "AG", "WP", "MA"])
	for k in CharacterBuilder.PRIMARIE:
		spin_caratt[k].max_value = builder.massimo
		spin_caratt[k].set_value_no_signal(builder.valori[k])
	# equipaggiamento economico e un Rank accessibile
	opt_mischia.select(id_mischia.find("broadsword"))
	opt_armatura.select(nomi_armature.find("Leather"))
	opt_scudo.select(nomi_scudi.find("Small Round Shield"))
	opt_distanza.select(0)
	spin_rank_d.set_value_no_signal(-1)
	spin_rank_s.set_value_no_signal(-1)
	var r := 3
	while r >= -1:
		if r == -1 or (builder.costo_fino_a("broadsword", r) >= 0 and builder.costo_fino_a("broadsword", r) <= builder.xp):
			break
		r -= 1
	spin_rank_m.set_value_no_signal(r)
	aggiorna_creazione()


func _equip_attuale() -> Dictionary:
	return {
		"mischia": id_mischia[max(0, opt_mischia.selected)],
		"rank_m": int(spin_rank_m.value),
		"distanza": id_distanza[max(0, opt_distanza.selected)],
		"rank_d": int(spin_rank_d.value),
		"armatura": nomi_armature[max(0, opt_armatura.selected)],
		"scudo": nomi_scudi[max(0, opt_scudo.selected)],
		"rank_s": int(spin_rank_s.value)}


func _figura_da_builder() -> Fighter:
	var e := _equip_attuale()
	var f := builder.crea_figura(edit_nome.text.strip_edges() if edit_nome.text.strip_edges() != "" else "Eroe", 0)
	f.arma_mischia = e["mischia"]
	f.rank_mischia = e["rank_m"]
	f.arma_distanza = e["distanza"]
	f.rank_distanza = e["rank_d"] if e["distanza"] != "" else -1
	f.armatura = e["armatura"]
	f.scudo = e["scudo"]
	f.rank_scudo = e["rank_s"] if e["scudo"] != "" else -1
	f.prepara_combattimento()
	return f


func _errori_equip(f: Fighter) -> Array:
	var err: Array = []
	var e := _equip_attuale()
	var xp_spesi := 0
	for coppia in [[e["mischia"], e["rank_m"]], [e["distanza"], e["rank_d"]]]:
		if coppia[0] == "" or coppia[1] < 0:
			continue
		var a := Rules.arma(coppia[0])
		var costo := builder.costo_fino_a(coppia[0], coppia[1])
		if costo < 0:
			err.append("%s: Rank %d non ottenibile." % [a["name"], coppia[1]])
		else:
			xp_spesi += costo
		if f.ps < int(a["min_ps"]) or f.md_modificata() < int(a["min_md"]):
			err.append("%s: serve PS %d e MD %d per avere un Rank." % [a["name"], a["min_ps"], a["min_md"]])
	if e["scudo"] != "" and e["rank_s"] >= 0:
		var cs := builder.costo_scudo_fino_a(e["rank_s"])
		if cs < 0:
			err.append("Rank scudo non ottenibile.")
		else:
			xp_spesi += cs
	var denaro := 0
	for id in [e["mischia"], e["distanza"]]:
		if id != "":
			denaro += int(Rules.arma(id)["cost_sp"])
	denaro += int(Rules.armature[e["armatura"]]["cost_sp"])
	if e["scudo"] != "":
		denaro += int(Rules.scudi[e["scudo"]]["cost_sp"])
	if e["scudo"] != "" and Rules.arma(e["mischia"]).get("hands", "1") == "2":
		err.append("Un'arma a due mani non si usa con lo scudo.")
	lbl_spesa.text = "XP: %d spesi su %d (moltiplicatore razza x%.1f)\nDenaro: %d su %d monete d'argento" % [xp_spesi, builder.xp, builder.moltiplicatore_xp(), denaro, builder.denaro]
	if retaggio_tirato:
		if xp_spesi > builder.xp:
			err.append("XP insufficienti per i Rank scelti.")
		if denaro > builder.denaro:
			err.append("Denaro insufficiente per l'equipaggiamento.")
	return err


func aggiorna_creazione() -> void:
	if lbl_punti == null:
		return
	_scrivi_log_creazione()
	if builder.punti > 0:
		lbl_punti.text = "%d punti, massimo %d. Assegnati %d, restano %d." % [builder.punti, builder.massimo, builder.punti_assegnati(), builder.punti - builder.punti_assegnati()]
	lbl_mano.text = "Mano primaria: " + (builder.mano if mano_tirata else "da tirare")
	btn_tenta.text = "Tenta (%d rimasti)" % builder.tentativi_razza
	btn_tenta.disabled = builder.razza_decisa
	lbl_razza.text = "Razza: %s%s" % [CharacterBuilder.NOMI_RAZZE[builder.razza], "" if builder.razza_decisa else " (non ancora decisa)"]
	if retaggio_tirato:
		lbl_retaggio.text = "%s, %s.\n%d XP, %d monete d'argento." % [builder.stato_sociale, builder.nascita, builder.xp, builder.denaro]
	var errori: Array = builder.errori_assegnazione()
	var f := _figura_da_builder()
	lbl_finali.text = "PS %d  MD %d  AG %d  EN %d  MA %d  WP %d\nFatica %d  Percezione %d  TMR %d\nStrike Chance %d  Difesa %d  Iniziativa %d" % [f.ps, f.md, f.ag, f.en, f.ma, f.wp, f.ft, f.pc, f.tmr(), f.strike_chance("mischia"), f.difesa(false, "melee"), f.valore_iniziativa()]
	errori.append_array(_errori_equip(f))
	if not builder.razza_decisa:
		errori.append("Decidi la razza (tentativo o umano).")
	if not retaggio_tirato:
		errori.append("Tira il retaggio.")
	if not mano_tirata:
		errori.append("Tira la mano primaria.")
	lbl_errori.text = "\n".join(errori)
	btn_armi.disabled = errori.size() > 0


func _alle_armi() -> void:
	eroe = _figura_da_builder()
	eroe.mano = builder.mano
	radice_creazione.queue_free()
	radice_creazione = null
	lbl_punti = null
	mostra_arena()


# ============================================================ arena

func _crea_mappa() -> HexGrid:
	var g := HexGrid.new()
	g.larghezza = 17
	g.altezza = 11
	for o in [Vector2i(5, 2), Vector2i(5, 3), Vector2i(11, 7), Vector2i(11, 8), Vector2i(8, 5), Vector2i(2, 8), Vector2i(14, 2)]:
		g.muri[HexGrid.offset_ad_assiale(o.x, o.y)] = true
	for o in [Vector2i(7, 3), Vector2i(9, 7), Vector2i(4, 6), Vector2i(12, 4)]:
		g.riparati[HexGrid.offset_ad_assiale(o.x, o.y)] = true
	return g


func mostra_arena() -> void:
	var g := _crea_mappa()
	combat = Combat.new(g, dadi)
	var compagni := [
		CharacterBuilder.png(dadi, "Brunilde", 0, "Human", ["PS", "EN", "MD", "AG", "WP", "MA"], "spear", 2, "Chainmail", "Large Round Shield", 1),
		CharacterBuilder.png(dadi, "Tobia", 0, "Halfling", ["MD", "AG", "EN", "PS", "WP", "MA"], "short_sword", 1, "Leather", "", -1, "sling", 2)]
	var nemici := [
		CharacterBuilder.png(dadi, "Capobanda", 1, "Human", ["PS", "MD", "EN", "AG", "WP", "MA"], "broadsword", 2, "Chainmail", "Small Round Shield", 1),
		CharacterBuilder.png(dadi, "Orco predone", 1, "Orc", ["PS", "EN", "MD", "AG", "WP", "MA"], "scimitar", 1, "Leather"),
		CharacterBuilder.png(dadi, "Orco lanciere", 1, "Orc", ["PS", "EN", "MD", "AG", "WP", "MA"], "spear", 1, "Leather"),
		CharacterBuilder.png(dadi, "Balestriere", 1, "Human", ["MD", "AG", "EN", "PS", "WP", "MA"], "dagger", 1, "Leather", "", -1, "crossbow", 1)]
	var squadra: Array = [eroe]
	squadra.append_array(compagni)
	var posti_g := [Vector2i(2, 4), Vector2i(2, 6), Vector2i(1, 5)]
	var posti_n := [Vector2i(13, 5), Vector2i(12, 3), Vector2i(12, 7), Vector2i(15, 5)]
	for i in squadra.size():
		squadra[i].hex = HexGrid.offset_ad_assiale(posti_g[i].x, posti_g[i].y)
		squadra[i].facing = 0
		combat.figure.append(squadra[i])
	for i in nemici.size():
		nemici[i].hex = HexGrid.offset_ad_assiale(posti_n[i].x, posti_n[i].y)
		nemici[i].facing = 3
		combat.figure.append(nemici[i])
	nemici[3].preparata = "distanza"
	compagni[1].preparata = "distanza"

	radice_arena = HBoxContainer.new()
	radice_arena.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(radice_arena)
	vista = ArenaView.new()
	vista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vista.esagono_cliccato.connect(_clic_esagono)
	vista.esagono_sotto.connect(_esagono_sotto)
	radice_arena.add_child(vista)
	var lato := VBoxContainer.new()
	lato.custom_minimum_size.x = 470
	lato.add_theme_constant_override("separation", 8)
	radice_arena.add_child(pannello(lato))
	lato.add_child(titolo("Arena", 24))
	lbl_scheda = RichTextLabel.new()
	lbl_scheda.bbcode_enabled = true
	lbl_scheda.fit_content = true
	lato.add_child(lbl_scheda)
	box_azioni = VBoxContainer.new()
	lato.add_child(box_azioni)
	lbl_sotto = etichetta()
	lbl_sotto.add_theme_color_override("font_color", Color(0.75, 0.72, 0.65))
	lato.add_child(lbl_sotto)
	lato.add_child(titolo("Cronaca", 18))
	log_arena = RichTextLabel.new()
	log_arena.bbcode_enabled = true
	log_arena.scroll_following = true
	log_arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_arena.custom_minimum_size.y = 260
	lato.add_child(log_arena)

	combat.cambiato.connect(_aggiorna_arena)
	vista.imposta(combat)
	combat.inizia()
	_aggiorna_arena()


func _aggiorna_arena() -> void:
	if combat == null or log_arena == null:
		return
	log_arena.clear()
	var inizio: int = max(0, combat.registro.size() - 200)
	for i in range(inizio, combat.registro.size()):
		log_arena.append_text(combat.registro[i] + "\n")
	for c in box_azioni.get_children():
		c.queue_free()
	_mostra_scheda(combat.attore)
	vista.evidenziati = bersagli_correnti
	vista.queue_redraw()
	match combat.fase:
		"scelta_iniziativa":
			box_azioni.add_child(etichetta("Hai vinto l'iniziativa: il tuo gruppo agisce per primo o lascia muovere i nemici?"))
			box_azioni.add_child(bottone("Agiamo per primi", func(): combat.scegli_iniziativa(true)))
			box_azioni.add_child(bottone("Lasciamo agire i nemici", func(): combat.scegli_iniziativa(false)))
		"azione_giocatore":
			_mostra_azioni()
		"fine":
			box_azioni.add_child(titolo("Vittoria!" if combat.vincitore == 0 else "Sconfitta", 22))
			box_azioni.add_child(bottone("Nuova battaglia con lo stesso eroe", _nuova_battaglia))
			box_azioni.add_child(bottone("Crea un nuovo personaggio", _nuovo_personaggio))
		"pronto":
			if timer_ia.is_stopped():
				timer_ia.start()


func _passo_ia() -> void:
	if combat and combat.fase == "pronto":
		combat.passo()


func _mostra_scheda(f: Fighter) -> void:
	if f == null:
		lbl_scheda.text = ""
		return
	var a := f.dati_arma()
	var testo := "[font_size=20][b]%s[/b][/font_size]  %s  [color=#a89f8a](%s)[/color]\n" % [f.nome, CharacterBuilder.NOMI_RAZZE.get(f.razza, f.razza), "tuo" if f.lato == 0 else "nemico"]
	testo += "PS %d  MD %d  AG %d (mod. %d)  EN %d  WP %d  PC %d\n" % [f.ps, f.md, f.ag, f.ag_modificata(), f.en, f.wp, f.pc_attuale()]
	testo += "Fatica [color=#e6c34a]%d/%d[/color]   Resistenza [color=#e06050]%d/%d[/color]   TMR %d\n" % [f.fatica, f.ft, f.resistenza, f.en, f.tmr()]
	testo += "%s (Rank %s): Strike Chance %d, danno D10%+d\n" % [a.get("name", "?"), str(f.rank_arma()) if f.rank_arma() >= 0 else "nessuno", f.strike_chance(), f.modificatore_danno()]
	testo += "Difesa %d   Armatura %s (protezione %d)%s\n" % [f.difesa(false, "melee"), f.armatura, f.protezione(), ("   Scudo " + f.scudo) if f.scudo != "" else ""]
	testo += "Stato: %s" % f.descrizione_stato()
	if f.ferite.size() > 0:
		testo += "\n[color=#d9534f]Ferite: %s[/color]" % "; ".join(f.ferite)
	lbl_scheda.text = testo


func _mostra_azioni() -> void:
	var f := combat.attore
	if azione_corrente != "":
		box_azioni.add_child(etichetta("Scegli un esagono evidenziato sulla mappa."))
		box_azioni.add_child(bottone("Annulla", _annulla))
		return
	box_azioni.add_child(etichetta("Turno di %s: scegli un'azione%s." % [f.nome, " (ingaggiato)" if combat.e_ingaggiato(f) else ""]))
	var griglia_b := GridContainer.new()
	griglia_b.columns = 2
	for az in combat.azioni_disponibili(f):
		var id: String = az["id"]
		var b := bottone(az["nome"], func(): _scegli_azione(id))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if ["attacco", "carica", "tira"].has(id) and combat.bersagli(f, id).is_empty():
			b.disabled = true
		griglia_b.add_child(b)
	box_azioni.add_child(griglia_b)


func _scegli_azione(id: String) -> void:
	var f := combat.attore
	var lista := combat.bersagli(f, id)
	if lista.is_empty() and not ["muovi", "schiva_muovi", "indietreggia", "ritirata_dif", "ritirata_off", "attacco", "carica", "tira", "gira"].has(id):
		combat.esegui(f, id)
		_chiudi_azione()
		return
	if lista.is_empty():
		combat.scrivi("Nessun bersaglio valido per questa azione.")
		_aggiorna_arena()
		return
	azione_corrente = id
	bersagli_correnti = lista
	_aggiorna_arena()


func _clic_esagono(h: Vector2i) -> void:
	if combat.fase != "azione_giocatore" or azione_corrente == "":
		var g := combat.figura_in(h)
		if g:
			_mostra_scheda(g)
		return
	if not bersagli_correnti.has(h):
		return
	combat.esegui(combat.attore, azione_corrente, h)
	_chiudi_azione()


func _chiudi_azione() -> void:
	azione_corrente = ""
	bersagli_correnti = []
	combat.fine_azione_giocatore()


func _annulla() -> void:
	azione_corrente = ""
	bersagli_correnti = []
	_aggiorna_arena()


func _esagono_sotto(h: Vector2i) -> void:
	if lbl_sotto == null:
		return
	var g := combat.figura_in(h)
	if g:
		lbl_sotto.text = "%s: Fatica %d/%d, Resistenza %d/%d, %s." % [g.nome, g.fatica, g.ft, g.resistenza, g.en, g.descrizione_stato()]
	elif combat.griglia.muri.has(h):
		lbl_sotto.text = "Muro: blocca movimento e tiro."
	elif combat.griglia.riparati.has(h):
		lbl_sotto.text = "Macerie: chi sta qui è al riparo (-20 ai tiri contro di lui)."
	else:
		lbl_sotto.text = ""


func _nuova_battaglia() -> void:
	radice_arena.queue_free()
	radice_arena = null
	log_arena = null
	var nuovo := Fighter.new()
	for p in ["nome", "lato", "razza", "femmina", "mano", "ps", "md", "ag", "en", "ma", "wp", "ft", "pc", "arma_mischia", "rank_mischia", "arma_distanza", "rank_distanza", "scudo", "rank_scudo", "armatura"]:
		nuovo.set(p, eroe.get(p))
	eroe = nuovo
	eroe.prepara_combattimento()
	mostra_arena()


func _nuovo_personaggio() -> void:
	log_arena = null
	mostra_creazione()
