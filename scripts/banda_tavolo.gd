class_name BandaTavolo
extends Control
## Striscia in basso del tavolo TV: QR code per entrare, i tre Viaggiatori Celebri (si toccano per vedere
## percorso e premio), il Mercato e le ultime righe del diario della partita.

signal viaggiatore(col: int)
signal ingrandisci(percorso: String)

var s: Dictionary = {}
var qr: Texture2D = null
var codice := ""
var _zone: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func aggiorna(stato: Dictionary, qr_tex: Texture2D, cod: String) -> void:
	s = stato
	qr = qr_tex
	codice = cod
	queue_redraw()

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		for z in _zone:
			if z[0].has_point(e.position):
				if z[1] >= 0:
					viaggiatore.emit(z[1])
				else:
					ingrandisci.emit(z[2])
				accept_event()
				return

func _draw() -> void:
	_zone = []
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.13, 0.09, 0.07, 0.94))
	draw_line(Vector2(0, 1), Vector2(size.x, 1), Stile.ORO, 2)
	if s.is_empty():
		return
	var h := size.y - 12
	var x := 8.0
	# QR code
	if qr:
		var qr_r := Rect2(Vector2(x, 6), Vector2(h - 22, h - 22))
		draw_texture_rect(qr, qr_r, false)
		Stile.testo_centrato(self, Stile.grassetto(), codice, Vector2(x + (h - 22) / 2, h - 4), 20, Stile.ORO_CHIARO)
		x += h - 10
		draw_string(Stile.testo(), Vector2(x, 26), "Inquadra per", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Stile.CARTA)
		draw_string(Stile.testo(), Vector2(x, 46), "giocare dal", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Stile.CARTA)
		draw_string(Stile.testo(), Vector2(x, 66), "telefono", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Stile.CARTA)
		x += 100
	# Viaggiatori Celebri
	var D := Dati.d()
	var cw := h * 2.0 / 3.0
	var r := int(s["round"])
	for col in 3:
		var id: String = s["viaggiatori"][col]
		var cr := Rect2(Vector2(x, 6), Vector2(cw, h))
		draw_rect(cr.grow(3), Mappa.COL_VG[col])
		draw_texture_rect(Stile.tex("res://assets/img/viaggiatori/%s.webp" % id), cr, false)
		_zone.append([Rect2(cr.position, Vector2(cw + 150, h)), col, ""])
		var tx := x + cw + 10
		var nome: String = D["viaggiatori"][id]["nome"]
		draw_string(Stile.titolo(), Vector2(tx, 28), nome, HORIZONTAL_ALIGNMENT_LEFT, 140, 19, Mappa.COL_VG[col].lightened(0.35))
		var citta: Array = D["gazzetta"][s["gazzetta"]]["citta"][col]
		for i in 5:
			var att := i + 1 == r
			var c := Color("ffe3a0") if att else (Stile.CARTA if i + 1 > r else Color(0.6, 0.55, 0.5))
			draw_string(Stile.testo(), Vector2(tx, 50 + i * (h - 48) / 5.0), "%s %s" % [Mappa.ROMANI[i], citta[i]], HORIZONTAL_ALIGNMENT_LEFT, 140, 16 if not att else 18, c)
			var sp = s["gaz"][col][i]
			if sp != null:
				var chi: int = int(sp["p"])
				var colname: String = s["automi"][chi - 100]["colore"] if chi >= 100 else s["giocatori"][chi]["colore"]
				draw_circle(Vector2(tx + 136, 45 + i * (h - 48) / 5.0), 6, Stile.colore(colname))
		x += cw + 160
	# Mercato
	draw_line(Vector2(x - 6, 10), Vector2(x - 6, size.y - 10), Color(0.7, 0.55, 0.3, 0.5), 2)
	draw_string(Stile.titolo(), Vector2(x, 24), "Mercato", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Stile.ORO_CHIARO)
	var mh := h - 22
	var mw := mh * 2.0 / 3.0
	var xm := x
	for l in ["1", "2", "3"]:
		for id2 in s["mercato"][l]:
			var mr := Rect2(Vector2(xm, 30), Vector2(mw, mh))
			if mr.end.x > size.x - 330:
				break
			var path: String = Motore.info(id2)["img"]
			draw_texture_rect(Stile.tex(path), mr, false)
			_zone.append([mr, -1, path])
			xm += mw + 4
		xm += 8
	# diario della partita
	var xl := maxf(xm + 10, size.x - 320)
	draw_line(Vector2(xl - 8, 10), Vector2(xl - 8, size.y - 10), Color(0.7, 0.55, 0.3, 0.5), 2)
	var righe: Array = s["log"].slice(-6)
	var y := 22.0
	for t in righe:
		draw_string(Stile.testo(), Vector2(xl, y), t, HORIZONTAL_ALIGNMENT_LEFT, size.x - xl - 8, 15, Stile.CARTA)
		y += (size.y - 24) / 6.0
