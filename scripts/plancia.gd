class_name Plancia
extends Control
## La vista centrale: plancia di una città, Gazzetta del Viaggiatore, Mercato o Diari di Viaggio,
## con la grafica originale e i segnalini sopra. Le scelte possibili si toccano direttamente.

signal scelta(id: String)
signal ingrandisci(percorso: String)

var vista := "citta"         # citta | gazzetta | mercato | diari
var citta := "Torino"
var giocatore := 0           # di chi mostrare i diari
var s: Dictionary = {}
var opz: Array = []          # scelte della decisione in attesa (solo se tocca a chi guarda)
var _zone: Array = []        # [Rect2, id scelta o "", percorso immagine da ingrandire]
var _t := 0.0

const SINISTRA := ["Torino", "Firenze", "Roma", "Palermo"]

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func _process(d: float) -> void:
	_t += d
	if not opz.is_empty():
		queue_redraw()

func aggiorna(stato: Dictionary, scelte: Array) -> void:
	s = stato
	opz = scelte
	queue_redraw()

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		for z in _zone:
			if z[0].has_point(e.position):
				if z[1] != "":
					scelta.emit(z[1])
				elif z[2] != "":
					ingrandisci.emit(z[2])
				accept_event()
				return

func _opz_con(chiave: String, valore) -> Array:
	var out: Array = []
	for o in opz:
		if o.has(chiave) and o[chiave] == valore:
			out.append(o)
	return out

func _alone(r: Rect2) -> void:
	var a := 0.7 + 0.3 * sin(_t * 5.0)
	draw_rect(r.grow(5), Color(0.35, 0.15, 0.0, 0.8), false, 7)
	draw_rect(r.grow(4), Color(1.0, 0.82, 0.2, a), false, 4)
	draw_rect(r, Color(1.0, 0.85, 0.3, 0.12 + 0.1 * a))

## rettangolo dentro cui disegnare un'immagine di proporzioni date, centrato
func _adatta(area: Rect2, prop: float) -> Rect2:
	var w := area.size.x
	var h := w / prop
	if h > area.size.y:
		h = area.size.y
		w = h * prop
	return Rect2(area.position + (area.size - Vector2(w, h)) / 2, Vector2(w, h))

func _draw() -> void:
	_zone = []
	if s.is_empty():
		return
	match vista:
		"citta": _disegna_citta()
		"gazzetta": _disegna_gazzetta()
		"mercato": _disegna_mercato()
		"diari": _disegna_diari()

# ============================================================================ città
func _disegna_citta() -> void:
	var D := Dati.d()
	var c := citta
	var tx := Stile.tex("res://assets/img/citta/%s.webp" % c)
	var area := Rect2(Vector2(0, 0), Vector2(size.x, size.y - 92))
	var r := _adatta(area, 2481.0 / 1418.0)
	draw_texture_rect(tx, r, false)
	var sx := SINISTRA.has(c)
	var P := func(x: float, y: float) -> Vector2: return r.position + Vector2(x, y) * r.size
	var u := r.size.x / 1000.0
	var st: Dictionary = s["citta"][c]
	# favore
	var fav_c: Vector2 = P.call(0.575 if sx else 0.425, 0.262)
	var fav_r := Rect2(fav_c - Vector2(115, 62) * u, Vector2(230, 124) * u)
	draw_texture_rect(Stile.tex("res://assets/img/tessere/favore_%s.webp" % st["favore"]), fav_r, false)
	_zone.append([fav_r, "", "res://assets/img/tessere/favore_%s.webp" % st["favore"]])
	# abitanti: amico e lettere
	var ab_x := [0.505, 0.648] if sx else [0.352, 0.497]
	for lato in 2:
		var ac: Vector2 = P.call(ab_x[lato], 0.6)
		var ab_r := Rect2(ac - Vector2(62, 105) * u, Vector2(124, 210) * u)
		if int(st["amico"]) == lato:
			draw_rect(ab_r, Color(0.95, 0.78, 0.25, 0.9), false, 4 * u)
			Stile.testo_centrato(self, Stile.titolo(), "Amico", ab_r.position + Vector2(ab_r.size.x / 2, 14 * u), int(20 * u), Color.WHITE, Color(0.2, 0.12, 0.05, 1))
		for o in opz:
			if o["id"] == "ab:%d" % lato or (o.get("citta", "") == c and int(o.get("lato", -1)) == lato and not o.has("disc")):
				_alone(ab_r)
				_zone.append([ab_r, o["id"], ""])
				break
		# lettere
		var lc: Vector2 = P.call(ab_x[lato], 0.855)
		var lettere: Array = st["lettere"][lato]
		for i in lettere.size():
			var chi: int = int(lettere[i])
			var col := _colore_di(chi)
			var lr := Rect2(lc - Vector2(40, 26) * u + Vector2(i * 10, -i * 10) * u, Vector2(80, 52) * u)
			draw_texture_rect(Stile.tex("res://assets/img/segnalini/lettera_%s.webp" % col), lr, false)
	# caffè
	var cx := [0.092, 0.17, 0.265, 0.342] if sx else [0.66, 0.745, 0.835, 0.92]
	for d in 2:
		for k in 2:
			var cc: Vector2 = P.call(cx[d * 2 + k], 0.808)
			var chi2 = st["caffe"][d][k]
			if chi2 != null:
				var cr := Rect2(cc - Vector2(36, 32) * u, Vector2(72, 64) * u)
				draw_texture_rect(Stile.tex("res://assets/img/segnalini/caffe_%s.webp" % _colore_di(int(chi2))), cr, false)
		for o in opz:
			if o.get("citta", "") == c and o.has("disc") and int(o["disc"]) == d:
				var rr := Rect2(P.call(cx[d * 2], 0.45) - Vector2(40, 0) * u, Vector2((cx[d * 2 + 1] - cx[d * 2]) * 1000 + 80, 0.43 * r.size.y / u) * u)
				_alone(rr)
				_zone.append([rr, o["id"], ""])
				break
	# tessere esplorazione e ricompensa
	var ex: Vector2 = P.call(0.86 if sx else 0.14, 0.49)
	var er := Rect2(ex - Vector2(85, 85) * u, Vector2(170, 170) * u)
	var n: int = st["esplora"].size()
	if n > 0:
		for k2 in mini(n, 5):
			draw_texture_rect(Stile.tex("res://assets/img/tessere/espl_%s_retro.webp" % c), Rect2(er.position + Vector2(k2 * 6, -k2 * 6) * u, er.size * 0.8), false)
		Stile.testo_centrato(self, Stile.grassetto(), "%d" % n, er.position + Vector2(68, 60) * u + Vector2(mini(n, 5) * 6, -mini(n, 5) * 6) * u, int(46 * u), Color.WHITE, Color(0, 0, 0, 0.9))
	# Pattuglia
	if st["pattuglia"] != "":
		var pc: Vector2 = P.call(0.86 if sx else 0.14, 0.12)
		_scudo(pc, 36 * u, st["pattuglia"])
	# testo sotto la plancia: abitanti e ricompense
	var y := r.end.y + 6
	var fav: Array = D["favori"][st["favore"]]
	var ab: Array = D["abitanti"][c]
	var riga1 := "%s: %s     %s: %s" % [_maiuscola(ab[0]), Motore.testo_eff(fav[0]), _maiuscola(ab[1]), Motore.testo_eff(fav[1])]
	var riga2 := "Esplorazione: tessera oppure %s.   Caffè: %s" % [Motore.testo_eff(D["plance"][c]["esplora_alt"]), _testo_caffe(c)]
	_scrivi(riga1, Vector2(12, y + 22), 19)
	_scrivi(riga2, Vector2(12, y + 50), 19)
	var vp := Motore.viaggiatori_pos(s)
	var qui: Array = []
	for v in vp:
		if v[1] == c:
			qui.append(Dati.viaggiatore(v[0])["nome"])
	var chi_qui: Array = []
	for p in s["giocatori"].size():
		if s["giocatori"][p]["pos"] == c:
			chi_qui.append(s["giocatori"][p]["nome"])
	_scrivi("Qui: %s%s" % [", ".join(chi_qui) if chi_qui.size() else "nessun viaggiatore", ("   Viaggiatori celebri: " + ", ".join(qui)) if qui.size() else ""], Vector2(12, y + 78), 19)

func _maiuscola(t: String) -> String:
	return t.substr(0, 1).to_upper() + t.substr(1)

func _testo_caffe(c: String) -> String:
	var parti: Array = []
	for disc in Dati.d()["plance"][c]["caffe"]:
		var costo: Array = []
		for k in disc["costo"]:
			costo.append("%d %s" % [int(disc["costo"][k]), k])
		parti.append((" o " if disc.get("o", false) else " e ").join(costo) + " (%d/%d PV)" % [int(disc["pv"][0]), int(disc["pv"][1])])
	return "  |  ".join(parti)

func _scrivi(t: String, pos: Vector2, dim: int) -> void:
	draw_string(Stile.testo(), pos, t, HORIZONTAL_ALIGNMENT_LEFT, size.x - pos.x - 8, dim, Stile.CARTA)

func _colore_di(chi: int) -> String:
	if chi >= 100:
		return s["automi"][chi - 100]["colore"]
	return s["giocatori"][chi]["colore"]

func _scudo(c: Vector2, r: float, cat: String) -> void:
	var pts := PackedVector2Array([c + Vector2(-r, -r), c + Vector2(r, -r), c + Vector2(r, r * 0.2), c + Vector2(0, r * 1.2), c + Vector2(-r, r * 0.2)])
	draw_colored_polygon(pts, Color("f4f0e6"))
	draw_rect(Rect2(c + Vector2(-r, -r * 0.35), Vector2(2 * r, r * 0.5)), Color("c8302a"))
	draw_circle(c + Vector2(0, r * 0.55), r * 0.32, Stile.COLORE_CAT[cat])
	var ch := pts.duplicate()
	ch.append(pts[0])
	draw_polyline(ch, Color("2b2b2b"), 2, true)

# ============================================================================ Gazzetta
func _disegna_gazzetta() -> void:
	var D := Dati.d()
	var area := Rect2(Vector2.ZERO, Vector2(size.x * 0.62, size.y))
	var r := _adatta(area, 1000.0 / 1190.0)
	draw_texture_rect(Stile.tex("res://assets/img/plance/gazzetta_%s.webp" % s["gazzetta"]), r, false)
	var P := func(x: float, y: float) -> Vector2: return r.position + Vector2(x / 1000.0, y / 1190.0) * r.size
	var u := r.size.x / 1000.0
	var vp := Motore.viaggiatori_pos(s)
	var rr := int(s["round"]) - 1
	for col in 3:
		var vid: String = s["viaggiatori"][col]
		var cc: Vector2 = P.call([273, 553, 831][col], 290)
		var cr := Rect2(cc - Vector2(118, 176) * u, Vector2(236, 352) * u)
		var tx := Stile.tex("res://assets/img/viaggiatori/%s.webp" % vid)
		if tx:
			draw_texture_rect(tx, cr, false)
			_zone.append([cr, "", "res://assets/img/viaggiatori/%s.webp" % vid])
		else:
			_carta_testo(cr, Dati.viaggiatore(vid)["nome"], Dati.viaggiatore(vid)["testo"], u)
		for row in 5:
			var bc: Vector2 = P.call([197, 476, 755][col], [543, 657, 772, 886, 1000][row])
			var br := Rect2(bc - Vector2(42, 42) * u, Vector2(84, 84) * u)
			if row == rr:
				draw_rect(br.grow(3 * u), Color(0.95, 0.6, 0.1, 0.8), false, 3 * u)
			var sp = s["gaz"][col][row]
			if sp != null:
				var chi: int = int(sp["p"])
				var colname := _colore_di(chi)
				var t: String = sp["t"]
				var nome_t := t if t != "affinita" else "affinita0"
				draw_texture_rect(Stile.tex("res://assets/img/segnalini/esp_%s_%s.webp" % [colname, nome_t]), br, false)
			elif int(s["nn"]) < int(D["gazzetta_min"][row][col]):
				draw_rect(br, Color(0.2, 0.15, 0.1, 0.55))
		# scelte: incontro con il viaggiatore
		for o in opz:
			if o["id"] == "vg:%d" % col:
				_alone(cr)
				_zone.append([cr, o["id"], ""])
	# testi dei viaggiatori a destra
	var x0 := r.end.x + 16
	var y := 10.0
	for col in 3:
		var vid2: String = s["viaggiatori"][col]
		var v: Dictionary = Dati.viaggiatore(vid2)
		y = _paragrafo("%s, ora a %s" % [v["nome"], vp[col][1]], Vector2(x0, y), size.x - x0 - 10, 22, Stile.ORO_CHIARO, Stile.titolo())
		y = _paragrafo(v["testo"], Vector2(x0, y), size.x - x0 - 10, 18, Stile.CARTA) + 4
		var premio: Array = D["gazzetta"][s["gazzetta"]]["premi"][col]
		y = _paragrafo("Incontro: " + Motore.testo_eff(premio), Vector2(x0, y), size.x - x0 - 10, 18, Color("e8d6a8")) + 14
	y = _espansioni(x0, y)
	y = _paragrafo("Esperienze: Duello d’Onore (premio doppio, poi niente più incontri con lui), Una Notte da Ricordare (vale doppio nelle maggioranze), Perso nell’Ammirazione (a fine round perdi 1 PV per riavere il premio), Affinità Elettive (2 PV, 6 PV se entrambe con lo stesso viaggiatore). Maggioranze di fine partita per colonna: 5/3/1 PV.", Vector2(x0, y), size.x - x0 - 10, 16, Color("cbb892"))

func _espansioni(x0: float, y: float) -> float:
	var D := Dati.d()
	var w := size.x - x0 - 10
	if s["esp"]["napoleone"]:
		var k: String = s["battaglia"]["attuale"]
		var soldati := 0
		var chi: Array = []
		for gg in s["giocatori"]:
			soldati += int(gg["soldati"])
			if int(gg["soldati"]) > 0:
				chi.append("%s %d" % [gg["nome"], int(gg["soldati"])])
			if gg["pattuglie"].size():
				chi.append("%s: %d Pattugli%s" % [gg["nome"], gg["pattuglie"].size(), "a" if gg["pattuglie"].size() == 1 else "e"])
		if k != "":
			var b: Dictionary = D["battaglie"][k]
			y = _paragrafo("Battaglia %s: serve forza %d (Soldati Francesi ora %d). Premio per ogni Soldato: %s. Se vinta: %d e %d PV ai primi due." % [k, int(s["nn"]) + int(b["mod"]), soldati, Motore.testo_eff(b["premio"]), int(b["pv"][0]), int(b["pv"][1])], Vector2(x0, y), w, 17, Color("e8c48a"))
		if chi.size():
			y = _paragrafo(", ".join(chi), Vector2(x0, y), w, 17, Color("e8c48a"))
		y += 6
	if s["esp"]["diodati"]:
		var righe: Array = []
		for cat in ["V", "A", "I", "F"]:
			var m: Dictionary = D["mostri"][cat]
			var dove := "nella Villa"
			if int(s["villa"][cat]) >= 0:
				dove = "con " + s["giocatori"][int(s["villa"][cat])]["nome"]
			righe.append("%s (%s) %s" % [m["nome"], Dati.CATEGORIE[cat], dove])
		y = _paragrafo("Villa Diodati%s: %s." % [" (Risvegliata)" if int(s["round"]) >= 4 else "", "; ".join(righe)], Vector2(x0, y), w, 17, Color("d9a0a0"))
		y += 6
	if s["viaggiatori"].has("andersen"):
		var libere: Array = []
		for k2 in 4:
			if int(s["andersen"][k2]) < 0:
				libere.append(D["andersen"][k2]["nome"])
		y = _paragrafo("Riserva Andersen: %s." % (", ".join(libere) if libere.size() else "vuota"), Vector2(x0, y), w, 17, Color("b8d0e0"))
		y += 6
	return y

func _paragrafo(t: String, pos: Vector2, w: float, dim: int, col: Color, f: Font = null) -> float:
	if f == null:
		f = Stile.testo()
	var parole := t.split(" ")
	var riga := ""
	var y := pos.y
	for p in parole:
		var prova := (riga + " " + p).strip_edges()
		if f.get_string_size(prova, HORIZONTAL_ALIGNMENT_LEFT, -1, dim).x > w and riga != "":
			y += dim + 4
			draw_string(f, Vector2(pos.x, y), riga, HORIZONTAL_ALIGNMENT_LEFT, -1, dim, col)
			riga = p
		else:
			riga = prova
	if riga != "":
		y += dim + 4
		draw_string(f, Vector2(pos.x, y), riga, HORIZONTAL_ALIGNMENT_LEFT, -1, dim, col)
	return y + 4

func _carta_testo(r: Rect2, titolo: String, testo: String, u: float) -> void:
	draw_style_box(Stile.scatola(Color("efe2c4"), Color("8a6a3a"), 10, 3), r)
	Stile.testo_centrato(self, Stile.titolo(), titolo, r.position + Vector2(r.size.x / 2, 28 * u), int(24 * u), Stile.INCHIOSTRO)
	var f := Stile.testo()
	var dim := int(17 * u)
	var parole := testo.split(" ")
	var riga := ""
	var y := r.position.y + 60 * u
	for p in parole:
		var prova := (riga + " " + p).strip_edges()
		if f.get_string_size(prova, HORIZONTAL_ALIGNMENT_LEFT, -1, dim).x > r.size.x - 20 * u and riga != "":
			draw_string(f, Vector2(r.position.x + 10 * u, y), riga, HORIZONTAL_ALIGNMENT_LEFT, -1, dim, Stile.INCHIOSTRO)
			y += dim + 3
			riga = p
		else:
			riga = prova
	draw_string(f, Vector2(r.position.x + 10 * u, y), riga, HORIZONTAL_ALIGNMENT_LEFT, -1, dim, Stile.INCHIOSTRO)

# ============================================================================ Mercato
func _disegna_mercato() -> void:
	var h := size.y
	var mr := _adatta(Rect2(Vector2(0, 0), Vector2(size.x * 0.2, h)), 1182.0 / 2953.0)
	draw_texture_rect(Stile.tex("res://assets/img/plance/mercato.webp"), mr, false)
	var ch := (h - 40) / 3.0 - 10
	var cw := ch * 300.0 / 450.0
	var x0 := mr.end.x + 20
	for l in 3:
		var y := 10 + l * (ch + 12)
		var liv := str(l + 1)
		var lista: Array = []
		for k in s["mercato"][liv].size():
			lista.append(["m:%s:%d" % [liv, k], s["mercato"][liv][k], false])
		if s["mazzi"][liv].size():
			lista.append(["d:%s" % liv, s["mazzi"][liv][0], true])
		var x := x0
		for it in lista:
			var cr := Rect2(Vector2(x, y), Vector2(cw, ch))
			if it[2]:
				draw_rect(cr.grow(2), Color(0.1, 0.08, 0.05, 0.6))
				for k2 in 3:
					draw_rect(Rect2(cr.position + Vector2(6 - k2 * 3, -6 + k2 * 3), cr.size), Color(0.35, 0.28, 0.2), false, 2)
			var path: String = Motore.info(it[1])["img"]
			draw_texture_rect(Stile.tex(path), cr, false)
			if it[2]:
				Stile.testo_centrato(self, Stile.grassetto(), "mazzo: %d" % s["mazzi"][liv].size(), cr.position + Vector2(cw / 2, 12), 16, Stile.CARTA, Color(0, 0, 0, 0.9))
			var id_opz := ""
			for o in opz:
				if o["id"] == it[0]:
					id_opz = o["id"]
			if id_opz != "":
				_alone(cr)
			_zone.append([cr, id_opz, path])
			x += cw + 14
		draw_string(Stile.titolo(), Vector2(x + 6, y + ch / 2), ["Livello I: gratis", "Livello II: 2 monete", "Livello III: 5 monete"][l], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Stile.ORO_CHIARO)

# ============================================================================ Diari
func _disegna_diari() -> void:
	if giocatore >= s["giocatori"].size():
		giocatore = 0
	var gg: Dictionary = s["giocatori"][giocatore]
	var colw := size.x * 0.58
	var dh := (size.y - 60) / 2.0
	for di in 2:
		var d: Dictionary = gg["diari"][di]
		var r := _adatta(Rect2(Vector2(0, 40 + di * (dh + 10)), Vector2(colw, dh)), 2010.0 / 1065.0)
		draw_texture_rect(Stile.tex("res://assets/img/diari/%s.webp" % d["id"]), r, false)
		var P := func(x: float, y: float) -> Vector2: return r.position + Vector2(x, y) * r.size
		var u := r.size.x / 500.0
		var pos := [[0.61, 0.31], [0.74, 0.31], [0.87, 0.31], [0.61, 0.66], [0.74, 0.66], [0.87, 0.66], [0.164, 0.31], [0.366, 0.64]]
		for k in 8:
			var v = d["slot"][k]
			var c: Vector2 = P.call(pos[k][0], pos[k][1])
			var sr := Rect2(c - Vector2(28, 28) * u, Vector2(56, 56) * u)
			if v != null:
				var sv: String = v
				if sv.begins_with("t:"):
					draw_texture_rect(Stile.tex("res://assets/img/tessere/espl_%s.webp" % sv.substr(2)), Rect2(c - Vector2(36, 36) * u, Vector2(72, 72) * u), false)
				elif sv.begins_with("a:"):
					draw_texture_rect(Stile.tex("res://assets/img/tessere/amico_%s.webp" % sv.substr(2)), Rect2(c - Vector2(30, 50) * u, Vector2(60, 100) * u), false)
				else:
					draw_texture_rect(Stile.tex("res://assets/img/segnalini/idea_%s.webp" % sv.to_lower()), sr, false)
			for o in opz:
				if o.has("diario") and int(o["diario"]) == di and int(o["slot"]) == k:
					_alone(sr)
					_zone.append([sr, o["id"], ""])
					break
	# a destra: idee, tessere, amici, dipinti del giocatore mostrato
	var x0 := colw + 20
	var y := 20.0
	draw_string(Stile.titolo(), Vector2(x0, y + 26), "Diari di " + gg["nome"], HORIZONTAL_ALIGNMENT_LEFT, size.x - x0, 26, Stile.ORO_CHIARO)
	y += 46
	var xx := x0
	for ge in Dati.GENERI:
		draw_texture_rect(Stile.tex("res://assets/img/segnalini/idea_%s.webp" % ge.to_lower()), Rect2(xx, y, 44, 44), false)
		draw_string(Stile.grassetto(), Vector2(xx + 48, y + 32), str(int(gg["idee"][ge])), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Stile.CARTA)
		xx += 88
	y += 58
	draw_string(Stile.testo(), Vector2(x0, y + 20), "Tessere Esplorazione (%d):" % gg["tessere"].size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Stile.CARTA)
	y += 28
	xx = x0
	for t in gg["tessere"]:
		var tr := Rect2(xx, y, 64, 64)
		draw_texture_rect(Stile.tex("res://assets/img/tessere/espl_%s.webp" % t["id"]), tr, false)
		if t["usata"]:
			draw_rect(tr, Color(0, 0, 0, 0.45))
		if t.get("diario", false):
			draw_rect(tr, Color(0.9, 0.75, 0.3, 0.9), false, 3)
		_zone.append([tr, "", "res://assets/img/tessere/espl_%s.webp" % t["id"]])
		xx += 70
		if xx > size.x - 70:
			xx = x0
			y += 70
	y += 76
	draw_string(Stile.testo(), Vector2(x0, y + 20), "Amici:", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Stile.CARTA)
	y += 28
	xx = x0
	for a in gg["amici"]:
		draw_texture_rect(Stile.tex("res://assets/img/tessere/amico_%s_%d.webp" % [a["citta"], int(a.get("lato", 0))]), Rect2(xx, y, 50, 84), false)
		xx += 56
	if gg["dipinti"].size():
		y += 96
		draw_string(Stile.testo(), Vector2(x0, y + 20), "Dipinti di Le Brun:", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Stile.CARTA)
		y += 28
		xx = x0
		for t2 in gg["dipinti"]:
			draw_texture_rect(Stile.tex("res://assets/img/tessere/lebrun_%d.webp" % int(t2)), Rect2(xx, y, 64, 64), false)
			xx += 70
