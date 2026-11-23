extends Control
## Menu principale: nuova partita (fino a 5 giocatori, computer, online), solitario con gli Automi, espansioni,
## partita salvata, stanze online su Firebase.

var rete: Rete
var partita: Partita = null
var stato_rete: Label = null
var contenuto: Control = null

# impostazioni della nuova partita
var posti: Array = []        # [{attivo, nome, colore, tipo}]
var solo := false
var tavolo := false          # TV e telefoni: questo schermo fa da tavolo, si gioca dal telefono con il QR code
var qr_lobby: TextureRect = null
var ripresa_tavolo: Dictionary = {}
var modo_vg := "intro"
var scelti_vg: Array = []
var gazzetta := ""
var favori_intro := true
var senza_settima := false
var esp := {"napoleone": false, "diodati": false, "romantici": false}
var livello_ia := 2

# online
var stanza_attesa: Dictionary = {}
var ospiti: Array = []       # [{uid, nome}]
var mio_uid := ""
var nome_ospite := "Viaggiatore"

const COLORI := ["rosso", "giallo", "verde", "blu", "grigio"]

func _ready() -> void:
	theme = Stile.tema()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rete = Rete.new()
	add_child(rete)
	rete.evento.connect(_evento_rete)
	var nomi := ["Stefano", "Giulia", "Marco", "Lucia", "Pietro"]
	for i in 5:
		posti.append({"attivo": i < 3, "nome": nomi[i], "colore": COLORI[i], "tipo": "umano" if i == 0 else "ia"})
	var p := rete.parametri()
	if p.has("stanza"):
		_entra_schermo(str(p["stanza"]))
	else:
		_home()

func _pulisci() -> void:
	for c in get_children():
		if c != rete:
			c.queue_free()
	partita = null
	stato_rete = null

func _fondo() -> void:
	var tr := TextureRect.new()
	tr.texture = Stile.tex("res://assets/img/plance/copertina.webp")
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tr)
	var velo := ColorRect.new()
	velo.color = Color(0.08, 0.05, 0.03, 0.35)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(velo)

func _scatola(larghezza: float) -> VBoxContainer:
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var pc := PanelContainer.new()
	var W := get_viewport_rect().size
	pc.custom_minimum_size = Vector2(minf(larghezza, W.x - 30), 0)
	cc.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	pc.add_child(vb)
	return vb

# ============================================================================ home
func _home() -> void:
	_pulisci()
	_fondo()
	var vb := _scatola(640)
	var t := Stile.etichetta("Timeless Journeys", 56, Color("5a2d10"), Stile.titolo())
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var t2 := Stile.etichetta("Il Grand Tour italiano", 30, Stile.INCHIOSTRO, Stile.titolo())
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t2)
	var d := Stile.paragrafo("Da Torino a Palermo, sulle orme dei primi viaggiatori: carte in catena, caffè letterari, lettere, amicizie e Diari di Viaggio. Da 1 a 5 giocatori, contro il computer o online, con le espansioni Napoleone, Villa Diodati e I Romantici.", 580, 20)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(d)
	vb.add_child(Stile.bottone("Nuova partita", _impostazioni, 28))
	var salvato := rete.carica("timeless_partita")
	if salvato != "":
		vb.add_child(Stile.bottone("Riprendi la partita salvata", _riprendi.bind(salvato), 24))
	vb.add_child(Stile.bottone("Entra in una partita online", _entra_schermo.bind(""), 24))
	if rete.web:
		vb.add_child(Stile.bottone("Recupera il salvataggio online", func(): stato_rete.text = "Cerco il salvataggio..."; rete.chiedi_remoto(), 22))
	vb.add_child(Stile.bottone("Regole", _regole, 22))
	stato_rete = Stile.paragrafo("", 580, 19)
	stato_rete.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(stato_rete)

func _regole() -> void:
	_pulisci()
	_fondo()
	var vb := _scatola(1150)
	vb.add_child(Stile.etichetta("Come si gioca", 34, Stile.INCHIOSTRO, Stile.titolo()))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, minf(760, get_viewport_rect().size.y - 200))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.custom_minimum_size = Vector2(minf(1080, get_viewport_rect().size.x - 80), 0)
	r.add_theme_font_size_override("normal_font_size", 20)
	r.add_theme_font_size_override("bold_font_size", 20)
	r.text = Regole.TESTO
	sc.add_child(r)
	vb.add_child(Stile.bottone("Indietro", _home, 22))

# ============================================================================ impostazioni
func _impostazioni() -> void:
	_pulisci()
	_fondo()
	var W := get_viewport_rect().size
	var sc := ScrollContainer.new()
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	var cc := CenterContainer.new()
	cc.custom_minimum_size = Vector2(W.x, W.y)
	sc.add_child(cc)
	var pc := PanelContainer.new()
	cc.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.custom_minimum_size = Vector2(minf(1100, W.x - 40), 0)
	pc.add_child(vb)
	vb.add_child(Stile.etichetta("Nuova partita", 38, Color("5a2d10"), Stile.titolo()))
	# modo
	var hm := HBoxContainer.new()
	vb.add_child(hm)
	var b1 := Stile.bottone("Su questo schermo", func(): solo = false; _metti_tavolo(false); _impostazioni(), 22, 240)
	b1.toggle_mode = true
	b1.button_pressed = not solo and not tavolo
	hm.add_child(b1)
	var b3 := Stile.bottone("TV e telefoni (QR code)", func(): solo = false; _metti_tavolo(true); _impostazioni(), 22, 290)
	b3.toggle_mode = true
	b3.button_pressed = tavolo
	hm.add_child(b3)
	var b2 := Stile.bottone("Solitario con gli Automi", func(): solo = true; _metti_tavolo(false); _impostazioni(), 22, 290)
	b2.toggle_mode = true
	b2.button_pressed = solo
	hm.add_child(b2)
	if tavolo:
		vb.add_child(Stile.paragrafo("Questo schermo (la TV) fa da tavolo: mappa al centro e le otto città ai lati. Ogni giocatore inquadra il QR code con il telefono e lì ha la sua mano, le carte giocate, i Diari e le scelte. I posti senza telefono li gioca il computer.", 1000, 19))
	# giocatori
	vb.add_child(Stile.etichetta("Giocatori", 26, Stile.INCHIOSTRO, Stile.titolo()))
	var n := 1 if solo else 5
	for i in n:
		var r := HBoxContainer.new()
		vb.add_child(r)
		var cb := CheckBox.new()
		cb.button_pressed = posti[i]["attivo"] or i < (1 if solo else 2)
		cb.disabled = i < (1 if solo else 2)
		cb.custom_minimum_size = Vector2(40, 40)
		cb.toggled.connect(func(v): posti[i]["attivo"] = v)
		if i < 2: posti[i]["attivo"] = true
		r.add_child(cb)
		var le := LineEdit.new()
		le.text = posti[i]["nome"]
		le.custom_minimum_size = Vector2(240, 0)
		le.text_changed.connect(func(t): posti[i]["nome"] = t)
		r.add_child(le)
		var oc := OptionButton.new()
		oc.custom_minimum_size = Vector2(150, 0)
		for k in COLORI.size():
			oc.add_item(Dati.NOMI_COLORE[COLORI[k]], k)
		oc.selected = COLORI.find(posti[i]["colore"])
		oc.item_selected.connect(func(k): posti[i]["colore"] = COLORI[k])
		r.add_child(oc)
		if tavolo:
			var ot2 := OptionButton.new()
			ot2.custom_minimum_size = Vector2(330, 0)
			ot2.add_item("Persona con il telefono", 0)
			ot2.add_item("Computer", 1)
			ot2.selected = 1 if posti[i]["tipo"] == "ia" else 0
			ot2.item_selected.connect(func(k): posti[i]["tipo"] = ["rete", "ia"][k])
			r.add_child(ot2)
		elif not solo:
			var ot := OptionButton.new()
			ot.custom_minimum_size = Vector2(330, 0)
			ot.add_item("Persona su questo dispositivo", 0)
			ot.add_item("Computer", 1)
			ot.add_item("Persona online (altro dispositivo)", 2)
			ot.selected = {"umano": 0, "ia": 1, "rete": 2}[posti[i]["tipo"]]
			ot.item_selected.connect(func(k): posti[i]["tipo"] = ["umano", "ia", "rete"][k])
			r.add_child(ot)
		else:
			posti[0]["tipo"] = "umano"
	# viaggiatori
	vb.add_child(Stile.etichetta("Viaggiatori Celebri", 26, Stile.INCHIOSTRO, Stile.titolo()))
	var ov := OptionButton.new()
	var modi := [["intro", "Partita introduttiva: Montesquieu, Lady Montagu, Mary Shelley"],
		["A", "Immersione storica: inizio XVIII secolo (Addison, Montagu, Montesquieu)"],
		["B", "Immersione storica: fine XVIII secolo (Craven, Goethe, Le Brun)"],
		["C", "Immersione storica: inizio XIX secolo (Byron, Keats, Mary Shelley)"],
		["D", "Immersione storica: fine XIX secolo (Blessington, Dickens, Twain)"],
		["caso", "Timeless Jam: tre a caso"], ["scelti", "Viaggio da esperti: li scelgo io"]]
	for k in modi.size():
		ov.add_item(modi[k][1], k)
		if modi[k][0] == modo_vg: ov.selected = k
	ov.item_selected.connect(func(k): modo_vg = modi[k][0]; _impostazioni())
	vb.add_child(ov)
	if modo_vg == "scelti":
		var gr := GridContainer.new()
		gr.columns = 4
		vb.add_child(gr)
		for vid in Dati.d()["viaggiatori"]:
			var v: Dictionary = Dati.d()["viaggiatori"][vid]
			var e2: String = v.get("esp", "")
			if e2 != "" and not esp[e2]:
				continue
			var c2 := CheckBox.new()
			c2.text = v["nome"]
			c2.custom_minimum_size = Vector2(250, 36)
			c2.button_pressed = scelti_vg.has(vid)
			c2.toggled.connect(func(on):
				if on and not scelti_vg.has(vid): scelti_vg.append(vid)
				elif not on: scelti_vg.erase(vid))
			gr.add_child(c2)
		vb.add_child(Stile.etichetta("Scegline esattamente tre.", 18, Stile.INCHIOSTRO_DEBOLE))
	# opzioni
	vb.add_child(Stile.etichetta("Opzioni", 26, Stile.INCHIOSTRO, Stile.titolo()))
	var hg := HBoxContainer.new()
	vb.add_child(hg)
	hg.add_child(Stile.etichetta("Gazzetta del Viaggiatore:", 20))
	var og := OptionButton.new()
	og.custom_minimum_size = Vector2(160, 0)
	var lati := ["", "A", "B", "C", "D"]
	for k in lati.size():
		og.add_item("a caso" if lati[k] == "" else "lato " + lati[k], k)
		if lati[k] == gazzetta: og.selected = k
	og.item_selected.connect(func(k): gazzetta = lati[k])
	hg.add_child(og)
	hg.add_child(Stile.etichetta("   Computer:", 20))
	var oi := OptionButton.new()
	oi.custom_minimum_size = Vector2(170, 0)
	oi.add_item("bravo", 0)
	oi.add_item("principiante", 1)
	oi.selected = 0 if livello_ia == 2 else 1
	oi.item_selected.connect(func(k): livello_ia = 2 if k == 0 else 1)
	hg.add_child(oi)
	var cf := CheckBox.new()
	cf.text = "Tessere Favore della partita introduttiva (FT01-04, FT07-10)"
	cf.button_pressed = favori_intro
	cf.toggled.connect(func(v): favori_intro = v)
	vb.add_child(cf)
	var c7 := CheckBox.new()
	c7.text = "Le persone giocano senza la 7ª carta (sfida più difficile)"
	c7.button_pressed = senza_settima
	c7.toggled.connect(func(v): senza_settima = v)
	vb.add_child(c7)
	vb.add_child(Stile.etichetta("Espansioni", 26, Stile.INCHIOSTRO, Stile.titolo()))
	for e in [["napoleone", "Napoleone (Pattuglie Austriache, Soldati Francesi, battaglie e tre nuovi viaggiatori)"],
			["diodati", "Una Notte di Terrore a Villa Diodati (i Mostri)"],
			["romantici", "I Romantici (Rousseau, Stendhal, Andersen, Liszt, Percy Shelley)"]]:
		var ce := CheckBox.new()
		ce.text = e[1]
		ce.button_pressed = esp[e[0]]
		ce.toggled.connect(func(v): esp[e[0]] = v; if modo_vg == "scelti" or modo_vg == "caso": _impostazioni())
		vb.add_child(ce)
	stato_rete = Stile.paragrafo("", 1000, 19, Color("8a2a14"))
	vb.add_child(stato_rete)
	var hb := HBoxContainer.new()
	vb.add_child(hb)
	hb.add_child(Stile.bottone("Indietro", _home, 24, 160))
	hb.add_child(Stile.bottone("Si parte!", _parti, 28, 260))

func _opzioni_partita() -> Dictionary:
	var gs: Array = []
	var sette: Array = []
	var usati := {}
	for i in (1 if solo else 5):
		var p: Dictionary = posti[i]
		if not (p["attivo"] or i < (1 if solo else 2)):
			continue
		if usati.has(p["colore"]):
			stato_rete.text = "Due giocatori hanno lo stesso colore."
			return {}
		usati[p["colore"]] = true
		var nome: String = p["nome"].strip_edges()
		if nome == "":
			nome = "Giocatore %d" % (gs.size() + 1)
		gs.append({"nome": nome.substr(0, 16), "colore": p["colore"], "tipo": p["tipo"] if not solo else "umano"})
		sette.append(not (senza_settima and p["tipo"] != "ia"))
	if solo and usati.size() > 0:
		# gli Automi prendono due colori liberi diversi dal grigio
		pass
	var o := {"giocatori": gs, "solo": solo, "seme": int(Time.get_unix_time_from_system()) ^ randi(), "esp": esp.duplicate(),
		"gazzetta": gazzetta, "favori_intro": favori_intro, "settima": sette}
	if modo_vg == "scelti":
		if scelti_vg.size() != 3:
			stato_rete.text = "Scegli esattamente tre Viaggiatori Celebri."
			return {}
		o["viaggiatori"] = scelti_vg.duplicate()
	else:
		o["modo_viaggiatori"] = modo_vg
	return o

func _parti() -> void:
	var o := _opzioni_partita()
	if o.is_empty():
		return
	var online := 0
	for g in o["giocatori"]:
		if g["tipo"] == "rete": online += 1
	if tavolo:
		if online == 0:
			stato_rete.text = "Con TV e telefoni serve almeno una persona con il telefono."
			return
		_apri_tavolo(o, {})
		return
	if online > 0:
		_apri_stanza(o, online)
		return
	var s := Motore.nuova(o)
	_gioca(s, "locale", 0)

func _gioca(s: Dictionary, modo: String, posto: int) -> void:
	_pulisci()
	partita = Tavolo.new() if modo == "tavolo" else Partita.new()
	partita.livello_ia = livello_ia
	add_child(partita)
	partita.esci.connect(_esci_partita)
	partita.avvia(s, modo, rete, posto)
	partita._dopo()

func _esci_partita() -> void:
	if partita and partita.modo != "locale":
		rete.chiudi()
	_home()

func _riprendi(j: String) -> void:
	var d = JSON.parse_string(j)
	if not d is Dictionary or not d.has("s"):
		if stato_rete: stato_rete.text = "Il salvataggio non si legge."
		return
	var s: Dictionary = d["s"]
	if d.get("modo", "locale") == "tavolo" and rete.web:
		_apri_tavolo({}, s)
		return
	if d.get("modo", "locale") == "host" or d.get("modo", "locale") == "tavolo":
		# la partita online riprende sullo stesso dispositivo: i posti online diventano del computer
		for g in s["giocatori"]:
			if g["tipo"] == "rete":
				g["tipo"] = "ia"
	_gioca(s, "locale", int(d.get("io", 0)))

# ============================================================================ online: chi ospita
func _apri_stanza(o: Dictionary, online: int) -> void:
	if not rete.web:
		stato_rete.text = "Il gioco online funziona solo nella versione per browser."
		return
	stanza_attesa = o
	ospiti = []
	_pulisci()
	_fondo()
	var vb := _scatola(720)
	vb.add_child(Stile.etichetta("Stanza online", 36, Stile.INCHIOSTRO, Stile.titolo()))
	stato_rete = Stile.paragrafo("Apro la stanza...", 660, 22)
	vb.add_child(stato_rete)
	var hb := HBoxContainer.new()
	vb.add_child(hb)
	hb.add_child(Stile.bottone("Annulla", func(): rete.chiudi(); _home(), 22, 160))
	var parti := Stile.bottone("Inizia (i posti vuoti al computer)", _avvia_online, 22, 380)
	hb.add_child(parti)
	rete.avvia()

func _testo_stanza() -> void:
	var o := stanza_attesa
	var righe: Array = ["Codice della stanza: %s" % rete.codice, "Link da mandare: %s" % rete.url, ""]
	var k := 0
	for g in o["giocatori"]:
		if g["tipo"] == "rete":
			var chi := "in attesa..."
			if k < ospiti.size():
				chi = ospiti[k]["nome"] + " è dentro"
			righe.append("%s (%s): %s" % [g["nome"], Dati.NOMI_COLORE[g["colore"]], chi])
			k += 1
	if stato_rete:
		stato_rete.text = "\n".join(righe)

func _avvia_online() -> void:
	var o: Dictionary = stanza_attesa.duplicate(true)
	if o.is_empty():
		return
	var k := 0
	for g in o["giocatori"]:
		if g["tipo"] == "rete":
			if k < ospiti.size():
				g["uid"] = ospiti[k]["uid"]
				g["nome"] = String(ospiti[k]["nome"]).substr(0, 16)
			else:
				g["tipo"] = "ia"
			k += 1
	var s := Motore.nuova(o)
	stanza_attesa = {}
	var mio := 0
	for i in s["giocatori"].size():
		if s["giocatori"][i]["tipo"] == "umano":
			mio = i
			break
	_gioca(s, "host", mio)

# ============================================================================ TV e telefoni
func _metti_tavolo(v: bool) -> void:
	tavolo = v
	for i in posti.size():
		if v and posti[i]["tipo"] != "ia":
			posti[i]["tipo"] = "rete"
		elif not v and posti[i]["tipo"] == "rete":
			posti[i]["tipo"] = "umano"

## sala d'attesa: QR code grande, i giocatori entrano dal telefono. ripresa: partita salvata da riprendere
func _apri_tavolo(o: Dictionary, ripresa: Dictionary) -> void:
	if not rete.web:
		if stato_rete:
			stato_rete.text = "Il gioco con i telefoni funziona solo nella versione per browser."
		return
	stanza_attesa = o
	ripresa_tavolo = ripresa
	ospiti = []
	_pulisci()
	_fondo()
	var vb := _scatola(1100)
	vb.add_child(Stile.etichetta("Tavolo con i telefoni", 38, Color("5a2d10"), Stile.titolo()))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 30)
	vb.add_child(hb)
	qr_lobby = TextureRect.new()
	qr_lobby.custom_minimum_size = Vector2(420, 420)
	qr_lobby.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	qr_lobby.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	qr_lobby.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hb.add_child(qr_lobby)
	stato_rete = Stile.paragrafo("Apro la stanza...", 560, 24)
	stato_rete.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(stato_rete)
	var hb2 := HBoxContainer.new()
	vb.add_child(hb2)
	hb2.add_child(Stile.bottone("Annulla", func(): rete.chiudi(); qr_lobby = null; _home(), 24, 180))
	hb2.add_child(Stile.bottone("Inizia (i posti vuoti al computer)", _avvia_tavolo, 24, 420))
	rete.avvia()

func _posti_telefono() -> Array:
	var gs: Array = ripresa_tavolo["giocatori"] if not ripresa_tavolo.is_empty() else stanza_attesa["giocatori"]
	var out: Array = []
	for g in gs:
		if g["tipo"] == "rete":
			out.append(g)
	return out

func _testo_tavolo() -> void:
	if stato_rete == null:
		return
	var righe: Array = ["Inquadra il QR code con il telefono,", "oppure apri %s" % rete.url_tel, "e scrivi il codice %s." % rete.codice, ""]
	var posti_t := _posti_telefono()
	righe.append("Posti con il telefono: %d" % posti_t.size())
	for o in ospiti:
		righe.append("  %s è dentro" % o["nome"])
	if ospiti.size() > posti_t.size():
		righe.append("(i telefoni in più guardano soltanto)")
	stato_rete.text = "\n".join(righe)

func _avvia_tavolo() -> void:
	var s: Dictionary
	var liberi: Array = ospiti.duplicate()
	if not ripresa_tavolo.is_empty():
		s = ripresa_tavolo
		# prima chi ritrova il suo nome, poi gli altri in ordine
		var da_fare: Array = []
		for g in s["giocatori"]:
			if g["tipo"] != "rete":
				continue
			var preso := -1
			for k in liberi.size():
				if String(liberi[k]["nome"]).to_lower() == String(g["nome"]).to_lower():
					preso = k
					break
			if preso >= 0:
				g["uid"] = liberi[preso]["uid"]
				liberi.remove_at(preso)
			else:
				da_fare.append(g)
		for g in da_fare:
			if liberi.size():
				g["uid"] = liberi[0]["uid"]
				liberi.remove_at(0)
			else:
				g["tipo"] = "ia"
	else:
		var o: Dictionary = stanza_attesa.duplicate(true)
		if o.is_empty():
			return
		for g in o["giocatori"]:
			if g["tipo"] == "rete":
				if liberi.size():
					g["uid"] = liberi[0]["uid"]
					g["nome"] = String(liberi[0]["nome"]).substr(0, 16)
					liberi.remove_at(0)
				else:
					g["tipo"] = "ia"
		var nomi := {}
		for g in o["giocatori"]:
			while nomi.has(g["nome"]):
				g["nome"] = g["nome"] + "*"
			nomi[g["nome"]] = true
		s = Motore.nuova(o)
	stanza_attesa = {}
	ripresa_tavolo = {}
	qr_lobby = null
	_gioca(s, "tavolo", 0)

## un telefono rientra a partita iniziata (pagina ricaricata o telefono nuovo): ritrova il posto con il nome
func _rientra(uid: String, nome: String) -> void:
	var s: Dictionary = partita.s
	for g in s["giocatori"]:
		if g.get("uid", "") == uid:
			return
	for g in s["giocatori"]:
		if (g["tipo"] == "rete" or g["tipo"] == "ia") and String(g["nome"]).to_lower() == nome.to_lower() and g.has("uid") and g["uid"] != "":
			g["uid"] = uid
			g["tipo"] = "rete"
			partita._dopo()
			return

# ============================================================================ online: ospite
func _entra_schermo(codice: String) -> void:
	_pulisci()
	_fondo()
	var vb := _scatola(620)
	vb.add_child(Stile.etichetta("Entra in una partita online", 32, Stile.INCHIOSTRO, Stile.titolo()))
	vb.add_child(Stile.paragrafo("Scrivi il codice di 4 lettere che ti ha dato chi ospita e il tuo nome.", 560, 20))
	var lc := LineEdit.new()
	lc.placeholder_text = "CODICE"
	lc.text = codice
	lc.max_length = 4
	vb.add_child(lc)
	var ln := LineEdit.new()
	ln.placeholder_text = "Il tuo nome"
	ln.text = nome_ospite
	ln.max_length = 16
	vb.add_child(ln)
	stato_rete = Stile.paragrafo("", 560, 20)
	vb.add_child(stato_rete)
	var hb := HBoxContainer.new()
	vb.add_child(hb)
	hb.add_child(Stile.bottone("Indietro", _home, 22, 160))
	hb.add_child(Stile.bottone("Entra", func(): _entra(lc.text, ln.text), 24, 200))

func _entra(c: String, nome: String) -> void:
	c = c.strip_edges().to_upper()
	if c.length() != 4:
		stato_rete.text = "Il codice della stanza ha 4 lettere."
		return
	if not rete.web:
		stato_rete.text = "Il gioco online funziona solo nella versione per browser."
		return
	nome_ospite = nome.strip_edges() if nome.strip_edges() != "" else "Viaggiatore"
	stato_rete.text = "Entro nella stanza %s..." % c
	rete.entra(c, nome_ospite)

func _evento_rete(e: Dictionary) -> void:
	match e.get("e"):
		"stanza":
			if qr_lobby:
				qr_lobby.texture = rete.qr_texture(rete.url_tel)
				_testo_tavolo()
			else:
				_testo_stanza()
		"entra":
			if qr_lobby:
				var uid2 := str(e.get("uid", ""))
				var trovato := false
				for o in ospiti:
					if o["uid"] == uid2:
						o["nome"] = str(e.get("nome", ""))
						trovato = true
				if not trovato:
					ospiti.append({"uid": uid2, "nome": str(e.get("nome", "Viaggiatore"))})
				_testo_tavolo()
			elif partita and partita.modo == "tavolo":
				_rientra(str(e.get("uid", "")), str(e.get("nome", "")))
			elif not stanza_attesa.is_empty():
				var uid := str(e.get("uid", ""))
				var gia := false
				for o in ospiti:
					if o["uid"] == uid:
						o["nome"] = str(e.get("nome", ""))
						gia = true
				var posti_online := 0
				for g in stanza_attesa["giocatori"]:
					if g["tipo"] == "rete": posti_online += 1
				if not gia and ospiti.size() < posti_online:
					ospiti.append({"uid": uid, "nome": str(e.get("nome", "Ospite"))})
				_testo_stanza()
		"azione":
			if partita and (partita.modo == "host" or partita.modo == "tavolo"):
				var a = JSON.parse_string(str(e.get("p", "")))
				if a is Dictionary:
					partita.mossa_remota(a, str(e.get("uid", "")))
		"dentro":
			mio_uid = str(e.get("uid", ""))
			if stato_rete:
				stato_rete.text = "Dentro! Aspetto che chi ospita inizi la partita..."
		"stato":
			var d = JSON.parse_string(str(e.get("j", "")))
			if not d is Dictionary or not d.has("s"):
				return
			var st: Dictionary = d["s"]
			if partita == null:
				var posto := -1
				for i in st["giocatori"].size():
					if st["giocatori"][i].get("uid", "") == mio_uid and mio_uid != "":
						posto = i
				if posto < 0:
					if stato_rete:
						stato_rete.text = "La partita è iniziata ma non c’è un posto per te."
					return
				_gioca(st, "ospite", posto)
			else:
				partita.ricevi(st)
		"salvataggio":
			var j := str(e.get("j", ""))
			if j == "":
				if stato_rete: stato_rete.text = "Nessuna partita salvata online."
			else:
				_riprendi(j)
		"errore":
			if stato_rete:
				stato_rete.text = "Errore: " + str(e.get("msg", ""))
