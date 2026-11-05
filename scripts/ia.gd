class_name IA
extends RefCounted
## Intelligenza dei nemici: regole semplici e leggibili, applicate nell'ordine.


static func turno(c: Combat, f: Fighter) -> void:
	var az: Array = c.azioni_disponibili(f)
	var ids: Array = az.map(func(a): return a["id"])
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
