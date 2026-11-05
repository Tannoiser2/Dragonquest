extends Control
## Schermate del prototipo: creazione del personaggio e arena tattica.

const COL_SFONDO := Color(0.11, 0.09, 0.08)
const COL_PANNELLO := Color(0.18, 0.15, 0.12)
const COL_ORO := Color(0.85, 0.70, 0.35)
const COL_TESTO := Color(0.92, 0.88, 0.80)

var dadi := Dice.new()
var font_titolo: Font
var font_grassetto: Font

# --- creazione
var radice_creazione: Control

# --- arena
var radice_arena: Control
var combat: Combat
var vista: ArenaView
var lbl_scheda: RichTextLabel
var lbl_dettaglio: RichTextLabel
var pannello_dettaglio: PanelContainer
var figura_scheda: Fighter
var box_azioni: VBoxContainer
var log_arena: RichTextLabel
var lbl_sotto: Label
var timer_ia: Timer
var azione_corrente := ""
var scelta_magia := false
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


## Spezza un testo lungo in righe di circa `larghezza` caratteri (per i tooltip).
func a_capo(testo: String, larghezza: int) -> String:
	var righe: Array[String] = []
	var riga := ""
	for parola in testo.split(" ", false):
		if riga.length() + parola.length() + 1 > larghezza and riga != "":
			righe.append(riga)
			riga = parola
		else:
			riga = parola if riga == "" else riga + " " + parola
	if riga != "":
		righe.append(riga)
	return "\n".join(righe)


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
		(ctrl as OptionButton).fit_to_longest_item = false
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
	radice_creazione = Creazione.new(self, dadi)
	radice_creazione.pronto.connect(_alle_armi)
	add_child(radice_creazione)


func _personaggio_casuale() -> void:
	(radice_creazione as Creazione)._personaggio_casuale()


func _alle_armi(f: Fighter = null) -> void:
	eroe = f if f != null else (radice_creazione as Creazione).figura()
	radice_creazione.queue_free()
	radice_creazione = null
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
		CharacterBuilder.png(dadi, "Tobia", 0, "Halfling", ["MD", "AG", "EN", "PS", "WP", "MA"], "short_sword", 1, "Leather", "", -1, "sling", 2),
		CharacterBuilder.adept(dadi, "Ariella", 0, "Human", 36, {"S-2": 3, "G-3": 2, "S-12": 1}, "quarterstaff", 1, "Leather")]
	var nemici := [
		CharacterBuilder.png(dadi, "Capobanda", 1, "Human", ["PS", "MD", "EN", "AG", "WP", "MA"], "broadsword", 2, "Chainmail", "Small Round Shield", 1),
		CharacterBuilder.png(dadi, "Orco predone", 1, "Orc", ["PS", "EN", "MD", "AG", "WP", "MA"], "scimitar", 1, "Leather"),
		CharacterBuilder.png(dadi, "Orco lanciere", 1, "Orc", ["PS", "EN", "MD", "AG", "WP", "MA"], "spear", 1, "Leather"),
		CharacterBuilder.png(dadi, "Balestriere", 1, "Human", ["MD", "AG", "EN", "PS", "WP", "MA"], "dagger", 1, "Leather", "", -1, "crossbow", 1),
		CharacterBuilder.adept(dadi, "Stregone", 1, "Human", 42, {"S-2": 3, "S-3": 1}, "quarterstaff", 1, "Leather")]
	var squadra: Array = [eroe]
	squadra.append_array(compagni)
	var posti_g := [Vector2i(2, 4), Vector2i(2, 6), Vector2i(1, 5), Vector2i(1, 3)]
	var posti_n := [Vector2i(13, 5), Vector2i(12, 3), Vector2i(12, 7), Vector2i(15, 5), Vector2i(15, 7)]
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
	lbl_scheda.meta_hover_started.connect(_mostra_dettaglio)
	lbl_scheda.meta_clicked.connect(_mostra_dettaglio)
	var vd := VBoxContainer.new()
	lbl_dettaglio = RichTextLabel.new()
	lbl_dettaglio.bbcode_enabled = true
	lbl_dettaglio.scroll_active = true
	lbl_dettaglio.custom_minimum_size.y = 150
	vd.add_child(lbl_dettaglio)
	var chiudi := bottone("Chiudi descrizione", func(): pannello_dettaglio.visible = false)
	chiudi.size_flags_horizontal = Control.SIZE_SHRINK_END
	vd.add_child(chiudi)
	pannello_dettaglio = pannello(vd)
	pannello_dettaglio.visible = false
	lato.add_child(pannello_dettaglio)
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


## Descrizione italiana completa di un incantesimo della figura in scheda.
func _mostra_dettaglio(meta: Variant) -> void:
	if figura_scheda == null or figura_scheda.collegio <= 0:
		return
	var v: Dictionary = Rules.voce_magica(figura_scheda.collegio, String(meta))
	if v.is_empty():
		return
	var cod := String(meta)
	var t := "[b][color=#d8b25a]%s  %s[/color][/b]  Rank %d\n" % [cod, v.get("nome", v["name"]), figura_scheda.rank_incantesimo(cod)]
	var dati: Array[String] = ["CC %d" % figura_scheda.cast_chance(cod), "Fatica %d" % figura_scheda.costo_fatica(cod)]
	if v.get("portata_it"):
		dati.append("Portata: " + String(v["portata_it"]))
	if v.get("durata_it"):
		dati.append("Durata: " + String(v["durata_it"]))
	if v.get("resistenza_it"):
		dati.append("Resistenza: " + String(v["resistenza_it"]))
	t += "[color=#bdb6a8]" + "   ".join(dati) + "[/color]\n" + String(v.get("testo_it", ""))
	lbl_dettaglio.text = t
	lbl_dettaglio.scroll_to_line(0)
	pannello_dettaglio.visible = true


## "Incantesimo del Sonno incantato" -> "Sonno incantato"
func _nome_breve(nome: String) -> String:
	var re := RegEx.new()
	re.compile("^(Incantesimo|Rituale) (di |del |della |dello |dei |degli |delle |dell')?")
	return re.sub(nome, "")


func _mostra_scheda(f: Fighter) -> void:
	if f != figura_scheda and pannello_dettaglio != null:
		pannello_dettaglio.visible = false
	figura_scheda = f
	if f == null:
		lbl_scheda.text = ""
		return
	var a := f.dati_arma()
	var testo := "[font_size=20][b]%s[/b][/font_size]  %s  [color=#a89f8a](%s)[/color]\n" % [f.nome, CharacterBuilder.NOMI_RAZZE.get(f.razza, f.razza), "tuo" if f.lato == 0 else "nemico"]
	testo += "PS %d  MD %d  AG %d (mod. %d)  EN %d  WP %d  PC %d\n" % [f.ps, f.md, f.ag, f.ag_modificata(), f.en, f.wp, f.pc_attuale()]
	testo += "Fatica [color=#e6c34a]%d/%d[/color]   Resistenza [color=#e06050]%d/%d[/color]   TMR %d\n" % [f.fatica, f.ft, f.resistenza, f.en, f.tmr()]
	testo += "%s (Rank %s): Strike Chance %d, danno D10%+d\n" % [a.get("name", "?"), str(f.rank_arma()) if f.rank_arma() >= 0 else "nessuno", f.strike_chance(), f.modificatore_danno()]
	testo += "Difesa %d   Armatura %s (protezione %d)%s\n" % [f.difesa(false, "melee"), f.armatura, f.protezione(), ("   Scudo " + f.scudo) if f.scudo != "" else ""]
	if f.collegio > 0:
		var nomi: Array = []
		for codice in f.incantesimi_da_combattimento():
			nomi.append("[url=%s][color=#e8d3a0]%s[/color][/url] R%d" % [codice, _nome_breve(Magia.nome(f, codice)), f.rank_incantesimo(codice)])
		testo += "[color=#d8b25a]%s[/color] (MA %d, resistenza %d)%s\n" % [Rules.collegio(f.collegio)["nome"], f.ma_attuale(), f.wp_attuale(), "" if not f.ferro_freddo() else ", ferro freddo"]
		if nomi.size() > 0:
			testo += "Incantesimi: " + ", ".join(nomi) + "  [color=#a89f8a](passa sopra un nome per la descrizione)[/color]\n"
	if f.abilita.size() > 0:
		var ab: Array = []
		for id in f.abilita:
			ab.append("%s %d" % [Rules.abilita_scheda(id).get("nome", id), f.abilita[id]])
		testo += "Abilità: " + ", ".join(ab) + "\n"
	testo += "Stato: %s" % f.descrizione_stato()
	if f.ferite.size() > 0:
		testo += "\n[color=#d9534f]Ferite: %s[/color]" % "; ".join(f.ferite)
	lbl_scheda.text = testo


func _mostra_azioni() -> void:
	var f := combat.attore
	if scelta_magia:
		box_azioni.add_child(etichetta("%s: quale incantesimo prepari? (un Pulse per prepararlo, uno per lanciarlo)" % f.nome))
		for codice in Magia.incantesimi_pronti(f):
			var cod: String = codice
			var b0 := bottone("%s  (CC %d, Fatica %d)" % [Magia.nome(f, cod), f.cast_chance(cod), f.costo_fatica(cod)], func():
				scelta_magia = false
				combat.esegui(f, "prepara_magia", Vector2i.ZERO, cod)
				_chiudi_azione())
			b0.alignment = HORIZONTAL_ALIGNMENT_LEFT
			var voce: Dictionary = Rules.voce_magica(f.collegio, cod)
			if not voce.is_empty():
				b0.tooltip_text = a_capo(String(voce.get("testo_it", "")), 90)
			box_azioni.add_child(b0)
		box_azioni.add_child(bottone("Annulla", func(): scelta_magia = false; _aggiorna_arena()))
		return
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
	if id == "prepara_magia":
		scelta_magia = true
		_aggiorna_arena()
		return
	var lista := combat.bersagli(f, id)
	if id == "lancia_magia" and lista.size() == 1 and lista[0] == f.hex and String(Magia.spec(f, f.preparato).get("bersaglio", "")) in ["se_stesso", "frontali"]:
		combat.esegui(f, id, f.hex)
		_chiudi_azione()
		return
	if lista.is_empty() and not ["muovi", "schiva_muovi", "indietreggia", "ritirata_dif", "ritirata_off", "attacco", "carica", "tira", "gira", "lancia_magia", "sveglia", "scuoti", "ferma_emorragia"].has(id):
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
	for p in ["nome", "lato", "razza", "femmina", "mano", "ps", "md", "ag", "en", "ma", "wp", "ft", "pc", "arma_mischia", "rank_mischia", "arma_distanza", "rank_distanza", "scudo", "rank_scudo", "armatura",
			"collegio", "scuola_celeste", "rank_furtivita", "rank_equitazione", "aspetto", "bellezza"]:
		nuovo.set(p, eroe.get(p))
	nuovo.incantesimi = eroe.incantesimi.duplicate(true)
	nuovo.abilita = eroe.abilita.duplicate()
	eroe = nuovo
	eroe.prepara_combattimento()
	mostra_arena()


func _nuovo_personaggio() -> void:
	log_arena = null
	mostra_creazione()
