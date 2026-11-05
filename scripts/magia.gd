class_name Magia
extends RefCounted
## Magia in combattimento (Libro Secondo, regole 27-33): preparazione, lancio, resistenza, effetti,
## contraccolpi e paura. Tutte le funzioni sono statiche e lavorano sul Combat passato.


static func spec(f: Fighter, codice: String) -> Dictionary:
	return Rules.spec_combattimento(f.collegio, codice)


static func voce(f: Fighter, codice: String) -> Dictionary:
	return Rules.voce_magica(f.collegio, codice)


static func nome(f: Fighter, codice: String) -> String:
	return String(voce(f, codice).get("nome", codice))


static func portata_esagoni(f: Fighter, codice: String) -> int:
	var sp := spec(f, codice)
	var r := maxi(0, f.rank_incantesimo(codice))
	var p = sp.get("portata", null)
	if sp.get("bersaglio", "") == "tocco":
		return 1
	if p == null:
		return int(sp.get("lunghezza", 1))
	return maxi(1, int(ceil((float(p[0]) + float(p[1]) * r) / 5.0)))


static func puo_lanciare(c: Combat, f: Fighter) -> String:
	## Restituisce "" se l'Adept può preparare un incantesimo, altrimenti il motivo.
	if f.collegio == 0:
		return "nessun Collegio"
	if f.muto:
		return "muto"
	if f.amnesia:
		return "amnesia"
	if f.ferro_freddo():
		return "ferro freddo addosso"
	if f.incantesimi_da_combattimento().is_empty():
		return "nessun incantesimo da combattimento"
	if c.figura_in(f.hex) != f:
		return "in Close combat"
	return ""


static func incantesimi_pronti(f: Fighter) -> Array:
	## Incantesimi da combattimento che l'Adept può pagare in Fatica.
	var out: Array = []
	for codice in f.incantesimi_da_combattimento():
		if f.fatica >= f.costo_fatica(codice):
			out.append(codice)
	return out


# ------------------------------------------------------------ bersagli

static func bersagli(c: Combat, f: Fighter) -> Array:
	var codice := f.preparato
	var sp := spec(f, codice)
	var portata := portata_esagoni(f, codice)
	var out: Array = []
	match String(sp.get("bersaglio", "singolo")):
		"se_stesso", "frontali":
			out.append(f.hex)
		"tocco":
			out.append(f.hex)
			for h in HexGrid.vicini(f.hex):
				if c.figura_in(h) != null:
					out.append(h)
		"alleato", "alleato_non_se", "alleati_multipli":
			for g in c.figure:
				if g.lato == f.lato and g.puo_agire() and HexGrid.distanza(f.hex, g.hex) <= portata:
					if sp["bersaglio"] == "alleato_non_se" and g == f:
						continue
					out.append(g.hex)
		"area":
			for h in c.griglia.celle():
				if c.griglia.libero(h) and HexGrid.distanza(f.hex, h) + int(sp.get("raggio", 0)) <= portata \
						and (h == f.hex or c.griglia.di_fronte(f.hex, f.facing, h)) and c.griglia.linea_libera(f.hex, h):
					out.append(h)
		"linea_tutti":
			for h in c.griglia.celle():
				if h != f.hex and HexGrid.distanza(f.hex, h) <= portata and c.griglia.di_fronte(f.hex, f.facing, h):
					out.append(h)
		_:
			for g in c.figure:
				if g != f and g.puo_agire() and HexGrid.distanza(f.hex, g.hex) <= portata \
						and c.griglia.di_fronte(f.hex, f.facing, g.hex) and c.griglia.linea_libera(f.hex, g.hex):
					out.append(g.hex)
	return out


static func figure_colpite(c: Combat, f: Fighter, h: Vector2i) -> Array:
	var sp := spec(f, f.preparato)
	var rank := maxi(0, f.rank_incantesimo(f.preparato))
	var out: Array = []
	match String(sp.get("bersaglio", "singolo")):
		"se_stesso":
			out.append(f)
		"frontali":
			var portata := portata_esagoni(f, f.preparato)
			for g in c.figure:
				if g != f and g.puo_agire() and HexGrid.distanza(f.hex, g.hex) <= portata and c.griglia.di_fronte(g.hex, g.facing, f.hex):
					out.append(g)
		"linea_primo":
			for p in c.griglia.linea(f.hex, h):
				var g := c.figura_in(p)
				if g and g.puo_agire():
					return [g]
			var t := c.figura_in(h)
			if t:
				out.append(t)
		"linea_tutti_fino":
			var quanti := maxi(1, rank)
			var percorso: Array = c.griglia.linea(f.hex, h)
			percorso.append(h)
			for p in percorso:
				var g2 := c.figura_in(p)
				if g2 and g2.puo_agire() and out.size() < quanti:
					out.append(g2)
		"linea_tutti":
			var lung := int(sp.get("lunghezza", 12))
			var v := c.griglia.a_pixel(h) - c.griglia.a_pixel(f.hex)
			var lontano := c.griglia.da_pixel(c.griglia.a_pixel(f.hex) + v.normalized() * c.griglia.lato * HexGrid.SQRT3 * lung)
			for p in c.griglia.linea(f.hex, lontano) + [lontano]:
				if c.griglia.muri.has(p) or not c.griglia.dentro(p):
					break
				var g3 := c.figura_in(p)
				if g3 and g3.puo_agire() and not out.has(g3):
					out.append(g3)
		"area":
			for g in c.figure:
				if g.puo_agire() and HexGrid.distanza(g.hex, h) <= int(sp.get("raggio", 0)):
					out.append(g)
		"multipli", "alleati_multipli":
			var q = sp.get("quanti", [1, 1])
			var q0 := int(q[0])
			var q1 := int(q[1])
			var n := maxi(1, rank) if (q0 == 1 and q1 == 1) else q0 + int(ceil(float(rank) / float(q1)))
			var primo := c.figura_in(h)
			if primo:
				out.append(primo)
			var portata2 := portata_esagoni(f, f.preparato)
			var altri: Array = []
			for g in c.figure:
				var stesso_lato: bool = g.lato == f.lato
				if g != primo and g.puo_agire() and HexGrid.distanza(f.hex, g.hex) <= portata2 \
						and (stesso_lato == (sp["bersaglio"] == "alleati_multipli")):
					altri.append(g)
			altri.sort_custom(func(a, b): return HexGrid.distanza(f.hex, a.hex) < HexGrid.distanza(f.hex, b.hex))
			for g in altri:
				if out.size() < n:
					out.append(g)
		_:
			var t2 := c.figura_in(h)
			if t2:
				out.append(t2)
	return out


# ------------------------------------------------------------ preparazione e lancio [27, 33]

static func prepara(c: Combat, f: Fighter, codice: String) -> void:
	f.preparato = codice
	c.scrivi("%s prepara %s (Cast Chance %d)." % [f.nome, nome(f, codice), f.cast_chance(codice)])


static func concentrazione(c: Combat, f: Fighter) -> void:
	## 29.5: se un Adept con un incantesimo pronto viene attaccato, D100 <= 4 x WP o perde la preparazione.
	if f.preparato == "" or f.morto:
		return
	var t := c.dadi.d100()
	if t > 4 * f.wp_attuale():
		c.scrivi("%s perde la concentrazione (%d su %d): l'incantesimo svanisce." % [f.nome, t, 4 * f.wp_attuale()])
		f.preparato = ""


static func lancia(c: Combat, f: Fighter, h: Vector2i) -> void:
	var codice := f.preparato
	f.preparato = ""
	var sp := spec(f, codice)
	var costo := f.costo_fatica(codice)
	if f.fatica < costo:
		c.scrivi("%s non ha abbastanza Fatica per lanciare." % f.nome)
		return
	f.fatica -= costo                                # la Fatica si spende comunque [27.3]
	var bersagli_lista := figure_colpite(c, f, h)
	var primo: Fighter = bersagli_lista[0] if bersagli_lista.size() > 0 else null
	var cc := f.cast_chance(codice, primo)
	# resistenza attiva: chi tra i bersagli ha scelto di resistere toglie la sua Magic Resistance [31.2]
	var resist: String = String(voce(f, codice).get("resist", "none"))
	if resist == "active_passive" or resist == "active":
		var mr_max := 0
		for g in bersagli_lista:
			if g.postura == "resiste" and g != f:
				mr_max = maxi(mr_max, g.magic_resistance(f))
		if mr_max > 0:
			cc -= mr_max
			c.scrivi("Resistenza attiva: -%d alla Cast Chance." % mr_max)
	var tiro := c.dadi.d100()
	var testo := "%s lancia %s: Cast Chance %d, tiro %d" % [f.nome, nome(f, codice), cc, tiro]
	if tiro <= cc:
		var riga := Rules.danno_speciale(cc)
		var molt := 1
		if riga.get("grievous_max") != null and tiro <= int(riga["grievous_max"]):
			molt = 3
		elif tiro <= int(riga.get("endurance_max", 0)):
			molt = 2
		c.scrivi(testo + (": [b]riuscito![/b]" if molt == 1 else ": [b]riuscito con effetto %s![/b]" % ("triplo" if molt == 3 else "doppio")))
		applica(c, f, codice, bersagli_lista, molt, 1.0)
	elif tiro > cc + 30:
		c.scrivi(testo + ": [color=#d9534f]contraccolpo![/color]")
		contraccolpo(c, f, codice, costo, bersagli_lista)
	else:
		c.scrivi(testo + ": fallito.")


static func resiste(c: Combat, lanciatore: Fighter, g: Fighter, codice: String) -> bool:
	var v := voce(lanciatore, codice)
	var resist := String(v.get("resist", "none"))
	if resist == "none" or g.lato == lanciatore.lato or g.stordito or not g.puo_agire():
		return false
	var mr := g.magic_resistance(lanciatore)
	var sp := spec(lanciatore, codice)
	if sp.has("resistenza_mod") and g.collegio != lanciatore.collegio:
		mr += int(sp["resistenza_mod"])
	var t := c.dadi.d100()
	if t <= mr:
		c.scrivi("%s resiste (%d su %d)." % [g.nome, t, mr])
		return true
	c.scrivi("%s non resiste (%d su %d)." % [g.nome, t, mr])
	return false


static func durata(c: Combat, f: Fighter, codice: String, molt: int) -> int:
	var sp := spec(f, codice)
	var r := maxi(1, f.rank_incantesimo(codice))
	var d = sp.get("durata", "combattimento")
	var p := 9999
	if typeof(d) == TYPE_DICTIONARY:
		if d.has("pulse"):
			p = int(d["pulse"][0]) + int(d["pulse"][1]) * maxi(0, f.rank_incantesimo(codice))
		elif d.has("dado"):
			p = int(d["dado"][0]) / 5 * maxi(1, c.dadi.d10() - int(d["dado"][1])) * r
	if molt > 1 and p < 9999 and not sp.has("danno") and not sp.has("cura"):
		p *= molt
	return c.pulse + maxi(1, p)


static func applica(c: Combat, f: Fighter, codice: String, lista: Array, molt: int, fattore: float) -> void:
	var sp := spec(f, codice)
	var rank := maxi(0, f.rank_incantesimo(codice))
	var tipo := String(sp.get("tipo", ""))
	if lista.is_empty():
		c.scrivi("L'incantesimo non colpisce nessuno.")
		return
	for g in lista:
		var resistito := resiste(c, f, g, codice)
		if resistito and not sp.get("dimezza_se_resiste", false):
			continue
		match tipo:
			"danno":
				var d = sp["danno"]
				var bonus := int(ceil(float(rank) / float(d[1]))) if int(d[1]) > 0 else 0
				var punti := maxi(1, c.dadi.d10() + int(d[0]) + bonus) * molt
				if resistito:
					punti = int(ceil(punti / 2.0))
				punti = maxi(1, int(round(punti * fattore)))
				danno_magico(c, g, punti, sp.get("armatura", false), sp.get("stordisce", false))
				g.infezione += int(sp.get("infezione", 0))
			"cura":
				var cu = sp["cura"]
				var q := (int(cu[0]) + int(ceil(float(rank) / float(cu[1])))) * molt
				var a_en := mini(q, g.en - g.resistenza)
				g.resistenza += maxi(0, a_en)
				var a_ft := mini(q - maxi(0, a_en), g.ft - g.fatica)
				g.fatica += maxi(0, a_ft)
				c.scrivi("%s recupera %d di Resistenza e %d di Fatica." % [g.nome, maxi(0, a_en), maxi(0, a_ft)])
			"sonno", "svenimento":
				g.addormentato = true
				g.stordito = false
				g.preparato = ""
				g.sveglia_impossibile = tipo == "svenimento" or rank >= 10
				g.effetti.append({"tipo": "sonno", "nome": "addormentato" if tipo == "sonno" else "privo di sensi", "fine": durata(c, f, codice, molt)})
				c.scrivi("[color=#9fb8e0]%s %s.[/color]" % [g.nome, "cade in un sonno incantato" if tipo == "sonno" else "perde i sensi"])
			"intralcio":
				g.intralciato = 2
				c.scrivi("%s è avvolto dalla ragnatela." % g.nome)
			"lentezza":
				g.effetti.append({"tipo": "lentezza", "nome": "rallentato", "fine": durata(c, f, codice, molt)})
				c.scrivi("%s è rallentato." % g.nome)
			"rapidita":
				g.effetti.append({"tipo": "rapidita", "nome": "accelerato", "fine": durata(c, f, codice, molt)})
				c.scrivi("%s è accelerato." % g.nome)
			"accecamento":
				g.effetti.append({"tipo": "accecamento", "nome": "accecato", "fine": durata(c, f, codice, molt)})
				g.preparato = ""
				c.scrivi("%s è accecato dal lampo." % g.nome)
			"arma":
				var s = sp.get("sc", [1, 1])
				g.effetti.append({"tipo": "arma", "nome": "arma incantata", "fine": durata(c, f, codice, molt),
					"sc": int(s[0]) + int(s[1]) * rank, "danno": int(ceil(float(rank) / float(sp.get("danno_arma", 3))))})
				c.scrivi("L'arma di %s è incantata." % g.nome)
			"protezione":
				if sp.get("solo_corazzati", false) and g.armatura == "Cloth / Heavy Furs":
					c.scrivi("%s non ha un'armatura su cui lanciarlo." % g.nome)
					continue
				var assorbe := 0
				if sp.has("assorbe"):
					assorbe = 1 + int(rank / int(sp["assorbe"][1]))
				elif rank >= 11:
					assorbe = 1
				g.effetti.append({"tipo": "protezione", "nome": "protetto", "fine": durata(c, f, codice, molt),
					"penalita": int(sp.get("penalita_per_rank", 2)) * maxi(1, rank) * molt, "assorbe": assorbe})
				c.scrivi("%s è protetto dalla magia." % g.nome)
			"scudo":
				g.effetti.append({"tipo": "scudo", "nome": "scudo di forza", "fine": durata(c, f, codice, molt),
					"penalita": int(sp.get("base_bonus", 5)) + int(sp.get("per_rank", 1)) * rank})
				c.scrivi("Uno scudo di forza circonda %s." % g.nome)
			"agonia":
				g.effetti.append({"tipo": "agonia", "nome": "in agonia", "fine": durata(c, f, codice, molt), "sc": int(sp.get("sc", -10))})
				g.preparato = ""
				c.scrivi("%s si contorce in agonia." % g.nome)
			"paura":
				paura(c, f, g)
			"prosciuga":
				var qn = sp.get("quantita", [1, 3])
				var n := (int(qn[0]) + int(ceil(float(rank) / float(qn[1])))) * molt
				var presi := 0
				if g.fatica >= n:
					g.fatica -= n
				else:
					g.resistenza -= n - g.fatica
					g.fatica = 0
					c.controlla_soglie(g)
				presi = n
				f.fatica = mini(f.ft, f.fatica + presi)
				c.scrivi("%s prosciuga %d punti di energia da %s." % [f.nome, presi, g.nome])
			"vigore":
				var piu := int(sp.get("per_rank", 1)) * maxi(1, rank) * molt
				g.ft += piu
				g.fatica += piu
				c.scrivi("%s guadagna %d di Fatica dalla forza della pietra." % [g.nome, piu])
			"maledizione":
				g.mod_pc += int(sp.get("pc", -5))
				c.scrivi("%s è maledetto: allucinazioni." % g.nome)


static func danno_magico(c: Combat, g: Fighter, punti: int, fisico: bool, stordisce: bool) -> void:
	## 18.4: l'energia magica toglie prima Fatica senza armatura; il danno fisico è assorbito dall'armatura.
	var eff := punti
	if fisico:
		eff = maxi(0, punti - g.protezione())
	if eff <= 0:
		c.scrivi("L'armatura di %s assorbe tutto." % g.nome)
		return
	if g.fatica > 0:
		var persi := mini(eff, g.fatica)
		g.fatica -= persi
		c.scrivi("%s subisce %d danni e perde %d di Fatica." % [g.nome, punti, persi])
		eff = persi
	else:
		g.resistenza -= eff
		c.scrivi("%s subisce %d danni alla Resistenza." % [g.nome, eff])
	if (stordisce or eff * 3 > g.en) and not g.stordito and g.resistenza > 0:
		g.stordito = true
		g.preparato = ""
		c.scrivi("[color=#e0a030]%s è stordito![/color]" % g.nome)
	c.controlla_soglie(g)


# ------------------------------------------------------------ contraccolpi [30] e paura [44.8]

static func contraccolpo(c: Combat, f: Fighter, codice: String, costo: int, lista: Array) -> void:
	var t := c.dadi.d100()
	var riga := Rules.da_tabella(Rules.magia_combat["backfire_30_1"], t)
	c.scrivi("[color=#d9534f]Contraccolpo (%d): %s[/color]" % [t, riga["testo"]])
	match String(riga["tipo"]):
		"fatica":
			perdi_fatica(c, f, costo * int(riga["x"]))
		"inverso":
			applica(c, f, codice, [f], 1, 1.0)
			if riga.has("fatica"):
				perdi_fatica(c, f, costo)
		"casuale":
			var portata := portata_esagoni(f, codice)
			var possibili: Array = c.figure.filter(func(g): return g.puo_agire() and HexGrid.distanza(f.hex, g.hex) <= portata)
			if possibili.size() > 0:
				var g = possibili[c.dadi.rng.randi_range(0, possibili.size() - 1)]
				c.scrivi("L'incantesimo colpisce %s." % g.nome)
				applica(c, f, codice, [g], 2 if riga.get("doppio", false) else 1, 1.0)
		"mezzo":
			applica(c, f, codice, lista, 1, 0.5)
		"cecita":
			f.effetti.append({"tipo": "accecamento", "nome": "cieco", "fine": 9999})
		"muto":
			f.muto = true
		"malattia", "emicrania", "senilita", "spasmi", "artrite":
			f.mod_wp += int(riga.get("wp", 0))
			f.mod_ma += int(riga.get("ma", 0))
			f.mod_md += int(riga.get("md", 0))
			f.mod_ag += int(riga.get("ag", 0))
			f.mod_cast += int(riga.get("cast", 0))
			if riga.get("en_meta", false):
				f.resistenza = int(f.resistenza / 2)
				c.controlla_soglie(f)
			if riga.get("ft_meta", false):
				f.fatica = int(f.fatica / 2)
		"amnesia":
			f.amnesia = true


static func perdi_fatica(c: Combat, f: Fighter, n: int) -> void:
	## 30.5: la Fatica che manca si toglie dalla Resistenza; stordimento se oltre 1/3 della Resistenza.
	var da_en := maxi(0, n - f.fatica)
	f.fatica = maxi(0, f.fatica - n)
	if da_en > 0:
		f.resistenza -= da_en
		c.scrivi("%s perde %d di Resistenza per lo sforzo." % [f.nome, da_en])
	if n * 3 > f.en and not f.stordito:
		f.stordito = true
		c.scrivi("[color=#e0a030]%s è stordito dal contraccolpo.[/color]" % f.nome)
	c.controlla_soglie(f)


static func paura(c: Combat, f: Fighter, g: Fighter) -> void:
	var t := c.dadi.d100()
	var riga := Rules.da_tabella(Rules.magia_combat["paura_44_8"], t)
	c.scrivi("[color=#c79be0]Paura (%d): %s %s[/color]" % [t, g.nome, String(riga["testo"]).to_lower()])
	match String(riga["tipo"]):
		"furia":
			g.furia_contro = f
		"fuga":
			g.in_fuga = maxi(2, c.dadi.d10())
			g.fuga_da = f
			g.preparato = ""
		"paralisi", "catatonia":
			g.stordito = true
			g.preparato = ""
		"isteria":
			g.isterico = true
			g.preparato = ""
		"svenimento":
			g.addormentato = true
			g.sveglia_impossibile = true
			g.effetti.append({"tipo": "sonno", "nome": "svenuto", "fine": 9999})
		"infarto":
			g.resistenza = 0
			c.controlla_soglie(g)


static func fuggi(c: Combat, f: Fighter) -> void:
	## Movimento di fuga: l'esagono raggiungibile più lontano da chi l'ha spaventato.
	f.in_fuga -= 1
	var da: Fighter = f.fuga_da
	var raggi := c.raggiungibili(f, f.tmr())
	var migliore := f.hex
	var dmax := HexGrid.distanza(f.hex, da.hex) if da else 0
	for h in raggi.keys():
		var d := HexGrid.distanza(h, da.hex) if da else 0
		if d > dmax:
			dmax = d
			migliore = h
	if migliore != f.hex:
		c.sposta(f, migliore)
		if da:
			f.facing = c.griglia.direzione_verso(da.hex, f.hex)
	c.scrivi("%s fugge in preda al terrore." % f.nome)
	if f.in_fuga <= 0:
		f.fuga_da = null
		c.scrivi("%s smette di fuggire." % f.nome)


static func aggiorna_effetti(c: Combat) -> void:
	for f in c.figure:
		var rimasti: Array = []
		for e in f.effetti:
			if int(e["fine"]) < c.pulse:
				c.scrivi("Finisce l'effetto su %s: %s." % [f.nome, e.get("nome", e["tipo"])])
				if e["tipo"] == "sonno":
					f.addormentato = false
					f.sveglia_impossibile = false
			else:
				rimasti.append(e)
		f.effetti = rimasti
		f.salta_pulse = not f.effetto("lentezza").is_empty() and (c.pulse % 2 == 0)
