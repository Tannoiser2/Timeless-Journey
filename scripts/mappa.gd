class_name Mappa
extends Control
## Il tabellone principale in 2D: strade, città, pedine, viaggiatori celebri, segnapunti.
## Si sposta trascinando (un dito o il mouse) e si ingrandisce con la rotella o pizzicando con due dita.

signal nodo_cliccato(nodo: String)
signal citta_cliccata(citta: String)

const W := 1080.0
const H := 1825.0

var s: Dictionary = {}
var evidenzia: Dictionary = {}     # nodo -> testo (scelte possibili sulla mappa)
var scelta_citta := ""
var percorsi := false        # mostra i percorsi dei Viaggiatori Celebri (Gazzetta)
var vg_sel := -1             # -1 tutti, altrimenti solo la colonna scelta
const COL_VG := [Color("c8892a"), Color("b3362b"), Color("2f6f9e")]
const ROMANI := ["I", "II", "III", "IV", "V"]
var zoom := 1.0
var centro := Vector2(W / 2, H / 2)
var _tocchi := {}
var _dist0 := 0.0
var _zoom0 := 1.0
var _trascina := false
var _mosso := 0.0
var _t := 0.0

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func _process(d: float) -> void:
	_t += d
	if not evidenzia.is_empty():
		queue_redraw()

func aggiorna(stato: Dictionary, ev: Dictionary) -> void:
	s = stato
	evidenzia = ev
	queue_redraw()

func _scala_base() -> float:
	return minf(size.x / W, size.y / H)

func _scala() -> float:
	return _scala_base() * zoom

func a_schermo(p: Vector2) -> Vector2:
	return size / 2 + (p - centro) * _scala()

func da_schermo(p: Vector2) -> Vector2:
	return centro + (p - size / 2) / _scala()

func _limita() -> void:
	zoom = clampf(zoom, 1.0, 4.0)
	var mezzo := size / 2 / _scala()
	centro.x = clampf(centro.x, minf(mezzo.x, W / 2), maxf(W - mezzo.x, W / 2))
	centro.y = clampf(centro.y, minf(mezzo.y, H / 2), maxf(H - mezzo.y, H / 2))

func _gui_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed:
			_tocchi[e.index] = e.position
		else:
			_tocchi.erase(e.index)
		if _tocchi.size() == 2:
			var k: Array = _tocchi.values()
			_dist0 = (k[0] - k[1]).length()
			_zoom0 = zoom
		accept_event()
		return
	if e is InputEventScreenDrag:
		_tocchi[e.index] = e.position
		if _tocchi.size() == 2:
			var k2: Array = _tocchi.values()
			var dd: float = (k2[0] - k2[1]).length()
			if _dist0 > 10:
				var prima := da_schermo((k2[0] + k2[1]) / 2)
				zoom = _zoom0 * dd / _dist0
				_limita()
				var dopo := da_schermo((k2[0] + k2[1]) / 2)
				centro += prima - dopo
				_limita()
			_mosso += 20
			queue_redraw()
		accept_event()
		return
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if e.pressed:
				var prima2 := da_schermo(e.position)
				zoom *= 1.12 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 1 / 1.12
				_limita()
				centro += prima2 - da_schermo(e.position)
				_limita()
				queue_redraw()
			accept_event()
			return
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_trascina = true
				_mosso = 0.0
			else:
				_trascina = false
				if _mosso < 12 and _tocchi.size() <= 1:
					_clic(e.position)
			accept_event()
			return
	if e is InputEventMouseMotion and _trascina and _tocchi.size() < 2:
		_mosso += e.relative.length()
		if _mosso > 6:
			centro -= e.relative / _scala()
			_limita()
			queue_redraw()
		accept_event()

func _clic(pos: Vector2) -> void:
	if s.is_empty():
		return
	var p := da_schermo(pos)
	var D := Dati.d()
	var migliore := ""
	var dmin := 60.0
	for n in D["nodi"]:
		var q := Vector2(D["nodi"][n][0], D["nodi"][n][1])
		var dd := q.distance_to(p)
		if dd < dmin:
			dmin = dd
			migliore = n
	# anche il nome della città (il nastro) apre la sua plancia
	if migliore == "":
		for c in D["citta"]:
			var q2 := Vector2(D["nodi"][c][0], D["nodi"][c][1])
			if Rect2(q2 + Vector2(-260, -60), Vector2(520, 120)).has_point(p):
				migliore = c
	if migliore == "":
		return
	if evidenzia.has(migliore):
		nodo_cliccato.emit(migliore)
	elif Dati.e_citta(migliore):
		citta_cliccata.emit(migliore)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("201812"))
	if s.is_empty():
		return
	var D := Dati.d()
	var sc := _scala()
	draw_set_transform(a_schermo(Vector2.ZERO), 0, Vector2(sc, sc))
	draw_texture_rect(Stile.tex("res://assets/img/plance/tabellone.webp"), Rect2(0, 0, W, H), false)
	# città selezionata
	if scelta_citta != "":
		var cp := Vector2(D["nodi"][scelta_citta][0], D["nodi"][scelta_citta][1])
		draw_arc(cp, 46, 0, TAU, 48, Color(0.95, 0.75, 0.3, 0.9), 5, true)
	# scelte possibili
	var pulsa := 0.5 + 0.5 * sin(_t * 5.0)
	for n in evidenzia:
		if not D["nodi"].has(n): continue
		var q := Vector2(D["nodi"][n][0], D["nodi"][n][1])
		draw_circle(q, 34 + 6 * pulsa, Color(1.0, 0.82, 0.25, 0.30 + 0.2 * pulsa))
		draw_arc(q, 36 + 6 * pulsa, 0, TAU, 48, Color(0.75, 0.45, 0.05, 0.95), 4, true)
	# pattuglie austriache (sulla stella accanto alla città)
	for c in D["citta"]:
		var pt: String = s["citta"][c]["pattuglia"]
		if pt != "":
			var st := Vector2(D["stelle"][c][0], D["stelle"][c][1]) + Vector2(0, 46)
			_pattuglia(st, pt)
	# tessere esplorazione rimaste in ogni città
	for c in D["citta"]:
		var n: int = s["citta"][c]["esplora"].size()
		var q3 := Vector2(D["nodi"][c][0], D["nodi"][c][1]) + Vector2(-40, 30)
		if n > 0:
			var tx := Stile.tex("res://assets/img/tessere/espl_%s_retro.webp" % c)
			for k in mini(n, 4):
				draw_texture_rect(tx, Rect2(q3 + Vector2(-26 + k * 3, -k * 3), Vector2(40, 40)), false)
			Stile.testo_centrato(self, Stile.grassetto(), str(n), q3 + Vector2(-6 + mini(n, 4) * 3, 8 - mini(n, 4) * 3), 26, Color.WHITE, Color(0, 0, 0, 0.9))
	# viaggiatori celebri
	var per_citta := {}
	for v in Motore.viaggiatori_pos(s):
		if not per_citta.has(v[1]): per_citta[v[1]] = []
		per_citta[v[1]].append(v[0])
	for c in per_citta:
		var base := Vector2(D["stelle"][c][0], D["stelle"][c][1])
		var k2 := 0
		for vid in per_citta[c]:
			var tx2 := _sagoma(vid)
			var hh := 118.0
			var ww := hh * 0.62
			if tx2:
				ww = hh * tx2.get_width() / tx2.get_height()
			var pos := base + Vector2(-ww / 2 + k2 * 46, -hh + 18 - k2 * 6)
			draw_rect(Rect2(pos + Vector2(4, 5), Vector2(ww, hh)), Color(0, 0, 0, 0.25))
			if tx2:
				draw_texture_rect(tx2, Rect2(pos, Vector2(ww, hh)), false)
			else:
				_cameo(pos, Vector2(ww, hh), vid)
			k2 += 1
	if percorsi:
		_percorsi()
	# pedine: giocatori e Automi
	var per_nodo := {}
	for p in s["giocatori"].size():
		var n2: String = s["giocatori"][p]["pos"]
		if not per_nodo.has(n2): per_nodo[n2] = []
		per_nodo[n2].append(Stile.colore(s["giocatori"][p]["colore"]))
	for au in s.get("automi", []):
		var n3: String = au["pos"]
		if not per_nodo.has(n3): per_nodo[n3] = []
		per_nodo[n3].append(Stile.colore(au["colore"]).darkened(0.1))
	for n4 in per_nodo:
		var q4 := Vector2(D["nodi"][n4][0], D["nodi"][n4][1])
		var lista: Array = per_nodo[n4]
		for i in lista.size():
			var off := Vector2((i - (lista.size() - 1) / 2.0) * 30, -8 + (i % 2) * 6)
			Stile.meeple(self, q4 + off, 62, lista[i])
	# segnapunti sul bordo
	_segnapunti()
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _sagoma(vid: String) -> Texture2D:
	return Stile.tex("res://assets/img/viaggiatori/sagoma_%s.webp" % vid)

## sagoma disegnata per i viaggiatori delle espansioni (senza grafica originale)
func _cameo(pos: Vector2, dim: Vector2, vid: String) -> void:
	var r := Rect2(pos, dim)
	draw_style_box(Stile.scatola(Color("efe2c4"), Color("8a6a3a"), 18, 3), r)
	var c := pos + Vector2(dim.x / 2, dim.y * 0.38)
	draw_circle(c, dim.x * 0.36, Color("d9c7a0"))
	draw_circle(c + Vector2(0, -dim.y * 0.08), dim.x * 0.14, Color("4a3a2a"))
	var spalle := PackedVector2Array([c + Vector2(-dim.x * 0.28, dim.y * 0.18), c + Vector2(-dim.x * 0.16, dim.y * 0.04),
		c + Vector2(dim.x * 0.16, dim.y * 0.04), c + Vector2(dim.x * 0.28, dim.y * 0.18)])
	draw_colored_polygon(spalle, Color("4a3a2a"))
	var nome: String = Dati.viaggiatore(vid)["nome"].split(" ")[-1]
	Stile.testo_centrato(self, Stile.titolo(), nome, pos + Vector2(dim.x / 2, dim.y * 0.82), 17, Stile.INCHIOSTRO)

func _pattuglia(c: Vector2, cat: String) -> void:
	var tx := Stile.tex("res://assets/img/espansioni/pattuglia_%s.webp" % cat)
	if tx:
		var h := 70.0
		var w := h * tx.get_width() / tx.get_height()
		draw_texture_rect(tx, Rect2(c - Vector2(w, h) / 2, Vector2(w, h)), false)
		return
	var pts := PackedVector2Array([c + Vector2(-20, -22), c + Vector2(20, -22), c + Vector2(20, 4), c + Vector2(0, 24), c + Vector2(-20, 4)])
	draw_colored_polygon(pts, Color("f4f0e6"))
	var ch := pts.duplicate()
	ch.append(pts[0])
	draw_polyline(ch, Color("2b2b2b"), 3, true)
	draw_rect(Rect2(c + Vector2(-20, -8), Vector2(40, 10)), Color("c8302a"))
	draw_circle(c + Vector2(0, 12), 7, Stile.COLORE_CAT[cat])

## posizione della casella p (0-99) del segnapunti stampato sul bordo
static func casella_pv(p: int) -> Vector2:
	var v := p % 100
	var passo_x := W / 21.0
	var passo_y := (H - 2 * 62.0) / 29.0
	if v == 0:
		return Vector2(passo_x / 2, 31)
	if v <= 20:
		return Vector2(passo_x * (v + 0.5), 31)
	if v <= 49:
		return Vector2(W - 31, 62 + passo_y * (v - 21 + 0.5))
	if v <= 70:
		return Vector2(W - passo_x * (v - 50 + 0.5), H - 31)
	return Vector2(31, H - 62 - passo_y * (v - 71 + 0.5))

func _segnapunti() -> void:
	var per := {}
	for p in s["giocatori"].size():
		var v: int = int(s["giocatori"][p]["pv"])
		var k := v % 100
		if not per.has(k): per[k] = []
		per[k].append(p)
	for k in per:
		var q := casella_pv(k)
		for i in per[k].size():
			var p2: int = per[k][i]
			var gg: Dictionary = s["giocatori"][p2]
			var tx := Stile.tex("res://assets/img/segnalini/pv_%s.webp" % gg["colore"])
			var r := Rect2(q + Vector2(-20 + i * 7, -20 - i * 7), Vector2(40, 40))
			draw_texture_rect(tx, r, false)
			if int(gg["pv"]) >= 100:
				Stile.testo_centrato(self, Stile.grassetto(), "+%d" % (int(gg["pv"]) / 100 * 100), r.get_center() + Vector2(0, 26), 16, Color.WHITE, Color(0, 0, 0, 0.9))

## percorso di ogni Viaggiatore Celebre nei cinque round lungo le strade del tabellone, con i numeri dei round
## in un riquadro accanto a ogni città di tappa
func _percorsi() -> void:
	var D := Dati.d()
	var r := int(s["round"])
	var spost := [Vector2(-7, -7), Vector2(0, 0), Vector2(7, 7)]
	# prima le linee (sotto), poi i numeri. Ogni viaggiatore ha la sua corsia: le tre linee corrono affiancate
	for col in 3:
		if vg_sel >= 0 and vg_sel != col:
			continue
		var citta: Array = D["gazzetta"][s["gazzetta"]]["citta"][col]
		var col_c: Color = COL_VG[col]
		var corsia := (col - 1) * (0.0 if vg_sel == col else 6.5)
		for i in 4:
			if citta[i] == citta[i + 1]:
				continue
			var nodi := Dati.strada(citta[i], citta[i + 1], 9)
			var grezzo := PackedVector2Array()
			for k in nodi.size() - 1:
				var t := Dati.tratto(nodi[k], nodi[k + 1])
				for j in t.size():
					if grezzo.size() and j == 0:
						continue
					grezzo.append(t[j])
			var pts := _affianca(grezzo, corsia)
			var a := 0.95 if i + 1 >= r else 0.3
			var w := 6.0 if vg_sel == col else 4.5
			draw_polyline(pts, Color(0.1, 0.06, 0.03, 0.55 * a), w + 3, true)
			draw_polyline(pts, Color(col_c, a), w, true)
			# freccia a metà del percorso
			var lung := 0.0
			for k2 in pts.size() - 1:
				lung += pts[k2].distance_to(pts[k2 + 1])
			var fatto := 0.0
			for k2 in pts.size() - 1:
				var seg := pts[k2].distance_to(pts[k2 + 1])
				if fatto + seg >= lung / 2 and seg > 0:
					var m := pts[k2].lerp(pts[k2 + 1], (lung / 2 - fatto) / seg)
					var dir := (pts[k2 + 1] - pts[k2]).normalized()
					var nrm := Vector2(-dir.y, dir.x)
					draw_colored_polygon(PackedVector2Array([m + dir * 15, m - dir * 7 + nrm * 10, m - dir * 7 - nrm * 10]), Color(0.1, 0.06, 0.03, 0.7 * a))
					draw_colored_polygon(PackedVector2Array([m + dir * 12, m - dir * 5 + nrm * 7.5, m - dir * 5 - nrm * 7.5]), Color(col_c, a))
					break
				fatto += seg
	# numeri dei round: per ogni città un riquadro con i round di ogni viaggiatore
	var tappe := {}
	for col in 3:
		if vg_sel >= 0 and vg_sel != col:
			continue
		var citta2: Array = D["gazzetta"][s["gazzetta"]]["citta"][col]
		for i in 5:
			var c: String = citta2[i]
			if not tappe.has(c): tappe[c] = []
			tappe[c].append([col, i])
	for c in tappe:
		var lista: Array = tappe[c]
		var base := Vector2(D["nodi"][c][0], D["nodi"][c][1]) + Vector2(0, 40)
		var rr := 15.0
		var larg := lista.size() * (rr * 2 + 4)
		var x0 := base.x - larg / 2 + rr + 2
		draw_rect(Rect2(Vector2(x0 - rr - 5, base.y - rr - 5), Vector2(larg + 6, rr * 2 + 10)), Color(0.12, 0.08, 0.05, 0.75))
		for k in lista.size():
			var col2: int = lista[k][0]
			var i2: int = lista[k][1]
			var q := Vector2(x0 + k * (rr * 2 + 4), base.y)
			var att := i2 + 1 == r
			var passato := i2 + 1 < r
			draw_circle(q, rr, Color(COL_VG[col2], 0.45 if passato else 1.0))
			if att:
				draw_arc(q, rr + 3, 0, TAU, 28, Color(1, 0.9, 0.5), 3, true)
			Stile.testo_centrato(self, Stile.titolo(), ROMANI[i2], q + Vector2(0, -1), 15 if i2 < 3 else 13, Color(1, 1, 1, 0.6 if passato else 1.0))

## sposta una linea di lato (a destra se d > 0) mantenendo la forma: corsie affiancate sulla stessa strada
func _affianca(pts: PackedVector2Array, d: float) -> PackedVector2Array:
	if absf(d) < 0.01 or pts.size() < 2:
		return pts
	var out := PackedVector2Array()
	for i in pts.size():
		var n := Vector2.ZERO
		if i > 0:
			var t1 := (pts[i] - pts[i - 1]).normalized()
			n += Vector2(-t1.y, t1.x)
		if i < pts.size() - 1:
			var t2 := (pts[i + 1] - pts[i]).normalized()
			n += Vector2(-t2.y, t2.x)
		if n.length() < 0.01:
			out.append(pts[i])
			continue
		n = n.normalized()
		out.append(pts[i] + n * d)
	return out
