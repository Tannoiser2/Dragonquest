extends Node
## Scatta screenshot dell'interfaccia: godot --path . res://tests/Screenshot.tscn -- CARTELLA
## (serve un display: in CI si usa xvfb-run).

var cartella := "user://screenshot"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		cartella = args[0]
	DirAccess.make_dir_recursive_absolute(cartella)
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await _attendi(20)
	main._personaggio_casuale()
	await _attendi(10)
	_scatta("1_creazione")
	var cr: Creazione = main.radice_creazione
	var idx := cr.num_collegi.find(42)
	cr.opt_collegio.select(idx)
	cr._cambia_collegio(idx)
	cr.schede.current_tab = 2
	await _attendi(10)
	_scatta("1b_magia")
	cr.schede.current_tab = 3
	await _attendi(10)
	_scatta("1c_abilita")
	cr.opt_collegio.select(0)
	cr._cambia_collegio(0)
	main._alle_armi()
	await _attendi(20)
	_scatta("2_arena_inizio")
	# fa giocare qualche turno: IA anche per il giocatore
	for i in 40:
		var c: Combat = main.combat
		if c.fase == "scelta_iniziativa":
			c.scegli_iniziativa(true)
		elif c.fase == "azione_giocatore":
			IA.turno(c, c.attore)
			c.fine_azione_giocatore()
		elif c.fase == "pronto":
			c.passo()
		await _attendi(2)
	await _attendi(10)
	_scatta("3_arena_mischia")
	get_tree().quit()


func _attendi(frame: int) -> void:
	for i in frame:
		await get_tree().process_frame


func _scatta(nome: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(cartella.path_join(nome + ".png"))
	print("Screenshot: ", nome)
