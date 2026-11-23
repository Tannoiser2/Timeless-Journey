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
	var sotto := {"rete": "telefono", "ia": "computer", "umano": "qui"}.get(gg["tipo"], "")
	if p == int(s.get("primo", 0)) and not s["solo"]:
		sotto += ", primo giocatore"
	draw_string(Stile.testo(), Vector2(60 * u, 52 * u), sotto, HORIZONTAL_ALIGNMENT_LEFT, size.x - 150 * u, int(16 * u), Stile.INCHIOSTRO_DEBOLE)
	draw_string(Stile.grassetto(), Vector2(size.x - 100 * u, 38 * u), "%d PV" % int(gg["pv"]), HORIZONTAL_ALIGNMENT_RIGHT, 92 * u, int(30 * u), Color("7a2a14"))
	# risorse
	var y := 72 * u
	var x := 10 * u
	var ic := 30 * u
	var passo := (size.x - 20 * u) / 7.0
	var voci := [["res://assets/img/segnalini/moneta1.webp", int(gg["monete"])]]
	for ge in Dati.GENERI:
		voci.append(["res://assets/img/segnalini/idea_%s.webp" % ge.to_lower(), int(gg["idee"][ge])])
	voci.append(["res://assets/img/segnalini/lettera_%s.webp" % gg["colore"], int(gg["lettere"])])
	voci.append(["res://assets/img/segnalini/caffe_%s.webp" % gg["colore"], int(gg["caffe"])])
	for v in voci:
		draw_texture_rect(Stile.tex(v[0]), Rect2(Vector2(x, y), Vector2(ic, ic)), false)
		draw_string(Stile.grassetto(), Vector2(x + ic + 1, y + ic * 0.78), str(v[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(19 * u), Stile.INCHIOSTRO)
		x += passo
	y += ic + 8 * u
	# carte giocate nel round
	var area: Array = gg["area"]
	draw_string(Stile.testo(), Vector2(10 * u, y + 16 * u), "Giocate (%d/5), in mano %d" % [area.size(), gg["mano"].size()], HORIZONTAL_ALIGNMENT_LEFT, size.x - 20 * u, int(16 * u), Stile.INCHIOSTRO)
	y += 22 * u
	var ch := clampf(size.y - y - 70 * u, 40, 110 * u)
	var cw := ch * 2.0 / 3.0
	for i in area.size():
		var a: Dictionary = area[i]
		var path: String = "res://assets/img/carte/retro.webp" if a["giu"] else Motore.info(a["id"])["img"]
		var cr := Rect2(Vector2(10 * u + i * (cw + 4), y), Vector2(cw, ch))
		if cr.end.x > size.x - 4:
			break
		draw_texture_rect(Stile.tex(path), cr, false)
	y += ch + 6 * u
	# tessere, diari, esperienze
	var dd: Array = []
	for d in gg["diari"]:
		var k := 0
		for v2 in d["slot"]:
			if v2 != null: k += 1
		dd.append("%s %d/8" % [String(d["id"]).substr(2), k])
	var riga := "Tessere %d  Amici %d  Esperienze %d" % [gg["tessere"].size(), gg["amici"].size(), gg["esp"].size()]
	draw_string(Stile.testo(), Vector2(10 * u, y + 16 * u), riga, HORIZONTAL_ALIGNMENT_LEFT, size.x - 20 * u, int(16 * u), Stile.INCHIOSTRO)
	y += 20 * u
	if y + 16 * u < size.y:
		draw_string(Stile.testo(), Vector2(10 * u, y + 16 * u), "Diari: " + ", ".join(dd), HORIZONTAL_ALIGNMENT_LEFT, size.x - 20 * u, int(16 * u), Stile.INCHIOSTRO)
	y += 20 * u
	if s["esp"]["napoleone"] and y + 16 * u < size.y:
		draw_string(Stile.testo(), Vector2(10 * u, y + 16 * u), "Soldati %d  Pattuglie %d" % [int(gg["soldati"]), gg["pattuglie"].size()], HORIZONTAL_ALIGNMENT_LEFT, size.x - 20 * u, int(16 * u), Stile.INCHIOSTRO)

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
