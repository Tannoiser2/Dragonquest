class_name Creazione
extends MarginContainer
## Creazione completa del personaggio (Libro Primo regole 3-8, Libro Secondo 34, Libro Terzo 52-66):
## caratteristiche, origini, retaggio, armi, Collegio di magia e incantesimi, abilità.

signal pronto(f: Fighter)

var m: Node                        # la scena principale, per stili e font
var builder: CharacterBuilder
var retaggio_tirato := false
var mano_tirata := false

var spin_caratt: Dictionary = {}
var lbl_punti: Label
var lbl_errori: Label
var lbl_finali: RichTextLabel
var lbl_spesa: Label
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
var btn_armi: Button
var log_creazione: RichTextLabel
var id_mischia: Array = []
var id_distanza: Array = [""]
var nomi_armature: Array = []
var nomi_scudi: Array = [""]
# magia
var opt_collegio: OptionButton
var opt_scuola: OptionButton
var lbl_collegio: Label
var lista_magia: VBoxContainer
var num_collegi: Array = [0]
# abilità
var lista_abilita: VBoxContainer
var spin_furtivita: SpinBox
var spin_equitazione: SpinBox


func _init(principale: Node, d: Dice) -> void:
	m = principale
	builder = CharacterBuilder.new(d)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	for lato in ["left", "right", "top", "bottom"]:
		add_theme_constant_override("margin_" + lato, 20)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	v.add_child(m.titolo("DragonQuest - Crea il tuo avventuriero", 30))
	v.add_child(m.etichetta("Regole dei tre Libri (DragonQuest 3a edizione). Compila le schede in ordine; ogni tiro compare nel registro a destra."))
	var corpo := HBoxContainer.new()
	corpo.add_theme_constant_override("separation", 14)
	corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(corpo)
	var schede := TabContainer.new()
	schede.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	schede.size_flags_stretch_ratio = 2.6
	schede.add_theme_font_override("font", m.font_grassetto)
	corpo.add_child(schede)
	schede.add_child(_scheda_caratteristiche())
	schede.add_child(_scheda_armi())
	schede.add_child(_scheda_magia())
	schede.add_child(_scheda_abilita())
	schede.set_tab_title(0, "1. Caratteristiche e origini")
	schede.set_tab_title(1, "2. Armi e protezioni")
	schede.set_tab_title(2, "3. Magia")
	schede.set_tab_title(3, "4. Abilità")
	corpo.add_child(_colonna_riepilogo())
	var fondo := HBoxContainer.new()
	fondo.add_theme_constant_override("separation", 12)
	fondo.add_child(m.bottone("Personaggio casuale", _personaggio_casuale))
	btn_armi = m.bottone("Alle armi!", _alle_armi)
	btn_armi.add_theme_font_override("font", m.font_titolo)
	fondo.add_child(btn_armi)
	v.add_child(fondo)
	aggiorna()


# ============================================================ schede

func _scorrevole(contenuto: Control) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	contenuto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(contenuto)
	return sc


func _scheda_caratteristiche() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	var c1 := VBoxContainer.new()
	c1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c1.add_child(m.titolo("Caratteristiche", 18))
	c1.add_child(m.bottone("Tira i punti (2D10)", _tira_punti))
	lbl_punti = m.etichetta("Punti non ancora tirati.")
	c1.add_child(lbl_punti)
	for k in CharacterBuilder.PRIMARIE:
		var s: SpinBox = m.spin(5, 25, 5)
		s.value_changed.connect(func(val): builder.valori[k] = int(val); aggiorna())
		spin_caratt[k] = s
		c1.add_child(m.riga(CharacterBuilder.NOMI_CARATT[k] + " (" + k + ")", s))
	c1.add_child(m.bottone("Distribuisci da guerriero", func(): _distribuisci(["PS", "MD", "EN", "AG", "WP", "MA"])))
	c1.add_child(m.bottone("Distribuisci da schermidore", func(): _distribuisci(["MD", "AG", "EN", "PS", "WP", "MA"])))
	c1.add_child(m.bottone("Distribuisci da mago", func(): _distribuisci(["MA", "WP", "EN", "AG", "MD", "PS"])))
	h.add_child(c1)
	var c2 := VBoxContainer.new()
	c2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c2.add_child(m.titolo("Origini", 18))
	opt_sesso = OptionButton.new()
	opt_sesso.add_item("Maschio")
	opt_sesso.add_item("Femmina")
	opt_sesso.item_selected.connect(func(i): builder.femmina = i == 1; aggiorna())
	c2.add_child(m.riga("Sesso", opt_sesso))
	var hm := HBoxContainer.new()
	lbl_mano = m.etichetta("Mano primaria: da tirare")
	lbl_mano.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl_mano.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hm.add_child(lbl_mano)
	hm.add_child(m.bottone("Tira", _tira_mano))
	c2.add_child(hm)
	opt_razza = OptionButton.new()
	for r in CharacterBuilder.RAZZE_TENTABILI:
		opt_razza.add_item("%s (%d%%)" % [CharacterBuilder.NOMI_RAZZE[r], int(Rules.razza(r)["chance"])])
	c2.add_child(m.riga("Razza da tentare", opt_razza))
	var hr := HBoxContainer.new()
	btn_tenta = m.bottone("Tenta", _tenta_razza)
	hr.add_child(btn_tenta)
	hr.add_child(m.bottone("Resta umano", func(): builder.accetta_umano(); aggiorna()))
	c2.add_child(hr)
	lbl_razza = m.etichetta()
	c2.add_child(lbl_razza)
	c2.add_child(m.titolo("Retaggio e aspetto", 18))
	c2.add_child(m.bottone("Tira retaggio, aspetto, XP e denaro", _tira_retaggio))
	lbl_retaggio = m.etichetta("Non ancora tirato.")
	c2.add_child(lbl_retaggio)
	h.add_child(c2)
	return _scorrevole(h)


func _scheda_armi() -> Control:
	var v := VBoxContainer.new()
	edit_nome = LineEdit.new()
	edit_nome.text = "Rolf"
	edit_nome.text_changed.connect(func(_t): aggiorna())
	v.add_child(m.riga("Nome", edit_nome))
	opt_mischia = OptionButton.new()
	for id in Rules.armi_ordine:
		var a: Dictionary = Rules.arma(id)
		if "M" in a["use"] and a.get("max_rank") != null and not ["Lance", "Garotte", "Torch", "Rock", "Net", "Whip", "Giant Axe", "Giant Club", "Giant Mace", "Giant Spear", "Giant Glaive", "Shield"].has(a["name"]):
			id_mischia.append(id)
			opt_mischia.add_item("%s  (Base %d, D%+d, PS %d, MD %d, %d m.a.)" % [a["name"], a["base_chance"], a["damage_mod"], a["min_ps"], a["min_md"], a["cost_sp"]])
	opt_mischia.select(id_mischia.find("broadsword"))
	opt_mischia.item_selected.connect(func(_i): aggiorna())
	v.add_child(m.riga("Arma da mischia", opt_mischia))
	spin_rank_m = m.spin(-1, 10, 0)
	spin_rank_m.value_changed.connect(func(_x): aggiorna())
	v.add_child(m.riga("Rank (-1 = nessuno)", spin_rank_m))
	opt_distanza = OptionButton.new()
	opt_distanza.add_item("Nessuna")
	for id in Rules.armi_ordine:
		var a2: Dictionary = Rules.arma(id)
		if a2["group"] == "Missile" and a2["name"] != "Blowgun" and a2["name"] != "Giant Bow":
			id_distanza.append(id)
			opt_distanza.add_item("%s  (Base %d, gittata %d, %d m.a.)" % [a2["name"], a2["base_chance"], a2["range_hex"], a2["cost_sp"]])
	opt_distanza.item_selected.connect(func(_i): aggiorna())
	v.add_child(m.riga("Arma da tiro", opt_distanza))
	spin_rank_d = m.spin(-1, 10, -1)
	spin_rank_d.value_changed.connect(func(_x): aggiorna())
	v.add_child(m.riga("Rank (-1 = nessuno)", spin_rank_d))
	opt_armatura = OptionButton.new()
	nomi_armature = Rules.armature.keys()
	for n in nomi_armature:
		var ar: Dictionary = Rules.armature[n]
		opt_armatura.add_item("%s  (protezione %d, AG %d, %d m.a.)" % [n, ar["protection"], ar["ag_loss"], ar["cost_sp"]])
	opt_armatura.select(nomi_armature.find("Leather"))
	opt_armatura.item_selected.connect(func(_i): aggiorna())
	v.add_child(m.riga("Armatura", opt_armatura))
	opt_scudo = OptionButton.new()
	opt_scudo.add_item("Nessuno")
	for n in Rules.scudi.keys():
		if n == "Main-Gauche":
			continue
		var sc: Dictionary = Rules.scudi[n]
		nomi_scudi.append(n)
		opt_scudo.add_item("%s  (+%d%% per Rank, MD %d, %d m.a.)" % [n, sc["def_per_rank"], sc["md_loss"], sc["cost_sp"]])
	opt_scudo.item_selected.connect(func(_i): aggiorna())
	v.add_child(m.riga("Scudo", opt_scudo))
	spin_rank_s = m.spin(-1, 4, -1)
	spin_rank_s.value_changed.connect(func(_x): aggiorna())
	v.add_child(m.riga("Rank scudo", spin_rank_s))
	v.add_child(m.etichetta("Gli Adept non possono lanciare incantesimi a contatto con il ferro freddo: niente armature di metallo (Scale, Chainmail, Plate) né armi di ferro impugnate. Bastone, randello, fionda e archi vanno bene."))
	return _scorrevole(v)


func _scheda_magia() -> Control:
	var v := VBoxContainer.new()
	opt_collegio = OptionButton.new()
	opt_collegio.add_item("Nessun Collegio")
	num_collegi = [0]
	for num in Rules.collegi.keys():
		var c: Dictionary = Rules.collegio(num)
		num_collegi.append(int(num))
		opt_collegio.add_item("%s  (%s, MA %d)" % [c["nome"], Rules.NOMI_RAMI.get(c["branch"], ""), Rules.ma_richiesta(int(num))])
	opt_collegio.item_selected.connect(_cambia_collegio)
	v.add_child(m.riga("Collegio di magia", opt_collegio))
	opt_scuola = OptionButton.new()
	for sc in ["Star Mage (Mago delle stelle)", "Dark Mage (Mago oscuro)", "Shadow Weaver (Tessitore d'ombre)"]:
		opt_scuola.add_item(sc)
	opt_scuola.item_selected.connect(func(i): builder.scuola_celeste = ["Star Mage", "Dark Mage", "Shadow Weaver"][i]; aggiorna())
	v.add_child(m.riga("Scuola (solo Magie Celesti)", opt_scuola))
	lbl_collegio = m.etichetta()
	v.add_child(lbl_collegio)
	lista_magia = VBoxContainer.new()
	v.add_child(lista_magia)
	return _scorrevole(v)


func _scheda_abilita() -> Control:
	var v := VBoxContainer.new()
	v.add_child(m.etichetta("Ogni personaggio parla il Comune a Rank 8 (e la lingua della sua razza). Una sola abilità a Rank 0 costa appena 100 XP prima della prima avventura (8.6): lo sconto è applicato da solo alla più cara."))
	lista_abilita = VBoxContainer.new()
	v.add_child(lista_abilita)
	for a in Rules.abilita.get("skills", []):
		if a["id"] in ["speak_language", "read_write"]:
			continue
		var riga := HBoxContainer.new()
		var l: Label = m.etichetta("%s" % a["nome"])
		l.custom_minimum_size.x = 170
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		riga.add_child(l)
		var s: SpinBox = m.spin(-1, 10, -1)
		s.custom_minimum_size.x = 90
		var id: String = a["id"]
		s.value_changed.connect(func(val): builder.rank_abilita[id] = int(val); aggiorna())
		riga.add_child(s)
		var d: Label = m.etichetta(a["summary_it"])
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		d.add_theme_font_size_override("font_size", 14)
		d.add_theme_color_override("font_color", Color(0.78, 0.74, 0.66))
		riga.add_child(d)
		lista_abilita.add_child(riga)
		lista_abilita.add_child(HSeparator.new())
	spin_furtivita = m.spin(0, 10, 0)
	spin_furtivita.value_changed.connect(func(val): builder.rank_furtivita = int(val); aggiorna())
	v.add_child(m.riga("Furtività (Rank)", spin_furtivita))
	spin_equitazione = m.spin(0, 10, 0)
	spin_equitazione.value_changed.connect(func(val): builder.rank_equitazione = int(val); aggiorna())
	v.add_child(m.riga("Equitazione (Rank)", spin_equitazione))
	return _scorrevole(v)


func _colonna_riepilogo() -> Control:
	var v := VBoxContainer.new()
	v.custom_minimum_size.x = 380
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(m.titolo("Riepilogo", 18))
	lbl_finali = RichTextLabel.new()
	lbl_finali.bbcode_enabled = true
	lbl_finali.fit_content = true
	v.add_child(lbl_finali)
	lbl_spesa = m.etichetta()
	v.add_child(lbl_spesa)
	lbl_errori = m.etichetta()
	lbl_errori.add_theme_color_override("font_color", Color(0.95, 0.55, 0.45))
	v.add_child(lbl_errori)
	v.add_child(m.titolo("Registro dei tiri", 16))
	log_creazione = RichTextLabel.new()
	log_creazione.bbcode_enabled = true
	log_creazione.scroll_following = true
	log_creazione.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(log_creazione)
	var p: Control = m.pannello(v)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


# ============================================================ magia: elenco incantesimi

func _cambia_collegio(i: int) -> void:
	builder.collegio = int(num_collegi[i])
	if builder.collegio == 44 and builder.scuola_celeste == "":
		builder.scuola_celeste = ["Star Mage", "Dark Mage", "Shadow Weaver"][opt_scuola.selected]
	builder.rank_magia.clear()
	builder.speciali.clear()
	_ricostruisci_magia()
	aggiorna()


func _ricostruisci_magia() -> void:
	for ch in lista_magia.get_children():
		ch.queue_free()
	if builder.collegio == 0:
		return
	lista_magia.add_child(m.titolo("Conoscenza generale (gratuita a Rank 0)", 16))
	for v in builder.voci_generali():
		lista_magia.add_child(_riga_incantesimo(v, true))
	lista_magia.add_child(m.titolo("Conoscenza speciale (si impara a pagamento)", 16))
	for v in builder.voci_speciali():
		lista_magia.add_child(_riga_incantesimo(v, false))


func _riga_incantesimo(v: Dictionary, generale: bool) -> Control:
	var riga := HBoxContainer.new()
	var codice: String = v["code"]
	var combat := not Rules.spec_combattimento(builder.collegio, codice).is_empty()
	if not generale:
		var chk := CheckBox.new()
		chk.text = "Impara"
		chk.toggled.connect(func(on):
			if on and not builder.speciali.has(codice):
				builder.speciali.append(codice)
				builder.rank_magia[codice] = 0
			elif not on:
				builder.speciali.erase(codice)
				builder.rank_magia.erase(codice)
			aggiorna())
		riga.add_child(chk)
	var bc = v.get("base_chance", null)
	var testo := "%s  %s%s" % [codice, v.get("nome", v["name"]), ("  [combattimento]" if combat else "")]
	var l: Label = m.etichetta(testo)
	l.custom_minimum_size.x = 380
	l.tooltip_text = "%s\nBase Chance %s  Moltiplicatore XP %s\n%s" % [v["name"], str(bc) if bc != null else "-", str(v.get("experience_multiple", "-")), String(v.get("effects", v.get("text", ""))).substr(0, 600)]
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	if combat:
		l.add_theme_color_override("font_color", Color(0.85, 0.70, 0.35))
	riga.add_child(l)
	if v["type"] != "talento" and v.get("experience_multiple") != null:
		var s: SpinBox = m.spin(0, 20, 0)
		s.prefix = "Rank"
		s.custom_minimum_size.x = 110
		s.value_changed.connect(func(val):
			if generale or builder.speciali.has(codice):
				builder.rank_magia[codice] = int(val)
			aggiorna())
		riga.add_child(s)
	var info: Label = m.etichetta("BC %s" % (str(bc) if bc != null else "-"))
	info.add_theme_color_override("font_color", Color(0.75, 0.72, 0.65))
	riga.add_child(info)
	return riga


# ============================================================ azioni

func _tira_punti() -> void:
	builder.tira_punti()
	for k in CharacterBuilder.PRIMARIE:
		spin_caratt[k].set_value_no_signal(5)
		spin_caratt[k].max_value = builder.massimo
	aggiorna()


func _distribuisci(priorita: Array) -> void:
	if builder.punti == 0:
		builder.tira_punti()
		for k in CharacterBuilder.PRIMARIE:
			spin_caratt[k].max_value = builder.massimo
	builder.distribuzione_automatica(priorita)
	for k in CharacterBuilder.PRIMARIE:
		spin_caratt[k].set_value_no_signal(builder.valori[k])
	aggiorna()


func _tira_mano() -> void:
	if mano_tirata:
		return
	builder.tira_mano()
	mano_tirata = true
	aggiorna()


func _tenta_razza() -> void:
	builder.tenta_razza(CharacterBuilder.RAZZE_TENTABILI[opt_razza.selected])
	aggiorna()


func _tira_retaggio() -> void:
	if retaggio_tirato:
		return
	builder.tira_retaggio()
	builder.tira_aspetto()
	retaggio_tirato = true
	aggiorna()


func _personaggio_casuale() -> void:
	var d := builder.dadi
	builder = CharacterBuilder.new(d)
	builder.tira_punti()
	builder.tira_mano()
	mano_tirata = true
	builder.tenta_razza(CharacterBuilder.RAZZE_TENTABILI[d.rng.randi_range(0, 3)])
	if not builder.razza_decisa:
		builder.accetta_umano()
	builder.tira_retaggio()
	builder.tira_aspetto()
	retaggio_tirato = true
	builder.distribuzione_automatica(["PS", "MD", "EN", "AG", "WP", "MA"])
	for k in CharacterBuilder.PRIMARIE:
		spin_caratt[k].max_value = builder.massimo
		spin_caratt[k].set_value_no_signal(builder.valori[k])
	opt_mischia.select(id_mischia.find("broadsword"))
	opt_armatura.select(nomi_armature.find("Leather"))
	opt_scudo.select(nomi_scudi.find("Small Round Shield"))
	opt_distanza.select(0)
	opt_collegio.select(0)
	builder.collegio = 0
	_ricostruisci_magia()
	spin_rank_d.set_value_no_signal(-1)
	spin_rank_s.set_value_no_signal(-1)
	var r := 3
	while r >= -1:
		if r == -1 or (builder.costo_fino_a("broadsword", r) >= 0 and builder.costo_fino_a("broadsword", r) <= builder.xp):
			break
		r -= 1
	spin_rank_m.set_value_no_signal(r)
	aggiorna()


func _equip() -> Dictionary:
	return {
		"mischia": id_mischia[max(0, opt_mischia.selected)],
		"rank_m": int(spin_rank_m.value),
		"distanza": id_distanza[max(0, opt_distanza.selected)],
		"rank_d": int(spin_rank_d.value),
		"armatura": nomi_armature[max(0, opt_armatura.selected)],
		"scudo": nomi_scudi[max(0, opt_scudo.selected)],
		"rank_s": int(spin_rank_s.value)}


func figura() -> Fighter:
	var e := _equip()
	var nome := edit_nome.text.strip_edges() if edit_nome.text.strip_edges() != "" else "Eroe"
	var f := builder.crea_figura(nome, 0)
	f.arma_mischia = e["mischia"]
	f.rank_mischia = e["rank_m"]
	f.arma_distanza = e["distanza"]
	f.rank_distanza = e["rank_d"] if e["distanza"] != "" else -1
	f.armatura = e["armatura"]
	f.scudo = e["scudo"]
	f.rank_scudo = e["rank_s"] if e["scudo"] != "" else -1
	f.mano = builder.mano
	f.prepara_combattimento()
	return f


func _conti(f: Fighter) -> Dictionary:
	## XP e denaro spesi, con gli errori di equipaggiamento.
	var err: Array = []
	var e := _equip()
	var xp_armi := 0
	for coppia in [[e["mischia"], e["rank_m"]], [e["distanza"], e["rank_d"]]]:
		if coppia[0] == "" or coppia[1] < 0:
			continue
		var a := Rules.arma(coppia[0])
		var costo := builder.costo_fino_a(coppia[0], coppia[1])
		if costo < 0:
			err.append("%s: Rank %d non ottenibile." % [a["name"], coppia[1]])
		else:
			xp_armi += costo
		if f.ps < int(a["min_ps"]) or f.md_modificata() < int(a["min_md"]):
			err.append("%s: servono PS %d e MD %d per avere un Rank." % [a["name"], a["min_ps"], a["min_md"]])
	if e["scudo"] != "" and e["rank_s"] >= 0:
		var cs := builder.costo_scudo_fino_a(e["rank_s"])
		if cs < 0:
			err.append("Rank scudo non ottenibile.")
		else:
			xp_armi += cs
	if e["scudo"] != "" and Rules.arma(e["mischia"]).get("hands", "1") == "2":
		err.append("Un'arma a due mani non si usa con lo scudo.")
	var denaro := 0
	for id in [e["mischia"], e["distanza"]]:
		if id != "":
			denaro += int(Rules.arma(id)["cost_sp"])
	denaro += int(Rules.armature[e["armatura"]]["cost_sp"])
	if e["scudo"] != "":
		denaro += int(Rules.scudi[e["scudo"]]["cost_sp"])
	var xp_magia := builder.costo_xp_magia()
	var xp_abil := builder.costo_xp_abilita()
	var denaro_magia := builder.costo_denaro_magia()
	return {"xp_armi": xp_armi, "xp_magia": xp_magia, "xp_abilita": xp_abil, "denaro": denaro + denaro_magia,
		"denaro_magia": denaro_magia, "errori": err}


func aggiorna() -> void:
	if lbl_finali == null:
		return
	log_creazione.clear()
	for r in builder.registro:
		log_creazione.append_text(r + "\n")
	if builder.punti > 0:
		lbl_punti.text = "%d punti, massimo %d. Assegnati %d, restano %d." % [builder.punti, builder.massimo, builder.punti_assegnati(), builder.punti - builder.punti_assegnati()]
	lbl_mano.text = "Mano primaria: " + (builder.mano if mano_tirata else "da tirare")
	btn_tenta.text = "Tenta (%d rimasti)" % builder.tentativi_razza
	btn_tenta.disabled = builder.razza_decisa
	lbl_razza.text = "Razza: %s%s" % [CharacterBuilder.NOMI_RAZZE[builder.razza], "" if builder.razza_decisa else " (non ancora decisa)"]
	if retaggio_tirato:
		lbl_retaggio.text = "%s, %s.\nAspetto: %s. Bellezza %d.\n%d XP, %d monete d'argento." % [builder.stato_sociale, builder.nascita, builder.aspetto, builder.bellezza, builder.xp, builder.denaro]
	var f := figura()
	var conti := _conti(f)
	var xp_tot: int = conti["xp_armi"] + conti["xp_magia"] + conti["xp_abilita"]
	var testo := "[b]%s[/b], %s\n" % [f.nome, CharacterBuilder.NOMI_RAZZE[builder.razza]]
	testo += "PS %d  MD %d  AG %d  EN %d  MA %d  WP %d\n" % [f.ps, f.md, f.ag, f.en, f.ma, f.wp]
	testo += "Fatica %d  Percezione %d  TMR %d\n" % [f.ft, f.pc, f.tmr()]
	testo += "Strike Chance %d  Difesa %d  Iniziativa %d\n" % [f.strike_chance("mischia"), f.difesa(false, "melee"), f.valore_iniziativa()]
	if f.collegio > 0:
		testo += "Collegio: %s, Magic Resistance %d\n" % [Rules.collegio(f.collegio)["nome"], f.wp]
		if f.ferro_freddo():
			testo += "[color=#e08070]Ferro freddo: con questo equipaggiamento non può lanciare.[/color]\n"
	var nomi_ab: Array = []
	for id in f.abilita:
		nomi_ab.append("%s %d" % [Rules.abilita_scheda(id)["nome"], f.abilita[id]])
	if nomi_ab.size() > 0:
		testo += "Abilità: " + ", ".join(nomi_ab) + "\n"
	lbl_finali.text = testo
	lbl_spesa.text = "XP: armi %d + magia %d + abilità %d = %d su %d (razza x%.1f)\nDenaro: %d su %d monete d'argento%s" % [conti["xp_armi"], conti["xp_magia"], conti["xp_abilita"], xp_tot, builder.xp, builder.moltiplicatore_xp(), conti["denaro"], builder.denaro, (" (incantesimi %d)" % conti["denaro_magia"]) if conti["denaro_magia"] > 0 else ""]
	if builder.collegio > 0:
		lbl_collegio.text = "Richiede Attitudine magica %d. Incantesimi e rituali di Rank 5 o meno: %d su %d. Passa il mouse su un incantesimo per i dettagli; in oro quelli usabili in combattimento.\n%s" % [Rules.ma_richiesta(builder.collegio), builder.conoscenze_basse(), builder.valore_finale("MA"), String(Rules.collegio(builder.collegio).get("requirements", "")).substr(0, 300)]
	else:
		lbl_collegio.text = "Un personaggio senza Collegio ha +20 alla resistenza contro la magia."
	opt_scuola.disabled = builder.collegio != 44
	var errori: Array = builder.errori_assegnazione()
	errori.append_array(conti["errori"])
	errori.append_array(builder.errori_magia())
	errori.append_array(builder.errori_abilita())
	if not builder.razza_decisa:
		errori.append("Decidi la razza (tentativo o umano).")
	if not retaggio_tirato:
		errori.append("Tira il retaggio.")
	if not mano_tirata:
		errori.append("Tira la mano primaria.")
	if retaggio_tirato:
		if xp_tot > builder.xp:
			errori.append("XP insufficienti per le scelte fatte.")
		if conti["denaro"] > builder.denaro:
			errori.append("Denaro insufficiente.")
	lbl_errori.text = "\n".join(errori)
	btn_armi.disabled = errori.size() > 0


func _alle_armi() -> void:
	pronto.emit(figura())
