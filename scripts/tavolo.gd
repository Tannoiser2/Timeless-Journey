class_name Tavolo
extends Partita
## Partita «TV + telefoni»: questo schermo fa da tavolo (mappa al centro, le otto città ai lati, i giocatori
## alle estremità, Gazzetta e Mercato in basso); ogni giocatore decide dal proprio telefono (web/telefono.html).

const CITTA_SX := ["Torino", "Firenze", "Roma", "Palermo"]
const CITTA_DX := ["Venezia", "Bologna", "Perugia", "Napoli"]

var plance: Dictionary = {}
var schede_g: Array = []
var banda: BandaTavolo
var qr_tex: Texture2D = null
var l_stato: Label

func _tocca_a_me(_chi: int) -> bool:
	return false

func pacchetto() -> Dictionary:
	var chi := chi_deve()
	var opz: Array = []
	var tipo := ""
	if chi >= 0 and s["giocatori"][chi]["tipo"] == "rete":
		opz = Motore.opzioni(s)
		tipo = s["attesa"]["tipo"]
	var vg: Array = []
	var D := Dati.d()
	for col in 3:
		var id: String = s["viaggiatori"][col]
		var v: Dictionary = D["viaggiatori"][id]
		vg.append({"id": id, "nome": v["nome"], "anni": v.get("anni", ""), "chi": v.get("chi", ""), "testo": v["testo"],
			"premio": Motore.testo_eff(D["gazzetta"][s["gazzetta"]]["premi"][col]), "citta": D["gazzetta"][s["gazzetta"]]["citta"][col]})
	var titolo: String = TITOLI.get(tipo, "")
	if tipo == "mercato":
		titolo += " Livello massimo: %s." % ["", "I", "II", "III"][int(s["attesa"]["liv"])]
	var ct := {}
	for c in Dati.citta():
		var ab: Array = D["abitanti"][c]
		var caffe: Array = []
		for disc in D["plance"][c]["caffe"]:
			var costo: Array = []
			for k in disc["costo"]:
				costo.append("%d %s" % [int(disc["costo"][k]), k])
			caffe.append((" o " if disc.get("o", false) else " e ").join(costo) + ": %d PV, poi %d PV" % [int(disc["pv"][0]), int(disc["pv"][1])])
		ct[c] = {"ab": [[ab[0], Motore.testo_eff(Motore.favore_eff(s, c, 0))], [ab[1], Motore.testo_eff(Motore.favore_eff(s, c, 1))]],
			"esp": Motore.testo_eff(D["plance"][c]["esplora_alt"]), "caffe": caffe}
	var vp := Motore.viaggiatori_pos(s)
	return {"s": s, "n": n_mossa, "o": opz, "t": titolo, "pt": Motore.punteggi(s), "vg": vg, "ct": ct, "tel": true}

func _costruisci() -> void:
	var fondo := TextureRect.new()
	fondo.texture = Stile.tex("res://assets/img/plance/tavolo.webp")
	fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.modulate = Color(0.5, 0.46, 0.42)
	add_child(fondo)
	mappa = Mappa.new()
	mappa.percorsi = true
	add_child(mappa)
	mappa.citta_cliccata.connect(_ingrandisci_citta)
	mappa3d = Mappa3D.new()
	mappa3d.visible = false
	add_child(mappa3d)
	for c in CITTA_SX + CITTA_DX:
		var pl := Plancia.new()
		pl.compatta = true
		pl.citta = c
		pl.vista = "citta"
		pl.ingrandisci.connect(_ingrandisci)
		pl.gui_input.connect(_tocco_citta.bind(c))
		add_child(pl)
		plance[c] = pl
	for i in s["giocatori"].size() + (1 if s["solo"] else 0):
		var sg := SchedaGiocatore.new()
		sg.p = i
		add_child(sg)
		schede_g.append(sg)
	banda = BandaTavolo.new()
	add_child(banda)
	banda.viaggiatore.connect(_viaggiatore)
	banda.ingrandisci.connect(_ingrandisci)
	# barra in alto
	barra = PanelContainer.new()
	barra.add_theme_stylebox_override("panel", Stile.scatola(Color(0.16, 0.11, 0.08, 0.95), Stile.ORO, 0, 2, 8))
	add_child(barra)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	barra.add_child(hb)
	hb.add_child(Stile.etichetta("Timeless Journeys", 30, Stile.ORO_CHIARO, Stile.titolo()))
	l_round = Stile.etichetta("", 24, Stile.CARTA, Stile.titolo())
	l_round.custom_minimum_size = Vector2(130, 0)
	hb.add_child(l_round)
	l_stato = Stile.etichetta("", 24, Color("ffe3a0"))
	l_stato.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l_stato.custom_minimum_size = Vector2(300, 0)
	l_stato.clip_text = true
	hb.add_child(l_stato)
	b3d = Stile.bottone("Vista 3D", _cambia_3d, 20, 110)
	hb.add_child(b3d)
	hb.add_child(Stile.bottone("Percorsi", func(): mappa.percorsi = not mappa.percorsi; mappa.vg_sel = -1; _aggiorna(), 20, 110))
	hb.add_child(Stile.bottone("Punti", _mostra_punti, 20, 80))
	hb.add_child(Stile.bottone("Regole", _regole, 20, 92))
	if rete and rete.web:
		hb.add_child(Stile.bottone("Schermo", func(): rete.schermo_intero(), 20, 100))
	hb.add_child(Stile.bottone("Menu", _menu, 20, 80))
	if rete and rete.url_tel != "":
		qr_tex = rete.qr_texture(rete.url_tel)
	_disponi()

func _disponi() -> void:
	if mappa == null or banda == null:
		return
	var W := size.x if size.x > 0 else get_viewport_rect().size.x
	var H := size.y if size.y > 0 else get_viewport_rect().size.y
	var top := 54.0
	var hb := clampf(H * 0.17, 150, 220)
	barra.position = Vector2.ZERO
	barra.size = Vector2(W, top)
	var hm := H - top - hb - 8
	var wm := hm * 1080.0 / 1825.0
	var hc := hm / 4.0
	var wc := minf(hc * 2481.0 / 1418.0, (W - wm) / 2 - 220)
	hc = wc * 1418.0 / 2481.0
	var wg := (W - wm - 2 * wc - 24) / 2
	var xm := (W - wm) / 2
	mappa.position = Vector2(xm, top + 4)
	mappa.size = Vector2(wm, hm)
	mappa3d.position = mappa.position
	mappa3d.size = mappa.size
	var y0 := top + 4 + (hm - 4 * hc) / 2
	for i in 4:
		var a: Plancia = plance[CITTA_SX[i]]
		a.position = Vector2(xm - wc - 6, y0 + i * hc)
		a.size = Vector2(wc, hc - 4)
		var b: Plancia = plance[CITTA_DX[i]]
		b.position = Vector2(xm + wm + 6, y0 + i * hc)
		b.size = Vector2(wc, hc - 4)
	# giocatori: la metà (arrotondata per eccesso) a sinistra, gli altri a destra
	var n := schede_g.size()
	var nsx := (n + 1) / 2
	var ndx := n - nsx
	for i in n:
		var sx := i < nsx
		var k := i if sx else i - nsx
		var quanti := nsx if sx else maxi(1, ndx)
		var h := minf(hm / quanti, 330)
		var sg: SchedaGiocatore = schede_g[i]
		sg.position = Vector2(6 if sx else W - wg - 6, top + 4 + k * h)
		sg.size = Vector2(wg, h - 6)
	banda.position = Vector2(0, H - hb)
	banda.size = Vector2(W, hb)
	if popup:
		popup.size = Vector2(W, H)

func _aggiorna() -> void:
	if s.is_empty():
		return
	var chi := chi_deve()
	l_round.text = "Round %s" % ["", "I", "II", "III", "IV", "V"][clampi(int(s["round"]), 1, 5)]
	if s["fine"]:
		l_stato.text = "Fine del Grand Tour: il punteggio è sui telefoni e qui con Punti"
	elif chi >= 0:
		var gg: Dictionary = s["giocatori"][chi]
		var t: String = s["attesa"].get("tipo", "")
		var cosa := {"turno": "gioca una carta", "catena": "catena di azioni", "mercato": "sceglie dal Mercato",
			"esplora": "esplora", "conversa": "conversa", "discuti": "discute al caffè", "scrivi": "scrive nel Diario",
			"lettera": "invia una lettera", "muovi": "si muove", "compra": "compra una carta", "esperienza": "incontra un Viaggiatore",
			"scarta": "scarta una carta"}.get(t, "decide")
		var dove := " (sul telefono)" if gg["tipo"] == "rete" else (" (computer)" if gg["tipo"] == "ia" else "")
		l_stato.text = "Tocca a %s: %s%s" % [gg["nome"], cosa, dove]
	mappa.aggiorna(s, {})
	if mappa3d.visible:
		mappa3d.aggiorna(s, {})
	for c in plance:
		plance[c].aggiorna(s, [])
	for sg in schede_g:
		sg.aggiorna(s, chi)
	banda.aggiorna(s, qr_tex, rete.codice if rete else "")

func _tocco_citta(e: InputEvent, c: String) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_ingrandisci_citta(c)

## la plancia di una città a schermo intero, con favori, caffè e chi c'è
func _ingrandisci_citta(c: String) -> void:
	var W := get_viewport_rect().size
	var vb := _finestra(minf(1500, W.x - 40), minf(980, W.y - 40))
	var pl := Plancia.new()
	pl.citta = c
	pl.vista = "citta"
	pl.custom_minimum_size = Vector2(minf(1440, W.x - 80), minf(860, W.y - 140))
	pl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(pl)
	pl.aggiorna(s, [])
	vb.add_child(Stile.bottone("Chiudi", _chiudi_popup, 22, 160))

func _viaggiatore(col: int) -> void:
	mappa.percorsi = true
	mappa.vg_sel = col
	_aggiorna()
	var D := Dati.d()
	var id: String = s["viaggiatori"][col]
	var v: Dictionary = D["viaggiatori"][id]
	var W := get_viewport_rect().size
	var vb := _finestra(minf(1100, W.x - 40), minf(720, W.y - 40))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 24)
	vb.add_child(hb)
	var tr := TextureRect.new()
	tr.texture = Stile.tex("res://assets/img/viaggiatori/%s.webp" % id)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(380, 570)
	hb.add_child(tr)
	var col_v := VBoxContainer.new()
	col_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(col_v)
	col_v.add_child(Stile.etichetta(v["nome"], 36, Mappa.COL_VG[col].darkened(0.3), Stile.titolo()))
	col_v.add_child(Stile.etichetta("%s, %s" % [v.get("chi", ""), v.get("anni", "")], 20, Stile.INCHIOSTRO_DEBOLE))
	col_v.add_child(Stile.paragrafo(v["testo"], 560, 22))
	col_v.add_child(Stile.paragrafo("Chi lo incontra (Conversare nella sua città) ottiene: " + Motore.testo_eff(D["gazzetta"][s["gazzetta"]]["premi"][col]) + ".", 560, 22, Color("6a2a10")))
	col_v.add_child(Stile.etichetta("Il suo viaggio", 26, Stile.INCHIOSTRO, Stile.titolo()))
	var r := int(s["round"])
	for i in 5:
		var c: String = D["gazzetta"][s["gazzetta"]]["citta"][col][i]
		var sp = s["gaz"][col][i]
		var chi_l := ""
		if sp != null:
			var p: int = int(sp["p"])
			chi_l = ": incontrato da " + (s["automi"][p - 100]["nome"] if p >= 100 else s["giocatori"][p]["nome"])
		elif int(s["nn"]) < int(D["gazzetta_min"][i][col]):
			chi_l = ": spazio chiuso con questo numero di giocatori"
		var riga := "Round %s: %s%s%s" % [Mappa.ROMANI[i], c, chi_l, "   (ora)" if i + 1 == r else ""]
		col_v.add_child(Stile.paragrafo(riga, 560, 21, Stile.INCHIOSTRO if i + 1 >= r else Stile.INCHIOSTRO_DEBOLE))
	var hb2 := HBoxContainer.new()
	vb.add_child(hb2)
	hb2.add_child(Stile.bottone("Chiudi", func(): _chiudi_popup(), 22, 160))
	hb2.add_child(Stile.bottone("Mostra tutti i percorsi", func(): mappa.vg_sel = -1; _chiudi_popup(); _aggiorna(), 22, 300))

func _cambia_3d() -> void:
	_vista_3d = not _vista_3d
	mappa3d.visible = _vista_3d
	mappa.visible = not _vista_3d
	b3d.text = "Vista 2D" if _vista_3d else "Vista 3D"
	if _vista_3d:
		mappa3d.aggiorna(s, {})
