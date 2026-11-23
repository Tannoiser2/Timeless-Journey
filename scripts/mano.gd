class_name Mano
extends Control
## Le carte del giocatore: quelle giocate in questo round (area personale) e quelle in mano,
## con i pulsanti per giocarle scoperte o coperte, attivarle in catena o scartarle.

signal scelta(id: String)
signal ingrandisci(percorso: String)

var s: Dictionary = {}
var p := 0
var opz: Array = []
var tipo := ""
var _zone: Array = []
var _sopra := -1

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func aggiorna(stato: Dictionary, posto: int, scelte: Array, tipo_attesa: String) -> void:
	s = stato
	p = posto
	opz = scelte
	tipo = tipo_attesa
	queue_redraw()

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var k := -1
		for i in _zone.size():
			if _zone[i][0].has_point(e.position):
				k = i
		if k != _sopra:
			_sopra = k
			queue_redraw()
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		for z in _zone:
			if z[0].has_point(e.position):
				if z[1] != "":
					scelta.emit(z[1])
				elif z[2] != "":
					ingrandisci.emit(z[2])
				accept_event()
				return

func _ha(id: String) -> bool:
	for o in opz:
		if o["id"] == id:
			return true
	return false

func _bottone(r: Rect2, t: String, id: String, forte := true) -> void:
	var i := _zone.size()
	var sopra := i == _sopra
	var fondo := Color("f3e3b8") if forte else Color("d9c7a0")
	if sopra:
		fondo = Color("fff1c8")
	draw_style_box(Stile.scatola(fondo, Color("8a5f22"), 6, 2), r)
	var dim := 18
	while dim > 11 and Stile.grassetto().get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, dim).x > r.size.x - 6:
		dim -= 1
	Stile.testo_centrato(self, Stile.grassetto(), t, r.get_center(), dim, Stile.INCHIOSTRO)
	_zone.append([r, id, ""])

func _draw() -> void:
	_zone = []
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.09, 0.07, 0.92))
	if s.is_empty() or p >= s["giocatori"].size():
		return
	var gg: Dictionary = s["giocatori"][p]
	var ch := size.y - 30 - 44
	var cw := ch * 300.0 / 450.0
	# area personale (carte giocate nel round)
	var area: Array = gg["area"]
	var ac := ch * 0.72
	var aw := cw * 0.72
	draw_string(Stile.titolo(), Vector2(10, 22), "Giocate nel round", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Stile.ORO_CHIARO)
	var xa := 10.0
	var passo_a := aw + 6
	var spazio_area := maxf(aw * 2.2, (aw + 6) * area.size())
	if area.size() > 1:
		passo_a = minf(aw + 6, (spazio_area - aw) / (area.size() - 1))
	for i in area.size():
		var a: Dictionary = area[i]
		var r := Rect2(xa + i * passo_a, 30, aw, ac)
		var path: String = "res://assets/img/carte/retro.webp" if a["giu"] else Motore.info(a["id"])["img"]
		if path == "":
			_carta_andersen(r, a["id"])
		else:
			draw_texture_rect(Stile.tex(path), r, false)
		if a["giu"]:
			Stile.testo_centrato(self, Stile.grassetto(), "coperta", r.get_center(), 18, Color.WHITE, Color(0, 0, 0, 0.9))
		_zone.append([r, "", path if not a["giu"] else Motore.info(a["id"])["img"]])
		var b := Rect2(r.position.x, r.end.y + 4, aw, 30)
		if tipo == "catena" and _ha("att:%d" % i):
			_alone(r)
			_bottone(b, "Attiva", "att:%d" % i)
		elif tipo == "coperta_muovi" and _ha(str(i)):
			_bottone(b, "Gira", str(i))
	var x0 := xa + maxf(spazio_area, aw * 2.2) + 26
	draw_line(Vector2(x0 - 13, 8), Vector2(x0 - 13, size.y - 8), Color(0.7, 0.55, 0.3, 0.5), 2)
	# mano
	var mano: Array = gg["mano"]
	draw_string(Stile.titolo(), Vector2(x0, 22), "In mano (%d)" % mano.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Stile.ORO_CHIARO)
	var disp := size.x - x0 - 10
	var passo := cw + 10
	if mano.size() > 1 and passo * mano.size() > disp:
		passo = (disp - cw) / (mano.size() - 1)
	for i in mano.size():
		var r2 := Rect2(x0 + i * passo, 30, cw, ch)
		var inf := Motore.info(mano[i])
		draw_texture_rect(Stile.tex(inf["img"]), r2, false)
		_zone.append([r2, "", inf["img"]])
		var bw := minf(cw, passo - 4)
		var y := r2.end.y + 4
		if tipo == "turno" and _ha("su:%d" % i):
			_alone(r2)
			var mezzo := bw / 2 - 2
			_bottone(Rect2(r2.position.x, y, mezzo, 34), "Gioca", "su:%d" % i)
			_bottone(Rect2(r2.position.x + mezzo + 4, y, mezzo, 34), "Coperta", "giu:%d" % i, false)
		elif (tipo == "scarta" or tipo == "rimuovi_I") and _ha(str(i)):
			_alone(r2)
			_bottone(Rect2(r2.position.x, y, bw, 34), "Scarta" if tipo == "scarta" else "Elimina", str(i))

func _alone(r: Rect2) -> void:
	draw_rect(r.grow(3), Color(1.0, 0.8, 0.25, 0.8), false, 3)

func _carta_andersen(r: Rect2, id: String) -> void:
	var k := int(id.split(":")[1])
	var an: Dictionary = Dati.d()["andersen"][k]
	draw_style_box(Stile.scatola(Stile.COLORE_CAT[an["cat"]].lightened(0.4), Stile.COLORE_CAT[an["cat"]].darkened(0.3), 10, 4), r)
	Stile.testo_centrato(self, Stile.titolo(), "Andersen", r.position + Vector2(r.size.x / 2, 22), 16, Stile.INCHIOSTRO)
	Stile.testo_centrato(self, Stile.testo(), an["nome"], r.position + Vector2(r.size.x / 2, 46), 13, Stile.INCHIOSTRO)
	Stile.testo_centrato(self, Stile.testo(), Motore.testo_eff(an["eff"]), r.position + Vector2(r.size.x / 2, r.size.y / 2 + 10), 12, Stile.INCHIOSTRO)
