class_name HexGrid
extends RefCounted
## Griglia esagonale (punta in alto, coordinate assiali q,r). 1 esagono = 5 piedi [2.2].
## Direzioni 0..5: E, NE, NO, O, SO, SE. Il fronte di una figura sono i 3 esagoni
## nelle direzioni facing-1, facing, facing+1 (la Melee Zone [9]); gli altri 3 sono il retro.

const DIREZIONI := [Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)]
const SQRT3 := 1.7320508

var larghezza := 18
var altezza := 12
var lato := 30.0                     # raggio dell'esagono in pixel
var muri: Dictionary = {}            # Vector2i -> true (esagoni bloccati)
var riparati: Dictionary = {}        # Vector2i -> true (esagoni riparati, -20 a distanza)


# Le celle valide formano un rettangolo "sfalsato" (offset per riga) convertito in assiali.
func celle() -> Array:
	var out: Array = []
	for row in altezza:
		for col in larghezza:
			out.append(offset_ad_assiale(col, row))
	return out


static func offset_ad_assiale(col: int, row: int) -> Vector2i:
	return Vector2i(col - (row - (row & 1)) / 2, row)


static func assiale_ad_offset(h: Vector2i) -> Vector2i:
	return Vector2i(h.x + (h.y - (h.y & 1)) / 2, h.y)


func dentro(h: Vector2i) -> bool:
	var o := assiale_ad_offset(h)
	return o.x >= 0 and o.x < larghezza and o.y >= 0 and o.y < altezza


func libero(h: Vector2i) -> bool:
	return dentro(h) and not muri.has(h)


func a_pixel(h: Vector2i) -> Vector2:
	return Vector2(lato * SQRT3 * (h.x + h.y / 2.0), lato * 1.5 * h.y)


func da_pixel(p: Vector2) -> Vector2i:
	var q := (SQRT3 / 3.0 * p.x - 1.0 / 3.0 * p.y) / lato
	var r := (2.0 / 3.0 * p.y) / lato
	return arrotonda(q, r)


static func arrotonda(qf: float, rf: float) -> Vector2i:
	var sf := -qf - rf
	var q := roundi(qf)
	var r := roundi(rf)
	var s := roundi(sf)
	var dq: float = abs(q - qf)
	var dr: float = abs(r - rf)
	var ds: float = abs(s - sf)
	if dq > dr and dq > ds:
		q = -r - s
	elif dr > ds:
		r = -q - s
	return Vector2i(q, r)


static func distanza(a: Vector2i, b: Vector2i) -> int:
	var d := a - b
	return int((abs(d.x) + abs(d.y) + abs(d.x + d.y)) / 2)


static func vicino(h: Vector2i, dir: int) -> Vector2i:
	return h + DIREZIONI[posmod(dir, 6)]


static func vicini(h: Vector2i) -> Array:
	var out: Array = []
	for d in 6:
		out.append(h + DIREZIONI[d])
	return out


func vertici(h: Vector2i) -> PackedVector2Array:
	var c := a_pixel(h)
	var pts := PackedVector2Array()
	for i in 6:
		var ang := deg_to_rad(60.0 * i - 30.0)
		pts.append(c + Vector2(cos(ang), sin(ang)) * lato)
	return pts


# ------------------------------------------------------------ fronte e retro

func angolo_direzione(dir: int) -> float:
	var v := a_pixel(DIREZIONI[posmod(dir, 6)]) - a_pixel(Vector2i.ZERO)
	return v.angle()


func direzione_verso(da: Vector2i, a: Vector2i) -> int:
	## Direzione (0..5) che punta più da vicino da 'da' verso 'a'.
	if da == a:
		return 0
	var v := a_pixel(a) - a_pixel(da)
	var migliore := 0
	var diff_min := 999.0
	for d in 6:
		var diff: float = abs(angle_difference(v.angle(), angolo_direzione(d)))
		if diff < diff_min - 0.0001:
			diff_min = diff
			migliore = d
	return migliore


func di_fronte(posizione: Vector2i, facing: int, bersaglio: Vector2i) -> bool:
	## Vero se 'bersaglio' e nella zona frontale (Melee Zone se adiacente, Ranged Zone se lontano).
	if HexGrid.distanza(posizione, bersaglio) == 1:
		var d := direzione_verso(posizione, bersaglio)
		var diff := posmod(d - facing, 6)
		return diff == 0 or diff == 1 or diff == 5
	var v := a_pixel(bersaglio) - a_pixel(posizione)
	return abs(angle_difference(v.angle(), angolo_direzione(facing))) <= deg_to_rad(90.5)


func esagoni_retro(posizione: Vector2i, facing: int) -> Array:
	return [vicino(posizione, facing + 2), vicino(posizione, facing + 3), vicino(posizione, facing + 4)]


# ------------------------------------------------------------ linea di tiro

func linea(a: Vector2i, b: Vector2i) -> Array:
	## Esagoni attraversati dalla retta fra i centri (esclusi gli estremi) [9 Line of Fire].
	var n := HexGrid.distanza(a, b)
	var out: Array = []
	for i in range(1, n):
		var t := float(i) / n
		var qf := lerpf(a.x + 1e-6, b.x + 1e-6, t)
		var rf := lerpf(a.y + 1e-6, b.y + 1e-6, t)
		out.append(arrotonda(qf, rf))
	return out


func linea_libera(a: Vector2i, b: Vector2i) -> bool:
	for h in linea(a, b):
		if muri.has(h):
			return false
	return true
