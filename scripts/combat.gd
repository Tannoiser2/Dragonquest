class_name Combat
extends RefCounted
## Motore del combattimento tattico (Libro Primo, regole 11-24), separato dalla grafica.
## La UI chiama passo() finché attesa_giocatore è falso, poi esegui() con l'azione scelta.

signal cambiato

var griglia: HexGrid
var dadi: Dice
var figure: Array = []
var pulse := 0
var coda: Array = []
var attore: Fighter = null
var fase := "pronto"            # pronto, scelta_iniziativa, azione_giocatore, fine
var registro: Array = []
var vincitore := -1
var lato_iniziativa := 0
var regole_casa: Dictionary = {}


func _init(g: HexGrid, d: Dice) -> void:
	griglia = g
	dadi = d
	regole_casa = Rules.combattimento.get("house_rules", {})


func scrivi(testo: String) -> void:
	registro.append(testo)


# ============================================================ figure e posizioni

func figura_in(h: Vector2i) -> Fighter:
	for f in figure:
		if f.hex == h and not f.morto:
			return f
	return null


func occupato(h: Vector2i) -> bool:
	return figura_in(h) != null


func nemici_di(f: Fighter) -> Array:
	var out: Array = []
	for g in figure:
		if g.lato != f.lato and g.puo_agire():
			out.append(g)
	return out


func adiacenti_nemici(f: Fighter) -> Array:
	var out: Array = []
	for g in nemici_di(f):
		if HexGrid.distanza(f.hex, g.hex) == 1:
			out.append(g)
	return out


func ha_zona_mischia(f: Fighter) -> bool:
	## Melee Zone: figura cosciente, non stordita, con arma da mischia pronta [9].
	return f.in_piedi_e_attivo() and not f.prono


func in_zona_mischia_di(f: Fighter, h: Vector2i) -> bool:
	return ha_zona_mischia(f) and HexGrid.distanza(f.hex, h) == 1 and griglia.di_fronte(f.hex, f.facing, h)


func ingaggiati(a: Fighter, b: Fighter) -> bool:
	## Regola della casa: adiacenti e almeno uno ha l'altro nella propria Melee Zone.
	if a.lato == b.lato or not a.puo_agire() or not b.puo_agire():
		return false
	if HexGrid.distanza(a.hex, b.hex) != 1:
		return false
	return griglia.di_fronte(a.hex, a.facing, b.hex) or griglia.di_fronte(b.hex, b.facing, a.hex)


func e_ingaggiato(f: Fighter) -> bool:
	for g in figure:
		if ingaggiati(f, g):
			return true
	return false


func zona_nemica(f: Fighter, h: Vector2i) -> bool:
	for g in nemici_di(f):
		if in_zona_mischia_di(g, h):
			return true
	return false


# ============================================================ sequenza del Pulse [12]

func inizia() -> void:
	for f in figure:
		f.prepara_combattimento()
	scrivi("[b]Inizia il combattimento.[/b]")
	nuovo_pulse()


func capo(lato: int) -> Fighter:
	var migliore: Fighter = null
	for f in figure:
		if f.lato == lato and f.in_piedi_e_attivo() and not e_ingaggiato(f):
			if migliore == null or f.pc_attuale() > migliore.pc_attuale():
				migliore = f
	if migliore == null:
		for f in figure:
			if f.lato == lato and f.puo_agire():
				if migliore == null or f.pc_attuale() > migliore.pc_attuale():
					migliore = f
	return migliore


func nuovo_pulse() -> void:
	pulse += 1
	for f in figure:
		f.ha_agito = false
	scrivi("[color=#c9a227]--- Pulse %d ---[/color]" % pulse)
	var c0 := capo(0)
	var c1 := capo(1)
	var t0 := 0
	var t1 := 0
	while t0 == t1:
		t0 = dadi.d10() + (c0.pc_attuale() if c0 else 0)
		t1 = dadi.d10() + (c1.pc_attuale() if c1 else 0)
	lato_iniziativa = 0 if t0 > t1 else 1
	scrivi("Iniziativa: tu %d, nemici %d." % [t0, t1])
	if lato_iniziativa == 0:
		fase = "scelta_iniziativa"
	else:
		scrivi("I nemici vincono l'iniziativa e muovono per primi.")
		costruisci_coda(1)
		fase = "pronto"
	cambiato.emit()


func scegli_iniziativa(agisci_primo: bool) -> void:
	costruisci_coda(0 if agisci_primo else 1)
	scrivi("Il tuo gruppo agisce %s." % ("per primo" if agisci_primo else "dopo i nemici"))
	fase = "pronto"
	cambiato.emit()


func costruisci_coda(lato_primo: int) -> void:
	coda.clear()
	# 1) ingaggi, per Initiative Value decrescente; stordito per ultimo [12.3, 19]
	var impegnati: Array = []
	for f in figure:
		if f.puo_agire() and e_ingaggiato(f):
			impegnati.append(f)
	impegnati.sort_custom(func(a, b):
		var va: int = -100 if a.stordito else a.valore_iniziativa()
		var vb: int = -100 if b.stordito else b.valore_iniziativa()
		return va > vb)
	coda.append_array(impegnati)
	# 2) non ingaggiati, un lato alla volta; gli storditi in coda al proprio lato
	for lato in [lato_primo, 1 - lato_primo]:
		var liberi: Array = []
		var storditi: Array = []
		for f in figure:
			if f.lato == lato and f.puo_agire() and not impegnati.has(f):
				if f.stordito:
					storditi.append(f)
				else:
					liberi.append(f)
		coda.append_array(liberi)
		coda.append_array(storditi)


func passo() -> void:
	## Avanza fino al prossimo turno che richiede il giocatore (o esegue un turno IA).
	if fase == "fine" or fase == "scelta_iniziativa" or fase == "azione_giocatore":
		return
	while coda.size() > 0:
		var f: Fighter = coda.pop_front()
		if not f.puo_agire() or f.ha_agito:
			continue
		attore = f
		f.ha_agito = true
		f.postura = ""
		if f.stordito:
			tenta_ripresa(f)
			cambiato.emit()
			return
		if f.pass_obbligato > 0:
			f.pass_obbligato -= 1
			scrivi("%s è sbilanciato e perde l'azione." % f.nome)
			cambiato.emit()
			return
		if f.lato == 1:
			IA.turno(self, f)
			controlla_fine()
			cambiato.emit()
			return
		fase = "azione_giocatore"
		cambiato.emit()
		return
	fine_pulse()


func fine_azione_giocatore() -> void:
	fase = "pronto"
	controlla_fine()
	cambiato.emit()


func fine_pulse() -> void:
	for f in figure:
		if not f.puo_agire() and not f.svenuto:
			continue
		if f.morto:
			continue
		if f.emorragia_en > 0:
			f.resistenza -= f.emorragia_en
			scrivi("%s perde %d di Resistenza per l'emorragia." % [f.nome, f.emorragia_en])
			controlla_soglie(f)
		if f.emorragia_ft > 0 and not (f.emorragia_fino_svenimento and f.svenuto):
			if f.fatica > 0:
				f.fatica = max(0, f.fatica - f.emorragia_ft)
			else:
				f.resistenza -= f.emorragia_ft
				controlla_soglie(f)
			scrivi("%s sanguina (-%d)." % [f.nome, f.emorragia_ft])
	controlla_fine()
	if fase != "fine":
		nuovo_pulse()
	else:
		cambiato.emit()


func controlla_fine() -> void:
	var vivi := [0, 0]
	for f in figure:
		if f.puo_agire() and not f.non_si_rialza:
			vivi[f.lato] += 1
	if vivi[0] == 0 or vivi[1] == 0:
		fase = "fine"
		vincitore = 0 if vivi[1] == 0 else 1
		scrivi("[b]%s[/b]" % ("Vittoria! I nemici sono a terra." if vincitore == 0 else "Sconfitta. Il tuo gruppo è caduto."))


func tenta_ripresa(f: Fighter) -> void:
	## Recupero dallo stordimento: D100 <= 3 x WP + Fatigue attuale [19].
	var soglia := 3 * f.wp + f.fatica
	var t := dadi.d100()
	if t <= soglia:
		f.stordito = false
		scrivi("%s si riprende dallo stordimento (%d su %d)." % [f.nome, t, soglia])
	else:
		scrivi("%s resta stordito (%d su %d)." % [f.nome, t, soglia])


# ============================================================ azioni disponibili [15.7]

func azioni_disponibili(f: Fighter) -> Array:
	var az: Array = []
	if f.non_si_rialza:
		return [{"id": "attendi", "nome": "Attendi"}]
	if f.prono:
		return [{"id": "rialzati", "nome": "Rialzati"}, {"id": "attendi", "nome": "Attendi"}]
	var impegnato := e_ingaggiato(f)
	var mischia_ok := f.preparata == "mischia" and not f.braccio_primario_inutile
	if impegnato:
		if mischia_ok:
			az.append({"id": "attacco", "nome": "Attacco in mischia"})
		az.append({"id": "schiva", "nome": "Schiva (Evade)"})
		az.append({"id": "ritirata_dif", "nome": "Ritirata difensiva"})
		if mischia_ok:
			az.append({"id": "ritirata_off", "nome": "Ritirata offensiva"})
	else:
		az.append({"id": "muovi", "nome": "Muovi"})
		if mischia_ok:
			az.append({"id": "carica", "nome": "Carica"})
		az.append({"id": "schiva_muovi", "nome": "Muovi schivando"})
		az.append({"id": "indietreggia", "nome": "Indietreggia (Retreat)"})
		if f.preparata == "distanza" and f.carica_pronta:
			az.append({"id": "tira", "nome": "Tira"})
	if f.ha_arma_distanza() and f.preparata == "distanza" and not f.carica_pronta:
		az.append({"id": "carica_arma", "nome": "Carica l'arma da tiro"})
	if f.ha_arma_distanza():
		az.append({"id": "cambia_arma", "nome": "Prepara %s" % ("arma da mischia" if f.preparata == "distanza" else "arma da tiro")})
	if f.arma_caduta and not f.arma_rotta:
		az.append({"id": "raccogli", "nome": "Raccogli l'arma"})
	az.append({"id": "gira", "nome": "Girati"})
	az.append({"id": "attendi", "nome": "Attendi"})
	return az


func bersagli(f: Fighter, azione: String) -> Array:
	## Esagoni cliccabili per un'azione. Vuoto = l'azione non ha bersaglio (si esegue subito).
	match azione:
		"muovi":
			return raggiungibili(f, f.tmr()).keys()
		"schiva_muovi":
			return raggiungibili(f, max(1, f.tmr() / 2)).keys()
		"indietreggia":
			return raggiungibili_indietro(f, 2)
		"ritirata_dif", "ritirata_off":
			var out: Array = []
			for h in griglia.esagoni_retro(f.hex, f.facing):
				if griglia.libero(h) and not occupato(h):
					out.append(h)
			return out
		"attacco":
			var out2: Array = []
			for g in adiacenti_nemici(f):
				out2.append(g.hex)
			return out2
		"carica":
			var out3: Array = []
			for g in nemici_di(f):
				if destinazione_carica(f, g) != Vector2i(-999, -999):
					out3.append(g.hex)
			return out3
		"tira":
			var out4: Array = []
			for g in nemici_di(f):
				if puo_tirare(f, g):
					out4.append(g.hex)
			return out4
		"gira":
			var out5: Array = []
			for h in HexGrid.vicini(f.hex):
				out5.append(h)
			return out5
	return []


func raggiungibili(f: Fighter, passi: int) -> Dictionary:
	## Esagoni raggiungibili entro 'passi'; ci si ferma entrando in una Melee Zone nemica [14.1].
	var visti := {f.hex: 0}
	var frontiera := [f.hex]
	while frontiera.size() > 0:
		var h: Vector2i = frontiera.pop_front()
		var costo: int = visti[h]
		if costo >= passi:
			continue
		if h != f.hex and zona_nemica(f, h):
			continue
		for n in HexGrid.vicini(h):
			if visti.has(n) or not griglia.libero(n) or occupato(n):
				continue
			visti[n] = costo + 1
			frontiera.append(n)
	visti.erase(f.hex)
	return visti


func raggiungibili_indietro(f: Fighter, passi: int) -> Array:
	var out: Array = []
	var dirs := [f.facing + 2, f.facing + 3, f.facing + 4]
	var livello := [f.hex]
	for i in passi:
		var nuovo: Array = []
		for h in livello:
			for d in dirs:
				var n := HexGrid.vicino(h, d)
				if griglia.libero(n) and not occupato(n) and not out.has(n):
					out.append(n)
					nuovo.append(n)
		livello = nuovo
	return out


func destinazione_carica(f: Fighter, bersaglio: Fighter) -> Vector2i:
	var asta: bool = f.dati_arma("mischia").get("is_pole", false)
	var portata: int = f.tmr() if asta else max(1, f.tmr() / 2)
	var raggi := raggiungibili(f, portata)
	var migliore := Vector2i(-999, -999)
	var punteggio := 999
	for h in HexGrid.vicini(bersaglio.hex):
		if raggi.has(h):
			var p: int = raggi[h] * 2
			if griglia.di_fronte(bersaglio.hex, bersaglio.facing, h):
				p += 1
			if p < punteggio:
				punteggio = p
				migliore = h
	return migliore


func puo_tirare(f: Fighter, g: Fighter) -> bool:
	if f.preparata != "distanza" or not f.carica_pronta:
		return false
	var a := f.dati_arma("distanza")
	var gittata = a.get("range_hex", null)
	if gittata == null:
		return false
	var d := HexGrid.distanza(f.hex, g.hex)
	if d > int(gittata) or d < 1:
		return false
	return griglia.di_fronte(f.hex, f.facing, g.hex) and griglia.linea_libera(f.hex, g.hex)


# ============================================================ esecuzione

func esegui(f: Fighter, azione: String, h: Vector2i = Vector2i.ZERO) -> void:
	match azione:
		"muovi":
			sposta(f, h)
			f.postura = "movimento"
			scrivi("%s si muove." % f.nome)
		"schiva_muovi":
			sposta(f, h)
			f.postura = "schiva"
			scrivi("%s si muove schivando." % f.nome)
		"indietreggia":
			f.hex = h
			f.postura = "ritirata"
			scrivi("%s indietreggia." % f.nome)
		"schiva":
			f.postura = "schiva"
			scrivi("%s si mette sulla difensiva e schiva." % f.nome)
		"ritirata_dif":
			f.hex = h
			f.postura = "ritirata"
			scrivi("%s si ritira coprendosi%s." % [f.nome, " con lo scudo" if f.scudo_utilizzabile() else ""])
		"ritirata_off":
			var vittima := bersaglio_preferito(f, adiacenti_nemici(f).filter(func(g): return griglia.di_fronte(f.hex, f.facing, g.hex)))
			if vittima:
				attacca(f, vittima, "melee", {"ritirata": true})
			f.hex = h
			f.postura = "ritirata"
			scrivi("%s si ritira." % f.nome)
		"attacco":
			var g := figura_in(h)
			if g:
				f.facing = griglia.direzione_verso(f.hex, g.hex)
				attacca(f, g, "melee", {})
		"carica":
			var g2 := figura_in(h)
			if g2:
				var dest := destinazione_carica(f, g2)
				if dest != Vector2i(-999, -999):
					f.hex = dest
					f.facing = griglia.direzione_verso(f.hex, g2.hex)
					scrivi("%s carica %s!" % [f.nome, g2.nome])
					attacca(f, g2, "melee", {"carica": true})
		"tira":
			var g3 := figura_in(h)
			if g3:
				tira(f, g3)
		"carica_arma":
			var a := f.dati_arma("distanza")
			var serve := 2 if String(a.get("name", "")).contains("Crossbow") else 1
			f.passi_carica += 1
			if f.passi_carica >= serve:
				f.carica_pronta = true
				f.passi_carica = 0
				scrivi("%s carica %s." % [f.nome, a.get("name", "l'arma")])
			else:
				scrivi("%s sta caricando la balestra (%d/%d)." % [f.nome, f.passi_carica, serve])
		"cambia_arma":
			f.preparata = "distanza" if f.preparata == "mischia" else "mischia"
			scrivi("%s prepara %s." % [f.nome, f.dati_arma().get("name", "")])
		"raccogli":
			f.arma_caduta = false
			scrivi("%s raccoglie l'arma." % f.nome)
		"rialzati":
			f.prono = false
			scrivi("%s si rialza." % f.nome)
		"gira":
			f.facing = griglia.direzione_verso(f.hex, h)
			scrivi("%s si gira." % f.nome)
		"attendi":
			scrivi("%s attende." % f.nome)
	controlla_fine()


func sposta(f: Fighter, h: Vector2i) -> void:
	var da := f.hex
	f.hex = h
	var vicino := nemico_piu_vicino(f)
	if vicino and HexGrid.distanza(f.hex, vicino.hex) <= f.tmr() + 2:
		f.facing = griglia.direzione_verso(f.hex, vicino.hex)
	else:
		f.facing = griglia.direzione_verso(da, h)


func nemico_piu_vicino(f: Fighter) -> Fighter:
	var migliore: Fighter = null
	var dmin := 999
	for g in nemici_di(f):
		var d := HexGrid.distanza(f.hex, g.hex)
		if d < dmin:
			dmin = d
			migliore = g
	return migliore


func bersaglio_preferito(f: Fighter, lista: Array) -> Fighter:
	var migliore: Fighter = null
	for g in lista:
		if migliore == null or g.resistenza + g.fatica < migliore.resistenza + migliore.fatica:
			migliore = g
	return migliore


# ============================================================ risoluzione dell'attacco [17-19]

func arma_attacco(f: Fighter, tipo: String) -> Dictionary:
	## Arma usata; se l'arma è caduta, rotta o il braccio è inutile si combatte a mani nude [21].
	if tipo == "melee" and (f.arma_caduta or f.arma_rotta or f.braccio_primario_inutile):
		var base := 2 * f.ag_modificata() + maxi(0, f.ps - 15)
		return {"name": "mani nude", "base_chance": base, "damage_mod": -4 + max(0, (f.ps - 15) / 3), "class": null, "unarmed": true}
	return f.dati_arma("distanza" if tipo == "ranged" else "mischia")


func attacca(att: Fighter, dif: Fighter, tipo: String, ctx: Dictionary) -> bool:
	var arma := arma_attacco(att, tipo)
	var sc: int
	if arma.get("unarmed", false):
		sc = int(arma["base_chance"])
	else:
		sc = att.strike_chance("distanza" if tipo == "ranged" else "mischia")
	var da_dietro := not griglia.di_fronte(dif.hex, dif.facing, att.hex)
	var difesa := dif.difesa(da_dietro, tipo)
	var mods := modificatori(att, dif, tipo, ctx, da_dietro)
	var totale_mod := 0
	var spiegazione: Array = []
	for m in mods:
		totale_mod += int(m[0])
		spiegazione.append("%+d %s" % [m[0], m[1]])
	var msc := sc - difesa + totale_mod
	var tiro := dadi.d100()
	var testo := "%s attacca %s con %s: SC %d - difesa %d" % [att.nome, dif.nome, arma.get("name", "?"), sc, difesa]
	if spiegazione.size() > 0:
		testo += " (" + ", ".join(spiegazione) + ")"
	testo += " = %d. Tiro %d" % [msc, tiro]
	# 99 e 100: possibile rottura o caduta dell'arma [17.3]
	if tiro >= 99:
		scrivi(testo + ": mancato.")
		if not arma.get("unarmed", false):
			var salva := dadi.d100()
			if salva > 3 * att.md_modificata():
				if tiro == 99:
					att.arma_rotta = true
					scrivi("[color=#d9534f]%s spezza l'arma![/color]" % att.nome)
				else:
					att.arma_caduta = true
					scrivi("[color=#d9534f]%s lascia cadere l'arma![/color]" % att.nome)
		return false
	if tiro > msc:
		scrivi(testo + ": mancato.")
		# parata e riposte [17.4]
		if tipo == "melee" and dif.postura == "schiva" and tiro >= msc + 30 and not ctx.get("riposte", false) and dif.in_piedi_e_attivo():
			para(att, dif)
		return false
	scrivi(testo + ": [b]colpito![/b]")
	danno(att, dif, arma, tiro, msc)
	return true


func modificatori(att: Fighter, dif: Fighter, tipo: String, ctx: Dictionary, da_dietro: bool) -> Array:
	## Modificatori della Strike Chance [17.6], come coppie [valore, motivo].
	var m: Array = []
	if tipo == "melee":
		if dif.fatica <= 0:
			m.append([10, "bersaglio senza Fatica"])
		if dif.stordito:
			m.append([15, "bersaglio stordito"])
		if dif.prono:
			m.append([20, "bersaglio a terra"])
		if da_dietro:
			m.append([30, "da dietro"])
		if dif.postura == "schiva":
			m.append([-10, "schiva"])
			if dif.rank_arma() > 0:
				m.append([-4 * dif.rank_arma(), "Rank del difensore"])
		if att.fatica <= 0:
			m.append([-10, "attaccante senza Fatica"])
		if ctx.get("carica", false):
			if att.dati_arma("mischia").get("is_pole", false):
				m.append([20, "carica con arma ad asta"])
			else:
				m.append([-15, "carica"])
		if ctx.get("ritirata", false):
			m.append([-20, "attacco in ritirata"])
	elif tipo == "ranged":
		if dif.stordito:
			m.append([10, "bersaglio stordito"])
		if da_dietro:
			m.append([20, "da dietro"])
		var d := HexGrid.distanza(att.hex, dif.hex)
		var a := att.dati_arma("distanza")
		if a.get("group", "") == "Thrown":
			m.append([-3 * d, "distanza"])
		elif d > 5:
			m.append([-3 * int(ceil((d - 5) / 5.0)), "distanza"])
		if dif.postura == "movimento":
			m.append([-5, "bersaglio in movimento"])
		if dif.prono:
			m.append([-10, "bersaglio a terra"])
		if dif.postura == "schiva":
			m.append([-20, "schiva"])
		if griglia.riparati.has(dif.hex):
			m.append([-20, "bersaglio al riparo"])
	if ctx.get("secondaria", false):
		m.append([-20, "mano secondaria"])
	return m


func para(att: Fighter, dif: Fighter) -> void:
	var t := dadi.d10()
	var r := t + maxi(0, dif.rank_arma()) - maxi(0, att.rank_arma())
	if r <= 3:
		dif.pass_obbligato = 1
		scrivi("%s para il colpo (D10 %d, risultato %d) ma resta sbilanciato." % [dif.nome, t, r])
	elif r <= 7:
		att.arma_caduta = true
		att.resistenza -= 1
		scrivi("%s para e disarma %s (risultato %d)." % [dif.nome, att.nome, r])
		controlla_soglie(att)
	else:
		att.arma_caduta = true
		scrivi("%s para, disarma %s e risponde con una Riposte! (risultato %d)" % [dif.nome, att.nome, r])
		attacca(dif, att, "melee", {"riposte": true})


func danno(att: Fighter, dif: Fighter, arma: Dictionary, tiro: int, msc: int) -> void:
	## Danno [18]: il tiro per colpire decide se va a Fatica, a Resistenza o se c'è ferita grave.
	var mod := 0
	if arma.get("unarmed", false):
		mod = int(arma["damage_mod"])
	else:
		mod = att.modificatore_danno("distanza" if arma.get("group", "") in ["Missile", "Thrown"] else "mischia")
	var d10 := dadi.d10()
	var punti: int = max(1, d10 + mod)
	var riga := Rules.danno_speciale(msc)
	var grave_max = riga.get("grievous_max", null)
	var en_max := int(riga.get("endurance_max", 0))
	var effettivo := 0
	if grave_max != null and tiro <= int(grave_max):
		effettivo = punti
		dif.resistenza -= punti
		scrivi("Colpo devastante: %d danni diretti alla Resistenza." % punti)
		var classe = arma.get("class", null)
		if classe != null:
			var t := dadi.d100()
			var intervallo := Rules.intervallo_classe(String(classe))
			if intervallo.size() == 2 and t >= int(intervallo[0]) and t <= int(intervallo[1]):
				applica_ferita_grave(att, dif, t)
			else:
				scrivi("Nessuna ferita grave (D100 %d, Classe %s)." % [t, classe])
	elif tiro <= en_max:
		effettivo = punti
		dif.resistenza -= punti
		scrivi("Colpo preciso: %d danni diretti alla Resistenza, l'armatura non conta." % punti)
	else:
		var assorbiti: int = min(punti, dif.protezione())
		effettivo = punti - assorbiti
		if effettivo <= 0:
			scrivi("L'armatura assorbe tutti i %d danni." % punti)
		elif dif.fatica > 0:
			var persi: int = min(effettivo, dif.fatica)
			dif.fatica -= persi
			scrivi("%d danni, %d assorbiti dall'armatura: %s perde %d di Fatica." % [punti, assorbiti, dif.nome, persi])
			effettivo = persi
		else:
			dif.resistenza -= effettivo
			scrivi("%d danni, %d assorbiti: senza Fatica, %s perde %d di Resistenza." % [punti, assorbiti, dif.nome, effettivo])
	if effettivo > 0:
		if arma.get("class", "") == "A" and arma.get("group", "") in ["Missile", "Thrown"]:
			dif.conficcate += 1
			scrivi("L'arma resta conficcata: %s perde 3 di Agilità." % dif.nome)
		if effettivo * 3 > dif.en and not dif.stordito and dif.resistenza > 0:
			dif.stordito = true
			scrivi("[color=#e0a030]%s è stordito![/color]" % dif.nome)
	controlla_soglie(dif)


func controlla_soglie(f: Fighter) -> void:
	## A Resistenza 3 si sviene, a 0 si muore [19].
	if f.morto:
		return
	if f.resistenza <= 0:
		f.morto = true
		f.stordito = false
		scrivi("[color=#d9534f][b]%s muore.[/b][/color]" % f.nome)
	elif f.resistenza <= 3 and not f.svenuto:
		f.svenuto = true
		f.prono = true
		scrivi("[color=#d9534f]%s perde i sensi.[/color]" % f.nome)


func applica_ferita_grave(att: Fighter, dif: Fighter, tiro: int) -> void:
	var voce := Rules.ferita_grave(tiro)
	var e: Dictionary = voce.get("effects", {})
	scrivi("[color=#d9534f][b]Ferita grave (%d):[/b] %s[/color]" % [tiro, voce.get("text_it", "")])
	dif.ferite.append(voce.get("text_it", ""))
	var morte := false
	if e.has("subroll"):
		var s := dadi.d10()
		if s in e.get("death_on", []):
			morte = true
		scrivi("D10 aggiuntivo: %d." % s)
	if e.get("death", false) or morte:
		dif.resistenza = 0
	dif.resistenza -= int(e.get("en", 0))
	if e.get("prone", false):
		dif.prono = true
	if e.get("cannot_stand", false):
		dif.non_si_rialza = true
	if e.get("unconscious", false):
		dif.svenuto = true
	if e.get("stun_next_pulse", false):
		dif.stordito = true
	if e.get("forced_pass", 0) > 0:
		dif.pass_obbligato = int(e["forced_pass"])
	if e.get("drop", "") != "" or e.has("disable") or e.has("lose"):
		var parte := String(e.get("disable", e.get("lose", e.get("drop", ""))))
		if parte.begins_with("primary") or e.get("drop", "") == "primary":
			dif.arma_caduta = true
			if e.has("disable") or e.has("lose"):
				dif.braccio_primario_inutile = true
		elif parte.begins_with("secondary") and dif.scudo != "":
			dif.scudo = ""
	if e.get("attacker_disarmed", false):
		att.arma_caduta = true
	match String(e.get("bleed", "")):
		"EN":
			dif.emorragia_en += 1
		"FT":
			dif.emorragia_ft += 1
			if e.get("until", "") == "unconscious":
				dif.emorragia_fino_svenimento = true
	for k in ["tmr", "tmr_perm"]:
		dif.mod_tmr += int(e.get(k, 0))
	for k in ["ag_perm", "ag_temp"]:
		dif.mod_ag += int(e.get(k, 0))
	for k in ["md_perm", "md_temp"]:
		dif.mod_md += int(e.get(k, 0))
	dif.mod_pc += int(e.get("pc_perm", 0))
	dif.infezione += int(e.get("infection", 0))
	if e.get("wp_check_or_unconscious", false):
		if dadi.d100() > dif.wp:
			dif.svenuto = true
	# l'armatura perde 2 di protezione (oppure si spacca lo scudo) [18.3]
	if dif.scudo != "":
		dif.scudo = ""
		scrivi("Lo scudo di %s si spacca." % dif.nome)
	else:
		dif.protezione_persa += 2
	controlla_soglie(dif)


func tira(att: Fighter, bersaglio: Fighter) -> void:
	## Tiro a distanza [16.1]: si controllano in ordine le figure lungo la linea, fino al primo colpo.
	att.carica_pronta = false
	var a := att.dati_arma("distanza")
	scrivi("%s tira con %s su %s." % [att.nome, a.get("name", ""), bersaglio.nome])
	for h in griglia.linea(att.hex, bersaglio.hex):
		var g := figura_in(h)
		if g and g.puo_agire():
			scrivi("%s è sulla linea di tiro." % g.nome)
			if attacca(att, g, "ranged", {}):
				return
	attacca(att, bersaglio, "ranged", {})
