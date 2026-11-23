class_name Partita
extends Control
## Lo schermo di gioco: tabellone (2D o 3D), plancia centrale, giocatori, decisioni, carte in mano.
## modo: "locale" (stesso dispositivo, con o senza computer), "host" (ospita online), "ospite" (online da un altro dispositivo)

signal esci

const TITOLI := {
	"turno": "Gioca una carta dalla mano: scoperta per usarne l’effetto (o una catena), coperta per 2 monete, 1 passo o una carta del Mercato.",
	"catena": "Catena di azioni: attiva, nell’ordine che vuoi, le carte della stessa categoria già giocate in questo round.",
	"coperta": "Carta coperta: scegli il vantaggio.",
	"idea": "Scegli il segnalino Idea.",
	"o": "Scegli uno degli effetti.",
	"paga": "Vuoi pagare?",
	"paga_pv": "Vuoi spendere i Punti Vittoria?",
	"muovi": "Dove vai? Tocca un luogo evidenziato sulla mappa oppure scegli qui.",
	"vai": "Scegli la città da raggiungere.",
	"esplora": "Esplorazione: scegli una tessera (le vedi solo tu) oppure la ricompensa della città.",
	"conversa": "Conversare: parla con un abitante oppure incontra un Viaggiatore Celebre.",
	"extra": "Con lo stesso abitante puoi anche fare amicizia o lasciare una Lettera.",
	"togli_lettera": "Hai usato le tue 3 Lettere: da quale città la riprendi?",
	"esperienza": "Scegli il segnalino Esperienza da mettere sulla Gazzetta.",
	"lettera": "Invia una lettera a un abitante con il tuo segnalino Lettera.",
	"scrivi": "Scrivi nel Diario di Viaggio: scegli lo spazio.",
	"discuti": "Discussione al caffè: scegli dove (paghi le Idee e prendi i PV).",
	"compra": "Scegli la carta Azione Avanzata.",
	"mercato": "Fase del Mercato: prendi gratis una carta Azione Avanzata.",
	"scambia_idea": "Scambia un segnalino Idea.",
	"scambia2": "Quali due Idee cedi?",
	"coperta_muovi": "Gira coperta una carta giocata per muoverti di 2.",
	"riusa": "Quale tessera Esplorazione usi di nuovo?",
	"attiva_tessera": "Quale tessera Esplorazione attivi?",
	"rimuovi_I": "Quale carta di livello I elimini?",
	"lebrun": "Vigée Le Brun: scegli un Dipinto.",
	"percy": "Percy Shelley: vuoi lasciare un’Idea sulla sua carta?",
	"mostro": "Hai preso il controllo di un Mostro di Villa Diodati.",
	"montagu": "Lady Montagu: scegli la ricompensa.",
	"napoleone": "Napoleone: scegli la ricompensa.",
	"ammira": "Perso nell’Ammirazione: vuoi il premio della Gazzetta un’altra volta?",
	"scarta": "Hai più di 8 carte in mano: scartane una (esce dal gioco).",
	"pattuglia": "Paolina Bonaparte: risolvi la carta o elimini la Pattuglia Austriaca?",
}

var s: Dictionary = {}
var modo := "locale"
var rete: Rete = null
var io := 0                 # posto mostrato in basso (mano) su questo dispositivo
var livello_ia := 2
var _attesa_ia := 0.0
var _vista_3d := false
var _ultima_attesa := ""
var _round_salvato := 0

var mappa: Mappa
var mappa3d: Mappa3D
var plancia: Plancia
var mano: Mano
var pannello: PannelloGiocatori
var barra: Control
var l_round: Label
var l_turno: Label
var decisioni: VBoxContainer
var scroll_dec: ScrollContainer
var titolo_dec: Label
var registro: RichTextLabel
var schede: Array = []
var popup: Control = null
var b3d: Button

func avvia(stato: Dictionary, m: String, r: Rete, posto := 0) -> void:
	s = stato
	modo = m
	rete = r
	io = posto
	_costruisci()
	_aggiorna()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Stile.tema()
	get_viewport().size_changed.connect(_disponi)

func _costruisci() -> void:
	var fondo := TextureRect.new()
	fondo.texture = Stile.tex("res://assets/img/plance/tavolo.webp")
	fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.modulate = Color(0.55, 0.5, 0.45)
	add_child(fondo)
	mappa = Mappa.new()
	add_child(mappa)
	mappa.nodo_cliccato.connect(_nodo)
	mappa.citta_cliccata.connect(_mostra_citta)
	mappa3d = Mappa3D.new()
	mappa3d.visible = false
	add_child(mappa3d)
	mappa3d.nodo_cliccato.connect(_nodo)
	mappa3d.citta_cliccata.connect(_mostra_citta)
	plancia = Plancia.new()
	add_child(plancia)
	plancia.scelta.connect(_scegli)
	plancia.ingrandisci.connect(_ingrandisci)
	mano = Mano.new()
	add_child(mano)
	mano.scelta.connect(_scegli)
	mano.ingrandisci.connect(_ingrandisci)
	pannello = PannelloGiocatori.new()
	add_child(pannello)
	pannello.giocatore_scelto.connect(func(p): plancia.giocatore = p; _vista("diari"))
	# barra in alto
	barra = PanelContainer.new()
	barra.add_theme_stylebox_override("panel", Stile.scatola(Color(0.16, 0.11, 0.08, 0.95), Stile.ORO, 0, 2, 10))
	add_child(barra)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	barra.add_child(hb)
	var tit := Stile.etichetta("Timeless Journeys", 30, Stile.ORO_CHIARO, Stile.titolo())
	hb.add_child(tit)
	l_round = Stile.etichetta("", 22, Stile.CARTA, Stile.titolo())
	l_round.custom_minimum_size = Vector2(130, 0)
	hb.add_child(l_round)
	l_turno = Stile.etichetta("", 21, Stile.CARTA)
	l_turno.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l_turno.clip_text = true
	l_turno.custom_minimum_size = Vector2(160, 0)
	hb.add_child(l_turno)
	for v in [["citta", "Città"], ["gazzetta", "Gazzetta"], ["mercato", "Mercato"], ["diari", "Diari"]]:
		var b := Stile.bottone(v[1], _vista.bind(v[0]), 20, 104)
		b.toggle_mode = true
		hb.add_child(b)
		schede.append([v[0], b])
	b3d = Stile.bottone("Vista 3D", _cambia_3d, 20, 110)
	hb.add_child(b3d)
	hb.add_child(Stile.bottone("Punti", _mostra_punti, 20, 80))
	hb.add_child(Stile.bottone("Regole", _regole, 20, 92))
	if rete and rete.web:
		hb.add_child(Stile.bottone("Schermo", func(): rete.schermo_intero(), 20, 100))
	hb.add_child(Stile.bottone("Menu", _menu, 20, 80))
	# colonna delle decisioni
	var pd := PanelContainer.new()
	pd.name = "PannelloDecisioni"
	add_child(pd)
	var vb := VBoxContainer.new()
	pd.add_child(vb)
	titolo_dec = Stile.paragrafo("", 300, 19, Stile.INCHIOSTRO)
	vb.add_child(titolo_dec)
	scroll_dec = ScrollContainer.new()
	scroll_dec.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_dec.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll_dec)
	decisioni = VBoxContainer.new()
	decisioni.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_dec.add_child(decisioni)
	var pr := PanelContainer.new()
	pr.name = "PannelloRegistro"
	pr.add_theme_stylebox_override("panel", Stile.scatola(Color(0.15, 0.11, 0.08, 0.92), Stile.ORO, 8, 2, 8))
	add_child(pr)
	registro = RichTextLabel.new()
	registro.scroll_following = true
	registro.add_theme_color_override("default_color", Stile.CARTA)
	registro.add_theme_font_size_override("normal_font_size", 16)
	pr.add_child(registro)
	_disponi()

func _disponi() -> void:
	if mappa == null:
		return
	var W := size.x if size.x > 0 else get_viewport_rect().size.x
	var H := size.y if size.y > 0 else get_viewport_rect().size.y
	var top := 58.0
	barra.position = Vector2.ZERO
	barra.size = Vector2(W, top)
	var np: int = s["giocatori"].size() if not s.is_empty() else 2
	var hp := pannello.altezza_per(np)
	var pd: Control = get_node("PannelloDecisioni")
	var pr: Control = get_node("PannelloRegistro")
	var wr := clampf(W * 0.215, 330, 470)
	if H > W * 1.1:
		# verticale (iPad in piedi): mappa e colonna in alto, plancia larga in mezzo, mano in basso
		var hb2 := clampf(H * 0.15, 220, 300)
		var hpl := minf((W - 12) / 1.75 + 96, (H - top - hb2) * 0.55)
		var h1 := H - top - hb2 - hpl - 12
		var wl2 := minf(h1 * 1080.0 / 1825.0, W * 0.45)
		mappa.position = Vector2(0, top)
		mappa.size = Vector2(wl2, h1)
		var wr2 := W - wl2 - 8
		pannello.position = Vector2(wl2 + 4, top + 4)
		pannello.size = Vector2(wr2, hp)
		var resto2 := h1 - hp - 10
		var hreg2 := clampf(resto2 * 0.3, 80, 200)
		pd.position = Vector2(wl2 + 4, top + hp + 6)
		pd.size = Vector2(wr2, resto2 - hreg2 - 4)
		pr.position = Vector2(wl2 + 4, top + hp + 6 + resto2 - hreg2)
		pr.size = Vector2(wr2, hreg2)
		plancia.position = Vector2(6, top + h1 + 6)
		plancia.size = Vector2(W - 12, hpl)
		mano.position = Vector2(0, H - hb2)
		mano.size = Vector2(W, hb2)
		wr = wr2
	else:
		var hb := clampf(H * 0.26, 220, 310)
		var wl := minf(W * 0.31, (H - top) * 1080.0 / 1825.0 + 6)
		mappa.position = Vector2(0, top)
		mappa.size = Vector2(wl, H - top)
		plancia.position = Vector2(wl + 6, top + 6)
		plancia.size = Vector2(W - wl - wr - 12, H - top - hb - 12)
		mano.position = Vector2(wl + 4, H - hb)
		mano.size = Vector2(W - wl - 4, hb)
		pannello.position = Vector2(W - wr, top + 4)
		pannello.size = Vector2(wr - 4, hp)
		var resto := H - hb - top - hp - 14
		var hreg := clampf(resto * 0.3, 90, 220)
		pd.position = Vector2(W - wr, top + hp + 6)
		pd.size = Vector2(wr - 4, resto - hreg - 6)
		pr.position = Vector2(W - wr, H - hb - hreg - 4)
		pr.size = Vector2(wr - 4, hreg)
	mappa3d.position = mappa.position
	mappa3d.size = mappa.size
	titolo_dec.custom_minimum_size = Vector2(wr - 40, 0)
	if popup:
		popup.size = Vector2(W, H)

# ============================================================================ ciclo
func chi_deve() -> int:
	if s.is_empty() or s["fine"] or s["attesa"].is_empty():
		return -1
	return int(s["attesa"]["chi"])

func _tocca_a_me(chi: int) -> bool:
	if chi < 0:
		return false
	var t: String = s["giocatori"][chi]["tipo"]
	if modo == "ospite":
		return chi == io
	return t == "umano"

func _process(d: float) -> void:
	if s.is_empty() or s["fine"] or modo == "ospite":
		return
	var chi := chi_deve()
	if chi < 0:
		return
	if s["giocatori"][chi]["tipo"] == "ia":
		_attesa_ia -= d
		if _attesa_ia <= 0:
			var tipo: String = s["attesa"]["tipo"]
			var id := IA.scegli(s, livello_ia)
			if id != "":
				_applica(id)
			_attesa_ia = 0.9 if tipo == "turno" else 0.45
	else:
		_attesa_ia = 0.6

func _scegli(id: String) -> void:
	var chi := chi_deve()
	if not _tocca_a_me(chi):
		return
	if modo == "ospite":
		rete.azione("m", {"id": id, "p": chi, "m": int(s["mossa"]), "a": s["attesa"].get("tipo", "")})
		return
	_applica(id)

func _applica(id: String) -> void:
	var prima_round: int = int(s["round"])
	var prima_log: int = s["log"].size()
	if not Motore.applica(s, id):
		return
	_suoni(prima_log)
	_dopo(prima_round != int(s["round"]))

func _suoni(prima_log: int) -> void:
	if rete == null:
		return
	var chi := chi_deve()
	if chi >= 0 and _tocca_a_me(chi) and s["attesa"].get("tipo", "") == "turno" and s["giocatori"].size() > 1:
		rete.suono("tocca")
	elif s["log"].size() != prima_log:
		rete.suono("carta")

func _dopo(round_nuovo := false) -> void:
	if modo == "host" and rete:
		rete.stato({"s": s})
	_salva(round_nuovo)
	_aggiorna()
	if s["fine"]:
		_mostra_punti()
		if rete:
			rete.suono("arrivo")

## mossa arrivata da un ospite online
func mossa_remota(a: Dictionary, uid: String) -> void:
	if modo != "host":
		return
	var p: int = int(a.get("p", -1))
	if p != chi_deve() or p < 0:
		return
	if s["giocatori"][p]["tipo"] != "rete" or s["giocatori"][p].get("uid", "") != uid:
		return
	_applica(str(a.get("id", "")))

## stato ricevuto da chi ospita
func ricevi(stato: Dictionary) -> void:
	var prima: int = s.get("log", []).size()
	s = stato
	if rete and s["log"].size() != prima:
		rete.suono("tocca" if chi_deve() == io and s["attesa"].get("tipo", "") == "turno" else "carta")
	_aggiorna()
	if s["fine"] and popup == null:
		_mostra_punti()

func _salva(round_nuovo: bool) -> void:
	if rete == null or modo == "ospite":
		return
	if s["fine"]:
		rete.salva("timeless_partita", "")
		return
	var dati := JSON.stringify({"s": s, "modo": modo, "io": io})
	rete.salva("timeless_partita", dati)
	if round_nuovo or int(s["round"]) != _round_salvato:
		_round_salvato = int(s["round"])
		rete.salva_remoto(dati)
		if modo == "host":
			rete.salva_stanza(dati)

# ============================================================================ interfaccia
func _aggiorna() -> void:
	if s.is_empty():
		return
	var chi := chi_deve()
	var mio := _tocca_a_me(chi)
	# in partita sullo stesso dispositivo la mano mostrata è quella di chi deve decidere
	if modo != "ospite" and mio:
		io = chi
	var opz: Array = Motore.opzioni(s) if mio else []
	var tipo: String = s["attesa"].get("tipo", "") if mio else ""
	l_round.text = "Round %s" % ["", "I", "II", "III", "IV", "V"][clampi(int(s["round"]), 1, 5)]
	if s["fine"]:
		l_turno.text = "Fine del Grand Tour"
	elif chi >= 0:
		var gg: Dictionary = s["giocatori"][chi]
		var fase := {"azione": "", "viaggiatori": " (fine del round)"}.get(s["fase"], "")
		l_turno.text = "Tocca a %s%s" % [gg["nome"], fase]
	# evidenziazioni sulla mappa
	var ev := {}
	for o in opz:
		if o.has("nodo") and not o.has("disc") and not o.has("lato"):
			ev[o["nodo"]] = o["id"]
	if tipo == "turno" or tipo == "catena":
		ev = {}
		for o in opz:
			if o["id"] == "byron":
				ev[o["nodo"]] = "byron"
	mappa.scelta_citta = plancia.citta
	mappa.aggiorna(s, ev)
	if mappa3d.visible:
		mappa3d.aggiorna(s, ev)
	# vista automatica secondo la decisione
	var chiave := "%s:%s:%s" % [s["attesa"].get("tipo", ""), s["attesa"].get("chi", ""), s["mossa"]]
	if mio and chiave != _ultima_attesa:
		_ultima_attesa = chiave
		_vista_automatica(tipo, opz)
	plancia.aggiorna(s, opz)
	mano.aggiorna(s, io, opz, tipo)
	pannello.aggiorna(s)
	for sc in schede:
		sc[1].button_pressed = sc[0] == plancia.vista
	# decisioni
	for c in decisioni.get_children():
		c.queue_free()
	var larg := maxf(220, scroll_dec.size.x - 16)
	if s["fine"]:
		titolo_dec.text = "Il viaggio è finito."
		decisioni.add_child(Stile.bottone("Punteggio finale", _mostra_punti, 20))
	elif not mio:
		if chi >= 0:
			var gg2: Dictionary = s["giocatori"][chi]
			titolo_dec.text = "%s sta decidendo%s..." % [gg2["nome"], " (computer)" if gg2["tipo"] == "ia" else (" (online)" if gg2["tipo"] == "rete" else "")]
	else:
		titolo_dec.text = "%s: %s" % [s["giocatori"][chi]["nome"], TITOLI.get(tipo, "Scegli.")]
		if tipo == "mercato":
			titolo_dec.text += " Livello massimo: %s." % ["", "I", "II", "III"][int(s["attesa"]["liv"])]
		for o in opz:
			var id: String = o["id"]
			if id.begins_with("su:") or id.begins_with("giu:"):
				continue
			var b := Stile.bottone_lungo(o["testo"], _scegli.bind(id), larg)
			decisioni.add_child(b)
	# registro
	var righe: Array = s["log"].slice(-60)
	registro.text = "\n".join(righe)

func _vista_automatica(tipo: String, opz: Array) -> void:
	var p := chi_deve()
	match tipo:
		"esplora", "conversa", "extra", "discuti", "lettera":
			var c := ""
			for o in opz:
				if o.has("citta"):
					c = o["citta"]
					break
			if tipo == "esplora":
				c = s["attesa"]["citta"]
			if c == "" and Dati.e_citta(s["giocatori"][p]["pos"]):
				c = s["giocatori"][p]["pos"]
			if c != "":
				plancia.citta = c
			if tipo == "conversa":
				var ha_vg := false
				for o in opz:
					if String(o["id"]).begins_with("vg:"):
						ha_vg = true
				plancia.vista = "citta"
			else:
				plancia.vista = "citta"
		"esperienza":
			plancia.vista = "gazzetta"
		"compra", "mercato":
			plancia.vista = "mercato"
		"scrivi", "percy":
			plancia.giocatore = p
			plancia.vista = "diari"
		"turno":
			if Dati.e_citta(s["giocatori"][p]["pos"]):
				plancia.citta = s["giocatori"][p]["pos"]
			if plancia.vista == "diari":
				plancia.giocatore = p

func _vista(v: String) -> void:
	plancia.vista = v
	if v == "diari" and chi_deve() >= 0 and _tocca_a_me(chi_deve()) and plancia.giocatore >= s["giocatori"].size():
		plancia.giocatore = chi_deve()
	_aggiorna()

func _mostra_citta(c: String) -> void:
	plancia.citta = c
	plancia.vista = "citta"
	_aggiorna()

func _nodo(n: String) -> void:
	var chi := chi_deve()
	if not _tocca_a_me(chi):
		if Dati.e_citta(n):
			_mostra_citta(n)
		return
	for o in Motore.opzioni(s):
		if o.get("nodo", "") == n and not o.has("disc"):
			_scegli(o["id"])
			return
	if Dati.e_citta(n):
		_mostra_citta(n)

func _cambia_3d() -> void:
	_vista_3d = not _vista_3d
	mappa3d.visible = _vista_3d
	mappa.visible = not _vista_3d
	b3d.text = "Vista 2D" if _vista_3d else "Vista 3D"
	if _vista_3d:
		mappa3d.aggiorna(s, mappa.evidenzia)

# ============================================================================ finestre
func _chiudi_popup() -> void:
	if popup:
		popup.queue_free()
		popup = null

func _finestra(larghezza: float, altezza: float) -> VBoxContainer:
	_chiudi_popup()
	popup = Control.new()
	popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(popup)
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.6)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _chiudi_popup())
	popup.add_child(velo)
	var pc := PanelContainer.new()
	var W := get_viewport_rect().size
	var w := minf(larghezza, W.x - 40)
	var h := minf(altezza, W.y - 40)
	pc.position = (W - Vector2(w, h)) / 2
	pc.size = Vector2(w, h)
	popup.add_child(pc)
	var vb := VBoxContainer.new()
	pc.add_child(vb)
	return vb

func _ingrandisci(path: String) -> void:
	var tx := Stile.tex(path)
	if tx == null:
		return
	var W := get_viewport_rect().size
	var h := minf(W.y * 0.8, 760)
	var w := h * tx.get_width() / tx.get_height()
	if w > W.x * 0.8:
		w = W.x * 0.8
		h = w * tx.get_height() / tx.get_width()
	var vb := _finestra(w + 40, h + 90)
	var tr := TextureRect.new()
	tr.texture = tx
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(w, h)
	tr.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(tr)
	vb.add_child(Stile.bottone("Chiudi", _chiudi_popup, 20))

func _mostra_punti() -> void:
	var pt: Array = s["punteggi"] if s["fine"] else Motore.punteggi(s)
	var vb := _finestra(1100, 640)
	var t := "Punteggio finale" if s["fine"] else "Punteggio se la partita finisse adesso"
	vb.add_child(Stile.etichetta(t, 34, Stile.INCHIOSTRO, Stile.titolo()))
	if s["fine"]:
		var nomi: Array = []
		for p in s["vincitori"]:
			nomi.append(s["giocatori"][int(p)]["nome"])
		vb.add_child(Stile.etichetta("Vince " + " e ".join(nomi) + "!", 28, Color("7a2a14"), Stile.titolo()))
		if s["solo"]:
			var tot: int = pt[0]["totale"]
			var giudizio := "Il Turista Smarrito"
			if tot > 110: giudizio = "Una Leggenda del Grand Tour"
			elif tot > 80: giudizio = "L’Illustre Grand Tourist"
			elif tot > 40: giudizio = "L’Esploratore Curioso"
			vb.add_child(Stile.etichetta("%d PV: %s" % [tot, giudizio], 26, Stile.INCHIOSTRO, Stile.titolo()))
	var gr := GridContainer.new()
	gr.columns = pt.size() + 1
	gr.add_theme_constant_override("h_separation", 26)
	gr.add_theme_constant_override("v_separation", 6)
	vb.add_child(gr)
	gr.add_child(Stile.etichetta("", 20))
	for p in pt.size():
		var l := Stile.etichetta(s["giocatori"][p]["nome"], 21, Stile.colore(s["giocatori"][p]["colore"]).darkened(0.35), Stile.grassetto())
		l.custom_minimum_size = Vector2(130, 0)
		gr.add_child(l)
	var voci := [["tracciato", "Tracciato dei PV"], ["esplorazioni", "Tessere Esplorazione"], ["diari", "Diari di Viaggio"],
		["carte", "Carte Azione Avanzata"], ["esperienze", "Affinità Elettive"], ["maggioranze", "Maggioranze Gazzetta"],
		["dipinti", "Dipinti di Le Brun"], ["pattuglie", "Pattuglie Austriache"], ["totale", "Totale"]]
	for v in voci:
		var tutti_zero := true
		for p in pt.size():
			if int(pt[p][v[0]]) != 0: tutti_zero = false
		if tutti_zero and v[0] in ["dipinti", "pattuglie"]:
			continue
		gr.add_child(Stile.etichetta(v[1], 21, Stile.INCHIOSTRO, Stile.grassetto() if v[0] == "totale" else Stile.testo()))
		for p in pt.size():
			gr.add_child(Stile.etichetta(str(pt[p][v[0]]), 22 if v[0] != "totale" else 26, Stile.INCHIOSTRO, Stile.grassetto() if v[0] == "totale" else Stile.testo()))
	var hb := HBoxContainer.new()
	vb.add_child(hb)
	hb.add_child(Stile.bottone("Chiudi", _chiudi_popup, 22, 160))
	if s["fine"]:
		hb.add_child(Stile.bottone("Torna al menu", func(): esci.emit(), 22, 200))

func _regole() -> void:
	var vb := _finestra(1200, 900)
	vb.add_child(Stile.etichetta("Come si gioca", 32, Stile.INCHIOSTRO, Stile.titolo()))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.custom_minimum_size = Vector2(minf(1120, get_viewport_rect().size.x - 120), 0)
	t.add_theme_font_size_override("normal_font_size", 20)
	t.add_theme_font_size_override("bold_font_size", 20)
	t.text = Regole.TESTO
	sc.add_child(t)
	vb.add_child(Stile.bottone("Chiudi", _chiudi_popup, 22, 160))

func _menu() -> void:
	var vb := _finestra(560, 360)
	vb.add_child(Stile.etichetta("Menu", 32, Stile.INCHIOSTRO, Stile.titolo()))
	var testo := "La partita è salvata a ogni mossa: dal menu principale puoi riprenderla." if modo != "ospite" else "Sei ospite in una partita online."
	vb.add_child(Stile.paragrafo(testo, 500, 20))
	var hb := HBoxContainer.new()
	vb.add_child(hb)
	hb.add_child(Stile.bottone("Continua", _chiudi_popup, 22, 160))
	hb.add_child(Stile.bottone("Esci al menu", func(): esci.emit(), 22, 200))
