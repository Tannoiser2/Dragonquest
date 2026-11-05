class_name IA
extends RefCounted
## Intelligenza dei nemici: regole semplici e leggibili, applicate nell'ordine.


static func furia(c: Combat, f: Fighter) -> void:
	## 44.8: in furia carica e attacca chi l'ha spaventato.
	var t := f.furia_contro
	if HexGrid.distanza(f.hex, t.hex) == 1 and f.preparata == "mischia":
		c.esegui(f, "attacco", t.hex)
	elif c.destinazione_carica(f, t) != Vector2i(-999, -999) and f.preparata == "mischia" and not c.e_ingaggiato(f):
		c.esegui(f, "carica", t.hex)
	else:
		var raggi: Dictionary = c.raggiungibili(f, f.tmr())
		var migliore := f.hex
		for h in raggi.keys():
			if HexGrid.distanza(h, t.hex) < HexGrid.distanza(migliore, t.hex):
				migliore = h
		if migliore != f.hex:
			c.esegui(f, "muovi", migliore)
		else:
			c.esegui(f, "attendi")


static func magia(c: Combat, f: Fighter, ids: Array) -> bool:
	## Gli Adept lanciano se possono: cura se feriti, poi attacco, poi potenziamenti.
	if ids.has("lancia_magia"):
		var possibili: Array = Magia.bersagli(c, f)
		var sp := Magia.spec(f, f.preparato)
		var migliore = null
		var punteggio := -999
		for h in possibili:
			var lista: Array = Magia.figure_colpite(c, f, h)
			var p := 0
			for g in lista:
				var amico: bool = g.lato == f.lato
				if ["danno", "sonno", "svenimento", "intralcio", "lentezza", "paura", "accecamento", "agonia", "prosciuga", "maledizione"].has(sp.get("tipo", "")):
					p += -3 if amico else 2
				else:
					p += 2 if amico else -3
			if p > punteggio:
				punteggio = p
				migliore = h
		if migliore != null and punteggio > 0:
			c.esegui(f, "lancia_magia", migliore)
		else:
			c.esegui(f, "annulla_magia")
		return true
	if not ids.has("prepara_magia"):
		return false
	var pronti: Array = Magia.incantesimi_pronti(f)
	var scelta := ""
	var ferito := f.resistenza < f.en * 0.6 or f.fatica < f.ft * 0.3
	for codice in pronti:
		var tipo := String(Magia.spec(f, codice).get("tipo", ""))
		if ferito and tipo == "cura":
			scelta = codice
			break
	if scelta == "":
		var miglior_cc := -999
		for codice in pronti:
			var tipo2 := String(Magia.spec(f, codice).get("tipo", ""))
			if ["danno", "sonno", "svenimento", "paura", "lentezza", "accecamento", "agonia", "intralcio"].has(tipo2):
				var cc := f.cast_chance(codice)
				if cc > miglior_cc:
					miglior_cc = cc
					scelta = codice
		if miglior_cc < 15:
			scelta = ""
	if scelta == "" or f.fatica < f.costo_fatica(scelta) + 1:
		return false
	# serve almeno un bersaglio possibile, altrimenti si avvicina
	f.preparato = scelta
	var ok := not Magia.bersagli(c, f).filter(func(h):
		var g := c.figura_in(h)
		return g != null and g.lato != f.lato).is_empty() or Magia.spec(f, scelta).get("bersaglio", "") == "se_stesso"
	f.preparato = ""
	if not ok:
		return false
	c.esegui(f, "prepara_magia", Vector2i.ZERO, scelta)
	return true


static func turno(c: Combat, f: Fighter) -> void:
	var az: Array = c.azioni_disponibili(f)
	var ids: Array = az.map(func(a): return a["id"])
	if ids.has("libera"):
		c.esegui(f, "libera")
		return
	if ids.has("sveglia"):
		c.esegui(f, "sveglia", c.bersagli(f, "sveglia")[0])
		return
	if ids.has("ferma_emorragia"):
		c.esegui(f, "ferma_emorragia", c.bersagli(f, "ferma_emorragia")[0])
		return
	if magia(c, f, ids):
		return
	if ids.has("rialzati"):
		c.esegui(f, "rialzati")
		return
	if ids.has("raccogli") and c.adiacenti_nemici(f).size() == 0:
		c.esegui(f, "raccogli")
		return
	# senza Fatica e con poca Resistenza: si ritira coprendosi
	if f.fatica <= 0 and f.resistenza <= f.en / 2 and ids.has("ritirata_dif"):
		var dietro: Array = c.bersagli(f, "ritirata_dif")
		if dietro.size() > 0:
			c.esegui(f, "ritirata_dif", dietro[0])
			return
	if ids.has("attacco"):
		var bersaglio := c.bersaglio_preferito(f, c.adiacenti_nemici(f))
		if bersaglio:
			c.esegui(f, "attacco", bersaglio.hex)
			return
	if ids.has("schiva") and not ids.has("attacco"):
		c.esegui(f, "schiva")
		return
	# arma da tiro: carica, poi tira se c'è un bersaglio
	if f.ha_arma_distanza() and f.preparata == "distanza":
		if ids.has("tira"):
			var possibili: Array = c.bersagli(f, "tira")
			if possibili.size() > 0:
				var lista: Array = possibili.map(func(h): return c.figura_in(h))
				c.esegui(f, "tira", c.bersaglio_preferito(f, lista).hex)
				return
		if ids.has("carica_arma"):
			c.esegui(f, "carica_arma")
			return
		var vicino := c.nemico_piu_vicino(f)
		if vicino and HexGrid.distanza(f.hex, vicino.hex) <= 2 and ids.has("cambia_arma"):
			c.esegui(f, "cambia_arma")
			return
		if vicino and not c.griglia.di_fronte(f.hex, f.facing, vicino.hex):
			c.esegui(f, "gira", HexGrid.vicino(f.hex, c.griglia.direzione_verso(f.hex, vicino.hex)))
			return
	if ids.has("carica"):
		var cariche: Array = c.bersagli(f, "carica")
		if cariche.size() > 0:
			var lista2: Array = cariche.map(func(h): return c.figura_in(h))
			c.esegui(f, "carica", c.bersaglio_preferito(f, lista2).hex)
			return
	if ids.has("muovi"):
		var obiettivo := c.nemico_piu_vicino(f)
		if obiettivo:
			var raggi: Dictionary = c.raggiungibili(f, f.tmr())
			var migliore := Vector2i(-999, -999)
			var dmin := HexGrid.distanza(f.hex, obiettivo.hex)
			for h in raggi.keys():
				var d := HexGrid.distanza(h, obiettivo.hex)
				if d < dmin:
					dmin = d
					migliore = h
			if migliore != Vector2i(-999, -999):
				c.esegui(f, "muovi", migliore)
				return
	c.esegui(f, "attendi")
