class_name PannelloGiocatori
extends Control
## Riepilogo dei giocatori: colore, punti, monete, idee, lettere, caffè, esperienze, carte in mano.

signal giocatore_scelto(p: int)

var s: Dictionary = {}
var _righe: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func aggiorna(stato: Dictionary) -> void:
	s = stato
	queue_redraw()

func altezza_per(n: int) -> float:
	return 12 + n * 78.0

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		for i in _righe.size():
			if _righe[i].has_point(e.position):
				giocatore_scelto.emit(i)
				accept_event()
				return

func _draw() -> void:
	_righe = []
	if s.is_empty():
		return
	var chi := -1
	if not s["attesa"].is_empty():
		chi = int(s["attesa"]["chi"])
	var y := 6.0
	for p in s["giocatori"].size():
		var gg: Dictionary = s["giocatori"][p]
		var r := Rect2(4, y, size.x - 8, 72)
		_righe.append(r)
		var fondo := Color(0.96, 0.91, 0.8, 0.96) if p == chi else Color(0.9, 0.84, 0.72, 0.9)
		draw_style_box(Stile.scatola(fondo, Stile.ORO if p != chi else Color("b0401f"), 8, 3 if p == chi else 2), r)
		var col := Stile.colore(gg["colore"])
		Stile.meeple(self, r.position + Vector2(24, 38), 46, col)
		var nome: String = gg["nome"]
		if gg["tipo"] == "ia":
			nome += " (computer)"
		elif gg["tipo"] == "rete":
			nome += " (online)"
		draw_string(Stile.grassetto(), r.position + Vector2(50, 24), nome, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 150, 20, Stile.INCHIOSTRO)
		draw_string(Stile.grassetto(), r.position + Vector2(r.size.x - 92, 26), "%d PV" % int(gg["pv"]), HORIZONTAL_ALIGNMENT_RIGHT, 84, 24, Color("7a2a14"))
		var x := r.position.x + 50
		var yy := r.position.y + 34
		_icona("res://assets/img/segnalini/moneta1.webp", Vector2(x, yy), str(int(gg["monete"])))
		x += 50
		for ge in Dati.GENERI:
			_icona("res://assets/img/segnalini/idea_%s.webp" % ge.to_lower(), Vector2(x, yy), str(int(gg["idee"][ge])))
			x += 46
		_icona("res://assets/img/segnalini/lettera_%s.webp" % gg["colore"], Vector2(x, yy), str(int(gg["lettere"])))
		x += 46
		_icona("res://assets/img/segnalini/caffe_%s.webp" % gg["colore"], Vector2(x, yy), str(int(gg["caffe"])))
		x += 46
		# carte giocate nel round: rettangolini del colore della categoria
		var xa := x + 4
		for a in gg["area"]:
			if xa + 14 > r.end.x - 4:
				break
			var cat: String = "giu" if a["giu"] else Motore.info(a["id"])["cat"]
			var cr := Rect2(xa, yy + 2, 14, 22)
			draw_rect(cr, Stile.COLORE_CAT[cat])
			draw_rect(cr, Color(0.25, 0.18, 0.1), false, 1.5)
			xa += 17
		if gg["area"].is_empty() and x + 100 < r.end.x:
			draw_string(Stile.testo(), Vector2(x + 4, yy + 22), "mano %d, tessere %d" % [gg["mano"].size(), gg["tessere"].size()], HORIZONTAL_ALIGNMENT_LEFT, r.end.x - x - 8, 15, Stile.INCHIOSTRO_DEBOLE)
		y += 78
	for au in s.get("automi", []):
		pass

func _icona(path: String, pos: Vector2, n: String) -> void:
	draw_texture_rect(Stile.tex(path), Rect2(pos, Vector2(28, 28)), false)
	draw_string(Stile.grassetto(), pos + Vector2(29, 22), n, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Stile.INCHIOSTRO)
