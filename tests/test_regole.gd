extends Node
## Test headless: godot --headless --path . res://tests/Test.tscn
## Verifica gli esempi del manuale e gioca partite automatiche IA contro IA.

var errori := 0


func verifica(cond: bool, msg: String) -> void:
	if cond:
		print("OK   ", msg)
	else:
		errori += 1
		printerr("ERRORE ", msg)


func _ready() -> void:
	# Esempio del manuale [17.6]: Rolf, Broadsword Rank 3, MD 15 -> SC 82
	var rolf := Fighter.new()
	rolf.md = 15
	rolf.arma_mischia = "broadsword"
	rolf.rank_mischia = 3
	rolf.scudo = ""
	verifica(rolf.strike_chance("mischia") == 82, "Strike Chance di Rolf = 82 (%d)" % rolf.strike_chance("mischia"))
	# White Mouse: AG 18, Main-Gauche Rank 2 come scudo -> difesa 22
	var topo := Fighter.new()
	topo.ag = 18
	topo.ps = 15
	topo.armatura = "Cloth / Heavy Furs"
	topo.arma_mischia = "rapier"
	topo.scudo = "Main-Gauche"
	topo.rank_scudo = 2
	var ag_mod := topo.ag_modificata()
	verifica(topo.difesa(false, "melee") == ag_mod + 4, "Difesa con Main-Gauche Rank 2 = AG mod. + 4 (%d)" % topo.difesa(false, "melee"))
	verifica(Rules.tmr_da_agilita(13) == 5 and Rules.tmr_da_agilita(22) == 7, "TMR da Agilità")
	verifica(Rules.fatigue_da_endurance(15) == 20, "Fatigue da Endurance 15 = 20")
	verifica(int(Rules.danno_speciale(80)["endurance_max"]) == 12, "Special Damage: SC 80 -> danno a EN fino a 12")
	verifica(String(Rules.ferita_grave(11)["text_it"]).contains("Aorta"), "Ferita grave 11 = aorta")
	var hg := HexGrid.new()
	verifica(HexGrid.distanza(Vector2i(0, 0), Vector2i(3, -1)) == 3, "Distanza esagonale")
	verifica(hg.di_fronte(Vector2i(0, 0), 0, Vector2i(1, 0)) and not hg.di_fronte(Vector2i(0, 0), 0, Vector2i(-1, 0)), "Fronte e retro")

	# Partite automatiche
	var vittorie := [0, 0]
	for partita in 30:
		var d := Dice.new(1000 + partita)
		var g := HexGrid.new()
		g.larghezza = 17
		g.altezza = 11
		var c := Combat.new(g, d)
		var squadre := [
			CharacterBuilder.png(d, "Eroe", 0, "Human", ["PS", "MD", "AG", "EN", "WP", "MA"], "broadsword", 2, "Leather", "Small Round Shield", 1),
			CharacterBuilder.png(d, "Brunilde", 0, "Human", ["PS", "EN", "MD", "AG", "WP", "MA"], "spear", 2, "Chainmail", "Large Round Shield", 1),
			CharacterBuilder.png(d, "Tobia", 0, "Halfling", ["MD", "AG", "EN", "PS", "WP", "MA"], "short_sword", 1, "Leather", "", -1, "sling", 2),
			CharacterBuilder.png(d, "Capobanda", 1, "Human", ["PS", "MD", "EN", "AG", "WP", "MA"], "broadsword", 2, "Chainmail", "Small Round Shield", 1),
			CharacterBuilder.png(d, "Orco", 1, "Orc", ["PS", "EN", "MD", "AG", "WP", "MA"], "scimitar", 1, "Leather"),
			CharacterBuilder.png(d, "Balestriere", 1, "Human", ["MD", "AG", "EN", "PS", "WP", "MA"], "dagger", 1, "Leather", "", -1, "crossbow", 1)]
		for i in squadre.size():
			var f: Fighter = squadre[i]
			f.hex = HexGrid.offset_ad_assiale(2 if f.lato == 0 else 14, 3 + 2 * (i % 3))
			f.facing = 0 if f.lato == 0 else 3
			if f.ha_arma_distanza():
				f.preparata = "distanza"
			c.figure.append(f)
		c.inizia()
		var sicurezza := 0
		while c.fase != "fine" and c.pulse < 300 and sicurezza < 20000:
			sicurezza += 1
			match c.fase:
				"scelta_iniziativa":
					c.scegli_iniziativa(true)
				"azione_giocatore":
					IA.turno(c, c.attore)
					c.fine_azione_giocatore()
				_:
					c.passo()
		verifica(c.fase == "fine", "Partita %d finita in %d Pulse (vince lato %d)" % [partita + 1, c.pulse, c.vincitore])
		if c.vincitore >= 0:
			vittorie[c.vincitore] += 1
	print("Vittorie giocatore/nemici: ", vittorie)
	print("ERRORI: ", errori)
	get_tree().quit(1 if errori > 0 else 0)
