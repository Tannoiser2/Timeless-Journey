class_name SchedaGiocatore
extends Control
## Sul tavolo TV: la scheda di un giocatore (punti, monete, idee, lettere, caffè, esperienze,
## carte giocate nel round, Diari). Se p è oltre i giocatori, mostra gli Automi del solitario.

var s: Dictionary = {}
var p := 0
var chi := -1
var _t := 0.0

func aggiorna(stato: Dictionary, chi_decide: int) -> void:
	s = stato
	chi = chi_decide
	queue_redraw()

func _process(d: float) -> void:
	_t += d
	if p == chi:
		queue_redraw()

func _draw() -> void:
	if s.is_empty():
		return
	if p >= s["giocatori"].size():
		_automi()
		return
	var gg: Dictionary = s["giocatori"][p]
	var r := Rect2(Vector2.ZERO, size)
	var mio := p == chi
	draw_style_box(Stile.scatola(Color(0.95, 0.9, 0.78, 0.97), Color("b0401f") if mio else Stile.ORO, 10, 4 if mio else 2), r)
	if mio:
		var a := 0.5 + 0.5 * sin(_t * 4.0)
		draw_rect(r.grow(3), Color(1.0, 0.78, 0.2, a), false, 4)
	var col := Stile.colore(gg["colore"])
	var u := clampf(size.x / 330.0, 0.7, 1.3)
	Stile.meeple(self, Vector2(30, 40) * u, 56 * u, col)
	var nome: String = gg["nome"]
	draw_string(Stile.grassetto(), Vector2(60 * u, 30 * u), nome, HORIZONTAL_ALIGNMENT_LEFT, size.x - 150 * u, int(24 * u), Stile.INCHIOSTRO)
	var sotto: String = {"rete": "telefono", "ia": "computer", "umano": "qui"}.get(gg["tipo"], "")
	if p == int(s.get("primo", 0)) and not s["solo"]:
		sotto += ", primo"

	draw_string(Stile.testo(), Vector2(60 * u, 52 * u), sotto, HORIZONTAL_ALIGNMENT_LEFT, size.x - 66 * u, int(15 * u), Stile.INCHIOSTRO_DEBOLE)
	draw_string(Stile.grassetto(), Vector2(size.x - 100 * u, 38 * u), "%d PV" % int(gg["pv"]), HORIZONTAL_ALIGNMENT_RIGHT, 92 * u, int(30 * u), Color("7a2a14"))
	# risorse
	var y := 66 * u
	var x := 8 * u
	var ic := 26 * u
	var passo := (size.x - 16 * u) / 7.0
	var voci := [["res://assets/img/segnalini/moneta1.webp", int(gg["monete"])]]
	for ge in Dati.GENERI:
		voci.append(["res://assets/img/segnalini/idea_%s.webp" % ge.to_lower(), int(gg["idee"][ge])])
	voci.append(["res://assets/img/segnalini/lettera_%s.webp" % gg["colore"], int(gg["lettere"])])
	voci.append(["res://assets/img/segnalini/caffe_%s.webp" % gg["colore"], int(gg["caffe"])])
	for v in voci:
		draw_texture_rect(Stile.tex(v[0]), Rect2(Vector2(x, y), Vector2(ic, ic)), false)
		draw_string(Stile.grassetto(), Vector2(x + ic + 1, y + ic * 0.8), str(v[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(18 * u), Stile.INCHIOSTRO)
		x += passo
	y += ic + 6 * u
	# a destra le carte giocate nel round (in colonna), a sinistra i due Diari di Viaggio veri
	var area: Array = gg["area"]
	var spazio := size.y - y - 6
	var cw := clampf(size.x * 0.15, 30, 56)
	var ch := minf(cw * 1.5, (spazio - 4 * 3) / 5.0)
	cw = ch / 1.5
	var xc := size.x - cw - 6
	for i in area.size():
		var a: Dictionary = area[i]
		var path: String = "res://assets/img/carte/retro.webp" if a["giu"] else Motore.info(a["id"])["img"]
		draw_texture_rect(Stile.tex(path), Rect2(Vector2(xc, y + i * (ch + 3)), Vector2(cw, ch)), false)
	for i in range(area.size(), 5):
		draw_rect(Rect2(Vector2(xc, y + i * (ch + 3)), Vector2(cw, ch)), Color(0.45, 0.35, 0.25, 0.35), false, 1.5)
	var wd := xc - 14
	var hd := minf(wd * 1065.0 / 2010.0, (spazio - 6) / 2.0)
	wd = hd * 2010.0 / 1065.0
	for di in 2:
		var r2 := Rect2(Vector2(8, y + di * (hd + 6)), Vector2(wd, hd))
		_diario(gg, di, r2)
	# tra i Diari e le carte giocate: tessere, amici, esperienze, carte in mano
	var xs := 8 + wd + 8
	var righe := ["Tessere %d" % gg["tessere"].size(), "Amici %d" % gg["amici"].size(), "Esperienze %d" % gg["esp"].size(), "In mano %d" % gg["mano"].size()]
	if s["esp"]["napoleone"]:
		righe.append("Soldati %d" % int(gg["soldati"]))
	var dim := int(clampf(15 * u, 12, 19))
	if xc - xs >= Stile.testo().get_string_size("Esperienze 5", HORIZONTAL_ALIGNMENT_LEFT, -1, dim).x + 4:
		for i in righe.size():
			draw_string(Stile.testo(), Vector2(xs, y + 18 + i * (dim + 8)), righe[i], HORIZONTAL_ALIGNMENT_LEFT, xc - xs - 2, dim, Stile.INCHIOSTRO)
	elif y + 2 * hd + 6 + dim + 4 < size.y:
		draw_string(Stile.testo(), Vector2(8, y + 2 * hd + 6 + dim + 2), ", ".join(righe), HORIZONTAL_ALIGNMENT_LEFT, xc - 12, dim, Stile.INCHIOSTRO)

const POS_DIARIO := [[0.61, 0.31], [0.74, 0.31], [0.87, 0.31], [0.61, 0.66], [0.74, 0.66], [0.87, 0.66], [0.164, 0.31], [0.366, 0.64]]

func _diario(gg: Dictionary, di: int, r: Rect2) -> void:
	var d: Dictionary = gg["diari"][di]
	draw_texture_rect(Stile.tex("res://assets/img/diari/%s.webp" % d["id"]), r, false)
	var u := r.size.x / 500.0
	for k in 8:
		var v = d["slot"][k]
		if v == null:
			continue
		var c := r.position + Vector2(POS_DIARIO[k][0], POS_DIARIO[k][1]) * r.size
		var sv: String = v
		if sv.begins_with("t:"):
			draw_texture_rect(Stile.tex("res://assets/img/tessere/espl_%s.webp" % sv.substr(2)), Rect2(c - Vector2(36, 36) * u, Vector2(72, 72) * u), false)
		elif sv.begins_with("a:"):
			draw_texture_rect(Stile.tex("res://assets/img/tessere/amico_%s.webp" % sv.substr(2)), Rect2(c - Vector2(30, 50) * u, Vector2(60, 100) * u), false)
		else:
			draw_texture_rect(Stile.tex("res://assets/img/segnalini/idea_%s.webp" % sv.to_lower()), Rect2(c - Vector2(30, 30) * u, Vector2(60, 60) * u), false)

func _automi() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_style_box(Stile.scatola(Color(0.85, 0.82, 0.75, 0.95), Stile.ORO, 10, 2), r)
	var y := 30.0
	draw_string(Stile.titolo(), Vector2(12, y), "Automi", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Stile.INCHIOSTRO)
	for au in s["automi"]:
		y += 40
		Stile.meeple(self, Vector2(26, y - 6), 40, Stile.colore(au["colore"]))
		draw_string(Stile.grassetto(), Vector2(52, y), "%s a %s" % [au["nome"], au["pos"]], HORIZONTAL_ALIGNMENT_LEFT, size.x - 60, 19, Stile.INCHIOSTRO)
		y += 22
		draw_string(Stile.testo(), Vector2(52, y), "carte da giocare %d" % au["mazzo"].size(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 60, 16, Stile.INCHIOSTRO_DEBOLE)
	y += 34
	draw_string(Stile.testo(), Vector2(12, y), "Azioni fallite: %d/5" % s["fallite"].size(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 17, Stile.INCHIOSTRO)
