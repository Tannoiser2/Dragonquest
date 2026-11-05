class_name ArenaView
extends Control
## Disegna la griglia esagonale, le figure (con il fronte) e gli esagoni evidenziati.

signal esagono_cliccato(h: Vector2i)
signal esagono_sotto(h: Vector2i)

const COL_PAVIMENTO := Color(0.27, 0.24, 0.20)
const COL_BORDO := Color(0.42, 0.37, 0.30)
const COL_MURO := Color(0.12, 0.11, 0.10)
const COL_RIPARO := Color(0.36, 0.30, 0.21)
const COL_EVIDENZA := Color(0.85, 0.70, 0.25, 0.35)
const COL_GIOCATORE := Color(0.25, 0.47, 0.75)
const COL_NEMICO := Color(0.72, 0.22, 0.20)
const COL_ATTORE := Color(1.0, 0.85, 0.35)

var combat: Combat
var evidenziati: Array = []
var sotto := Vector2i(-999, -999)
var origine := Vector2(60, 60)
var font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	font = load("res://assets/font/Alegreya-Bold.ttf")
	resized.connect(_centra)


func imposta(c: Combat) -> void:
	combat = c
	_centra()
	queue_redraw()


func _centra() -> void:
	if combat == null:
		return
	var g := combat.griglia
	var minimo := Vector2(INF, INF)
	var massimo := Vector2(-INF, -INF)
	for h in g.celle():
		var p := g.a_pixel(h)
		minimo = minimo.min(p)
		massimo = massimo.max(p)
	var dim := massimo - minimo
	origine = (size - dim) / 2.0 - minimo
	queue_redraw()


func _gui_input(evento: InputEvent) -> void:
	if combat == null:
		return
	if evento is InputEventMouseMotion:
		var mm := evento as InputEventMouseMotion
		var h := combat.griglia.da_pixel(mm.position - origine)
		if h != sotto:
			sotto = h
			esagono_sotto.emit(h)
			queue_redraw()
	elif evento is InputEventMouseButton:
		var mb := evento as InputEventMouseButton
		if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
			return
		var h2 := combat.griglia.da_pixel(mb.position - origine)
		if combat.griglia.dentro(h2):
			esagono_cliccato.emit(h2)


func _draw() -> void:
	if combat == null:
		return
	var g := combat.griglia
	for h in g.celle():
		var pts := _sposta(g.vertici(h))
		var col := COL_PAVIMENTO
		if g.muri.has(h):
			col = COL_MURO
		elif g.riparati.has(h):
			col = COL_RIPARO
		draw_colored_polygon(pts, col)
		if evidenziati.has(h):
			draw_colored_polygon(pts, COL_EVIDENZA)
		var chiuso := pts.duplicate()
		chiuso.append(pts[0])
		draw_polyline(chiuso, COL_BORDO, 1.0)
		if g.riparati.has(h):
			var c := g.a_pixel(h) + origine
			for i in 3:
				draw_circle(c + Vector2(-8 + 8 * i, 4 - 4 * (i % 2)), 4.0, Color(0.45, 0.38, 0.27))
	if g.dentro(sotto):
		var bordo := _sposta(g.vertici(sotto))
		bordo.append(bordo[0])
		draw_polyline(bordo, Color(1, 1, 1, 0.6), 2.0)
	for f in combat.figure:
		_disegna_figura(f)


func _sposta(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p + origine)
	return out


func _disegna_figura(f: Fighter) -> void:
	var g := combat.griglia
	var c := g.a_pixel(f.hex) + origine
	var r := g.lato * 0.62
	var base := COL_GIOCATORE if f.lato == 0 else COL_NEMICO
	if f.morto:
		base = Color(0.35, 0.33, 0.30)
	elif f.svenuto:
		base = base.darkened(0.5)
	# cuneo del fronte: copre i tre esagoni frontali
	if f.puo_agire():
		var ang := g.angolo_direzione(f.facing)
		var cuneo := PackedVector2Array([c])
		for i in 9:
			var a := ang - deg_to_rad(90) + deg_to_rad(180) * i / 8.0
			cuneo.append(c + Vector2(cos(a), sin(a)) * (r + 7))
		draw_colored_polygon(cuneo, Color(base.r, base.g, base.b, 0.35))
		var punta := c + Vector2(cos(ang), sin(ang)) * (r + 9)
		draw_line(c, punta, Color(1, 1, 1, 0.8), 2.0)
	draw_circle(c, r, base)
	if combat.attore == f and combat.fase != "fine":
		draw_arc(c, r + 3, 0, TAU, 32, COL_ATTORE, 3.0)
	else:
		draw_arc(c, r, 0, TAU, 32, Color(0, 0, 0, 0.6), 1.5)
	if f.prono and not f.morto:
		draw_line(c + Vector2(-r * 0.6, r * 0.6), c + Vector2(r * 0.6, -r * 0.6), Color(0, 0, 0, 0.7), 2.0)
	var iniziale := f.nome.substr(0, 2)
	var dim := font.get_string_size(iniziale, HORIZONTAL_ALIGNMENT_CENTER, -1, 15)
	draw_string(font, c + Vector2(-dim.x / 2, 5), iniziale, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	if f.morto:
		return
	# barre Fatica (giallo) e Resistenza (rosso) sotto la figura
	var w := r * 2
	var y := c.y + r + 4
	var x := c.x - r
	draw_rect(Rect2(x, y, w, 3), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(x, y, w * clampf(float(f.fatica) / max(1, f.ft), 0, 1), 3), Color(0.9, 0.75, 0.2))
	draw_rect(Rect2(x, y + 4, w, 3), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(x, y + 4, w * clampf(float(f.resistenza) / max(1, f.en), 0, 1), 3), Color(0.85, 0.2, 0.2))
	if f.stordito:
		draw_arc(c, r * 0.45, 0, TAU * 0.75, 16, COL_ATTORE, 2.0)
