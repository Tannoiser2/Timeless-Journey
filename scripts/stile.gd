class_name Stile
extends RefCounted
## Colori, font e piccoli aiuti grafici: carta antica, inchiostro, oro, come la grafica del gioco.

const CARTA := Color("f1e6cc")
const CARTA_SCURA := Color("e2d2ae")
const INCHIOSTRO := Color("3b2a1c")
const INCHIOSTRO_DEBOLE := Color("7a6450")
const ORO := Color("b88a3a")
const ORO_CHIARO := Color("e0b866")
const BLU_NOTTE := Color("1f2a36")
const LEGNO := Color("4a3324")
const FONDO := Color("2b2018")
const VERDE := Color("4f7f4a")
const ROSSO := Color("a63a2b")
const EVIDENZA := Color("f2c14e")

const COLORE_CAT := {"V": Color("e9a43b"), "A": Color("3e9a9a"), "I": Color("9a72b8"), "F": Color("d9d2c2"), "giu": Color("6b6b6b")}
const COLORE_IDEA := {"Arte": Color("d8574a"), "Storia": Color("d9a53a"), "Filosofia": Color("4fa3c7"), "Scienza": Color("4c9a52")}

static var _font := {}

static func font(nome: String) -> Font:
	if not _font.has(nome):
		_font[nome] = load("res://assets/font/%s.ttf" % nome)
	return _font[nome]

static func titolo() -> Font:
	return font("IMFellEnglishSC")

static func testo() -> Font:
	return font("EBGaramond-Medium")

static func grassetto() -> Font:
	return font("EBGaramond-Bold")

static var _tex := {}

static func tex(percorso: String) -> Texture2D:
	if percorso == "":
		return null
	if not _tex.has(percorso):
		_tex[percorso] = load(percorso) if ResourceLoader.exists(percorso) else null
	return _tex[percorso]

static func scatola(fondo: Color, bordo: Color, raggio := 8, spessore := 2, margine := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fondo
	sb.border_color = bordo
	sb.set_border_width_all(spessore)
	sb.set_corner_radius_all(raggio)
	sb.content_margin_left = margine
	sb.content_margin_right = margine
	sb.content_margin_top = margine * 0.6
	sb.content_margin_bottom = margine * 0.6
	sb.anti_aliasing = true
	return sb

static func tema() -> Theme:
	var t := Theme.new()
	t.default_font = testo()
	t.default_font_size = 22
	t.set_color("font_color", "Label", INCHIOSTRO)
	for k in ["Button", "CheckBox", "OptionButton"]:
		t.set_color("font_color", k, INCHIOSTRO)
		t.set_color("font_hover_color", k, Color("1a120b"))
		t.set_color("font_pressed_color", k, Color("1a120b"))
		t.set_color("font_focus_color", k, INCHIOSTRO)
		t.set_color("font_disabled_color", k, Color(0.23, 0.16, 0.11, 0.4))
		t.set_font("font", k, grassetto())
		t.set_font_size("font_size", k, 22)
	t.set_stylebox("normal", "Button", scatola(Color("efe0bd"), ORO, 8, 2))
	t.set_stylebox("hover", "Button", scatola(Color("f8ecd0"), Color("8a5f22"), 8, 2))
	t.set_stylebox("pressed", "Button", scatola(Color("e5d09f"), Color("6a4416"), 8, 3))
	t.set_stylebox("disabled", "Button", scatola(Color("d9ccb0"), Color("b9a684"), 8, 2))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for k in ["CheckBox", "OptionButton"]:
		t.set_stylebox("normal", k, scatola(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 6, 0))
		t.set_stylebox("hover", k, scatola(Color(1, 1, 1, 0.25), Color(0, 0, 0, 0), 6, 0))
		t.set_stylebox("pressed", k, scatola(Color(1, 1, 1, 0.15), Color(0, 0, 0, 0), 6, 0))
		t.set_stylebox("focus", k, StyleBoxEmpty.new())
		t.set_stylebox("hover_pressed", k, scatola(Color(1, 1, 1, 0.25), Color(0, 0, 0, 0), 6, 0))
	t.set_stylebox("normal", "OptionButton", scatola(Color("efe0bd"), ORO, 8, 2))
	t.set_stylebox("hover", "OptionButton", scatola(Color("f8ecd0"), Color("8a5f22"), 8, 2))
	t.set_icon("unchecked", "CheckBox", _casella(false))
	t.set_icon("checked", "CheckBox", _casella(true))
	t.set_icon("arrow", "OptionButton", _freccia())
	t.set_stylebox("panel", "PanelContainer", scatola(Color(0.95, 0.91, 0.81, 0.97), ORO, 10, 2, 12))
	t.set_stylebox("panel", "PopupMenu", scatola(Color("f4ead2"), ORO, 6, 2, 8))
	t.set_color("font_color", "PopupMenu", INCHIOSTRO)
	t.set_color("font_hover_color", "PopupMenu", Color.BLACK)
	t.set_stylebox("hover", "PopupMenu", scatola(Color("e5d09f"), Color(0, 0, 0, 0), 4, 0))
	t.set_font("font", "PopupMenu", testo())
	t.set_font_size("font_size", "PopupMenu", 22)
	t.set_icon("radio_unchecked", "PopupMenu", _casella(false))
	t.set_icon("radio_checked", "PopupMenu", _casella(true))
	t.set_stylebox("normal", "LineEdit", scatola(Color("fbf4e2"), ORO, 6, 2))
	t.set_stylebox("focus", "LineEdit", scatola(Color("fffaf0"), Color("8a5f22"), 6, 2))
	t.set_color("font_color", "LineEdit", INCHIOSTRO)
	t.set_font_size("font_size", "LineEdit", 24)
	t.set_stylebox("scroll", "VScrollBar", scatola(Color(0, 0, 0, 0.08), Color(0, 0, 0, 0), 4, 0, 2))
	t.set_stylebox("grabber", "VScrollBar", scatola(Color(0.55, 0.42, 0.25, 0.6), Color(0, 0, 0, 0), 4, 0, 2))
	t.set_stylebox("grabber_highlight", "VScrollBar", scatola(Color(0.55, 0.42, 0.25, 0.85), Color(0, 0, 0, 0), 4, 0, 2))
	t.set_stylebox("grabber_pressed", "VScrollBar", scatola(Color(0.45, 0.32, 0.18, 0.9), Color(0, 0, 0, 0), 4, 0, 2))
	t.set_constant("separation", "VBoxContainer", 8)
	t.set_constant("separation", "HBoxContainer", 8)
	t.set_color("default_color", "RichTextLabel", INCHIOSTRO)
	t.set_font("normal_font", "RichTextLabel", testo())
	t.set_font("bold_font", "RichTextLabel", grassetto())
	t.set_font_size("normal_font_size", "RichTextLabel", 19)
	t.set_font_size("bold_font_size", "RichTextLabel", 19)
	return t

## casella di spunta disegnata (niente simboli dei font)
static func _casella(piena: bool) -> ImageTexture:
	var im := Image.create(30, 30, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	for x in 30:
		for y in 30:
			var bordo := x < 3 or y < 3 or x > 26 or y > 26
			if bordo:
				im.set_pixel(x, y, ORO.darkened(0.3))
			elif x > 3 and y > 3 and x < 26 and y < 26:
				im.set_pixel(x, y, Color("fbf4e2"))
	if piena:
		for x in range(8, 23):
			for y in range(8, 23):
				im.set_pixel(x, y, ROSSO)
	return ImageTexture.create_from_image(im)

static func _freccia() -> ImageTexture:
	var im := Image.create(20, 14, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	for y in 10:
		for x in range(y, 20 - y):
			im.set_pixel(x, y + 2, INCHIOSTRO)
	return ImageTexture.create_from_image(im)

static func etichetta(t: String, dim := 22, colore := INCHIOSTRO, f: Font = null) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", dim)
	l.add_theme_color_override("font_color", colore)
	if f:
		l.add_theme_font_override("font", f)
	return l

## etichetta a più righe: ha sempre una larghezza minima, così non si stringe in colonna
static func paragrafo(t: String, larghezza: float, dim := 20, colore := INCHIOSTRO) -> Label:
	var l := etichetta(t, dim, colore)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(larghezza, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

static func bottone(t: String, cb: Callable, dim := 22, larghezza := 0.0) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", dim)
	b.pressed.connect(cb)
	if larghezza > 0:
		b.custom_minimum_size = Vector2(larghezza, 0)
	return b

## bottone con testo che va a capo (per le scelte lunghe): larghezza minima fissa
static func bottone_lungo(t: String, cb: Callable, larghezza: float, dim := 19) -> Button:
	var b := Button.new()
	b.text = t
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(larghezza, 40)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", dim)
	b.add_theme_font_override("font", testo())
	b.pressed.connect(cb)
	return b

static func colore(nome: String) -> Color:
	return Dati.COLORI_GIOCATORE.get(nome, Color.WHITE)

## disegna un segnalino tondo colorato con bordo
static func disco(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c + Vector2(1.5, 2.5), r, Color(0, 0, 0, 0.35))
	ci.draw_circle(c, r, col.darkened(0.45))
	ci.draw_circle(c, r * 0.84, col)
	ci.draw_circle(c - Vector2(r * 0.25, r * 0.3), r * 0.28, col.lightened(0.35))

## sagoma di un meeple (pedina del giocatore) disegnata con poligoni
static func meeple(ci: CanvasItem, c: Vector2, h: float, col: Color) -> void:
	var s := h / 100.0
	var pts := PackedVector2Array([
		Vector2(-12, -48), Vector2(12, -48), Vector2(16, -36), Vector2(13, -24), Vector2(38, -14), Vector2(42, -2),
		Vector2(20, 0), Vector2(28, 44), Vector2(8, 44), Vector2(0, 22), Vector2(-8, 44), Vector2(-28, 44),
		Vector2(-20, 0), Vector2(-42, -2), Vector2(-38, -14), Vector2(-13, -24), Vector2(-16, -36)])
	var ombra := PackedVector2Array()
	var forma := PackedVector2Array()
	for p in pts:
		forma.append(c + p * s)
		ombra.append(c + p * s + Vector2(2, 3))
	ci.draw_colored_polygon(ombra, Color(0, 0, 0, 0.35))
	ci.draw_colored_polygon(forma, col)
	var chiuso := forma.duplicate()
	chiuso.append(forma[0])
	ci.draw_polyline(chiuso, col.darkened(0.55), maxf(1.5, 2.5 * s), true)
	ci.draw_circle(c + Vector2(0, -38) * s, 9 * s, col.lightened(0.2))

static func testo_centrato(ci: CanvasItem, f: Font, t: String, c: Vector2, dim: int, col: Color, bordo := Color(0, 0, 0, 0)) -> void:
	var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, dim).x
	var pos := c + Vector2(-w / 2.0, dim * 0.35)
	if bordo.a > 0:
		ci.draw_string_outline(f, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, dim, 4, bordo)
	ci.draw_string(f, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, dim, col)
