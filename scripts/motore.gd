class_name Motore
extends RefCounted
## Regole di Timeless Journeys: The Italian Grand Tour (regolamento italiano), con il solitario degli Automi
## e le espansioni Napoleone, Una Notte di Terrore a Villa Diodati e I Romantici.
##
## Lo stato è un Dictionary JSON puro (si salva e si manda in rete così com'è). Tutto avanza con:
##   s = Motore.nuova(opzioni)       nuova partita
##   Motore.opzioni(s) -> Array      le scelte possibili della decisione in attesa ({id, testo, ...})
##   Motore.applica(s, id)           applica una scelta e fa avanzare il gioco fino alla prossima decisione
## s["attesa"]["chi"] è il posto del giocatore che deve decidere.

const COSTO_LIVELLO := {1: 0, 2: 2, 3: 5}

# ============================================================================ numeri casuali (nello stato)
static func _rnd(s: Dictionary) -> int:
	var x: int = int(s["rng"])
	x ^= (x << 13) & 0xFFFFFFFF
	x ^= (x >> 17)
	x ^= (x << 5) & 0xFFFFFFFF
	x &= 0xFFFFFFFF
	if x == 0:
		x = 2463534242
	s["rng"] = x
	return x

static func _rand(s: Dictionary, n: int) -> int:
	return _rnd(s) % maxi(1, n)

static func _mescola(s: Dictionary, a: Array) -> Array:
	for i in range(a.size() - 1, 0, -1):
		var j := _rand(s, i + 1)
		var t = a[i]
		a[i] = a[j]
		a[j] = t
	return a

# ============================================================================ carte
static func info(id: String) -> Dictionary:
	var p := id.split(":")
	var D := Dati.d()
	if p[0] == "a":
		var c: Dictionary = D["avanzate"][p[1]]
		return {"tipo": "a", "num": int(p[1]), "cat": c["cat"], "cats": [c["cat"]], "eff": c["eff"], "liv": int(c["liv"]),
			"pv": int(c["pv"]), "cond": c["cond"], "img": "res://assets/img/carte/av_%02d.webp" % int(p[1])}
	if p[0] == "b":
		var col := p[1]
		var k := int(p[2])
		var b: Dictionary = D["base"][k]
		var eff: Array = b["eff"]
		if int(b["img"]) == 5:
			eff = D["idea_colore"][col]
		return {"tipo": "b", "num": 0, "cat": b["cat"], "cats": [b["cat"]], "eff": eff, "liv": 0, "pv": 0, "cond": null,
			"img": "res://assets/img/carte/base_%s_%d.webp" % [col, int(b["img"])], "nome": b["nome"]}
	# carta Andersen
	var k2 := int(p[1])
	var an: Dictionary = D["andersen"][k2]
	return {"tipo": "n", "num": 0, "cat": an["cat"], "cats": an.get("cats", [an["cat"]]), "eff": an["eff"], "liv": 0, "pv": 0, "cond": null,
		"img": "res://assets/img/espansioni/andersen_%d.webp" % k2,
		"nome": an["nome"]}

## «a» con l'articolo: il pittore -> al pittore
static func a_chi(n: String) -> String:
	for art in [["il ", "al "], ["lo ", "allo "], ["la ", "alla "], ["l’", "all’"]]:
		if n.begins_with(art[0]):
			return art[1] + n.substr(art[0].length())
	return "a " + n

static func nome_carta(id: String) -> String:
	var i := info(id)
	if i["tipo"] == "a":
		return "Carta %d (%s, livello %s)" % [i["num"], Dati.CATEGORIE[i["cat"]], ["", "I", "II", "III"][i["liv"]]]
	if i["tipo"] == "n":
		var cn: Array = []
		for c in i["cats"]:
			cn.append(Dati.CATEGORIE[c])
		return "Carta Andersen (%s)" % " e ".join(cn)
	return "%s (%s)" % [i["nome"], Dati.CATEGORIE[i["cat"]]]

# ============================================================================ testi degli effetti
static func testo_eff(eff) -> String:
	if eff is Array:
		var parti: Array = []
		for e in eff:
			parti.append(testo_eff(e))
		return " + ".join(parti) if parti.size() else "nessun effetto"
	var e: Dictionary = eff
	if e.has("o"):
		var alt: Array = []
		for r in e["o"]:
			alt.append(testo_eff(r))
		return " oppure ".join(alt)
	if e.has("monete"): return "+%d monet%s" % [int(e["monete"]), "a" if int(e["monete"]) == 1 else "e"]
	if e.has("pv"): return "+%d PV" % int(e["pv"])
	if e.has("idea"): return "1 Idea a scelta" if e["idea"] == "*" else "1 Idea " + e["idea"]
	if e.has("idee_diverse"): return "%d Idee diverse" % int(e["idee_diverse"])
	if e.has("muovi"):
		var t := "Muovi di %d" % int(e["muovi"])
		if int(e.get("sconto", 0)) > 0:
			t += " (sconto %d)" % int(e["sconto"])
		return t
	if e.has("esplora"): return "Esplora" if int(e["esplora"]) == 1 else "Esplora %d volte" % int(e["esplora"])
	if e.has("conversa"): return "Conversa" if int(e["conversa"]) == 1 else "%d Conversazioni" % int(e["conversa"])
	if e.has("lettera"):
		var n := int(e["lettera"])
		return "Invia una lettera" if n == 1 else "Invia %d lettere%s" % [n, " diverse" if e.get("diverse", false) else ""]
	if e.has("lettera_ovunque"): return "Lettera a un abitante senza tua Lettera"
	if e.has("scrivi"):
		var n2 := int(e["scrivi"])
		return "Scrivi nel Diario" if n2 == 1 else "Scrivi %d volte%s" % [n2, " in Diari diversi" if e.get("diversi", false) else ""]
	if e.has("discuti"): return "Discuti al caffè" + (" in qualsiasi città" if e.get("ovunque", false) else "") + (" con 1 Idea in meno" if int(e.get("sconto_idea", 0)) > 0 else "")
	if e.has("compra"):
		var t2 := "Compra una carta"
		if int(e.get("sconto", 0)) > 0: t2 += " (sconto %d)" % int(e["sconto"])
		if e.get("risolvi", false): t2 += " e usala subito"
		return t2
	if e.has("compra_max"): return "Carta gratis dal Mercato"
	if e.has("paga"): return "paga %d monet%s: %s" % [int(e["paga"]), "a" if int(e["paga"]) == 1 else "e", testo_eff(e["poi"])]
	if e.has("paga_pv"): return "perdi %d PV: %s" % [int(e["paga_pv"]), testo_eff(e["poi"])]
	if e.has("scambia_idea"): return "Scambia 1 Idea con un’altra o con 3 monete"
	if e.has("scambia2"): return "Scambia 2 Idee con 2 a scelta"
	if e.has("coperta_muovi"): return "Gira coperta una carta giocata: muovi di 2"
	if e.has("vai"): return "Vai a %s o %s" % [e["vai"][0], e["vai"][1]]
	if e.has("riusa_esplorazione"): return "Riusa una tessera Esplorazione"
	if e.has("attiva_esplorazione"): return "Attiva una tessera Esplorazione"
	if e.has("rimuovi_I"): return "Elimina una carta di livello I: " + testo_eff(e["poi"])
	return "?"

# ============================================================================ nuova partita
## opz: {giocatori: [{nome, colore, tipo}], solo: bool, seme, gazzetta: "A".."D" o "", viaggiatori: [id] o
##       modo_viaggiatori: "intro"|"A".."D"|"caso", favori_intro: bool, settima: [bool], esp: {napoleone, diodati, romantici}}
static func nuova(opz: Dictionary) -> Dictionary:
	var D := Dati.d()
	var s := {"v": 1, "rng": int(opz.get("seme", 12345)) & 0xFFFFFFFF, "log": [], "mossa": 0, "fine": false}
	if int(s["rng"]) == 0:
		s["rng"] = 777
	for i in 5:
		_rnd(s)
	var gs: Array = opz.get("giocatori", [])
	var solo: bool = opz.get("solo", false)
	if solo:
		gs = [gs[0]]
	var n := gs.size()
	s["n"] = n
	s["solo"] = solo
	var nn := 3 if solo else n   # numero di giocatori per la preparazione
	s["nn"] = nn
	var esp: Dictionary = opz.get("esp", {})
	s["esp"] = {"napoleone": esp.get("napoleone", false), "diodati": esp.get("diodati", false), "romantici": esp.get("romantici", false)}
	s["round"] = 1
	s["primo"] = 0
	# Gazzetta
	var gz: String = opz.get("gazzetta", "")
	if gz == "":
		gz = ["A", "B", "C", "D"][_rand(s, 4)]
	s["gazzetta"] = gz
	s["gaz"] = [[null, null, null, null, null], [null, null, null, null, null], [null, null, null, null, null]]
	# Viaggiatori
	var vg: Array = opz.get("viaggiatori", [])
	if vg.size() != 3:
		var modo: String = opz.get("modo_viaggiatori", "intro")
		var pool: Array = []
		for k in D["viaggiatori"]:
			var esp_v: String = D["viaggiatori"][k].get("esp", "")
			if esp_v == "" or s["esp"].get(esp_v, false):
				pool.append(k)
		if modo == "intro":
			vg = D["intro"].duplicate()
		elif D["periodi"].has(modo):
			vg = D["periodi"][modo].duplicate()
		else:
			vg = _mescola(s, pool).slice(0, 3)
		vg = _mescola(s, vg)
	s["viaggiatori"] = vg
	# città: tessere esplorazione, favori, amici
	s["citta"] = {}
	for c in D["citta"]:
		var tiles: Array = []
		for i in 6:
			tiles.append("%s_%d" % [c, i])
		_mescola(s, tiles)
		var quante := nn + 1
		if solo and (c == "Torino" or c == "Palermo"):
			quante = 2
		s["citta"][c] = {"esplora": tiles.slice(0, quante), "favore": "", "amico": -1,
			"lettere": [[], []], "caffe": [[null, null], [null, null]], "pattuglia": ""}
	var f1: Array = []
	var f2: Array = []
	var favori: Array = D["favori_intro"] if opz.get("favori_intro", false) else D["favori"].keys()
	for k in favori:
		if int(D["favori_livello"][k]) == 1: f1.append(k)
		else: f2.append(k)
	_mescola(s, f1)
	_mescola(s, f2)
	for c in D["citta"]:
		if int(D["plance"][c]["favore"]) == 1:
			s["citta"][c]["favore"] = f1.pop_back()
		else:
			s["citta"][c]["favore"] = f2.pop_back()
	var amici_n: int = {1: 3, 2: 3, 3: 4, 4: 6, 5: 7}[nn]
	var con_amico: Array = D["citta"].slice(1)
	_mescola(s, con_amico)
	for c in con_amico.slice(0, amici_n):
		s["citta"][c]["amico"] = _rand(s, 2)
	# mercato
	s["mazzi"] = {"1": [], "2": [], "3": []}
	for k in D["avanzate"]:
		var a: Dictionary = D["avanzate"][k]
		for j in int(a["copie"]):
			s["mazzi"][str(int(a["liv"]))].append("a:%s:%d" % [k, j])
	s["mercato"] = {"1": [], "2": [], "3": []}
	for l in ["1", "2", "3"]:
		_mescola(s, s["mazzi"][l])
	_rifornisci(s)
	# diari
	var da: Array = []
	var db: Array = []
	for d0 in D["diari"]["A"]: da.append("A_" + d0[0])
	for d1 in D["diari"]["B"]: db.append("B_" + d1[0])
	_mescola(s, da)
	_mescola(s, db)
	# giocatori
	s["giocatori"] = []
	var usati := {}
	for i in n:
		var g: Dictionary = gs[i]
		var col: String = g.get("colore", D["colori"][i])
		usati[col] = true
		var mano: Array = []
		for k in 7:
			if k == 6 and not (opz.get("settima", []).size() <= i or opz["settima"][i]):
				continue
			mano.append("b:%s:%d" % [col, k])
		var gg := {"nome": g.get("nome", "Giocatore %d" % (i + 1)), "colore": col, "tipo": g.get("tipo", "umano"),
			"uid": g.get("uid", ""), "pos": "Torino", "monete": 2, "pv": 5,
			"idee": {"Arte": 0, "Storia": 0, "Filosofia": 0, "Scienza": 0},
			"mano": mano, "area": [], "tessere": [], "amici": [], "lettere": 3, "caffe": 6,
			"esp": ["duello", "notte", "ammirazione", "affinita", "affinita"],
			"diari": [{"id": da[i], "slot": [null, null, null, null, null, null, null, null]},
				{"id": db[i], "slot": [null, null, null, null, null, null, null, null]}],
			"dipinti": [], "pattuglie": [], "soldati": 0, "mostri": {}, "andersen": false,
			"bloccati": [], "ammirati": [], "fatto": {}, "avanzate_round": 0, "percy": []}
		s["giocatori"].append(gg)
	# monete iniziali (in ordine dal primo giocatore)
	for i in n:
		if nn == 2:
			s["giocatori"][i]["monete"] = 1 if i == 0 else 2
		else:
			s["giocatori"][i]["monete"] = 1 if i <= 1 else 2
	# Automi
	s["automi"] = []
	s["fallite"] = []
	s["automa_espl"] = []
	if solo:
		var liberi: Array = []
		for c in D["colori"]:
			if not usati.has(c) and c != "grigio":
				liberi.append(c)
		for k in 2:
			var col2: String = liberi[k]
			var mazzo: Array = []
			for j in 6:
				mazzo.append("b:%s:%d" % [col2, j])
			s["automi"].append({"nome": "Automa " + ["Alfa", "Beta"][k], "colore": col2, "pos": "Torino", "mazzo": mazzo,
				"giocate": [], "esp": _mescola(s, ["duello", "notte", "ammirazione", "affinita", "affinita"]),
				"lettere": 3, "caffe": 6})
	# Vigée Le Brun
	s["lebrun"] = {"mazzo": [], "scoperti": []}
	if vg.has("le_brun"):
		for t in 5:
			for c3 in (2 if nn == 2 else 3):
				s["lebrun"]["mazzo"].append(t)
		_mescola(s, s["lebrun"]["mazzo"])
	# espansioni
	s["battaglia"] = {"mazzo": [], "attuale": ""}
	if s["esp"]["napoleone"]:
		var pt: Array = _mescola(s, D["pattuglie"].duplicate())
		var k3 := 0
		for c in D["citta"]:
			s["citta"][c]["pattuglia"] = pt[k3]
			k3 += 1
		var ba: Array = []
		var bb: Array = []
		for k in D["battaglie"]:
			if k.begins_with("A"): ba.append(k)
			else: bb.append(k)
		_mescola(s, ba)
		_mescola(s, bb)
		s["battaglia"]["mazzo"] = ba.slice(0, 3) + bb.slice(0, 2)
		s["battaglia"]["attuale"] = s["battaglia"]["mazzo"].pop_front()
	s["villa"] = {"V": -1, "A": -1, "I": -1, "F": -1}   # -1 = nella Villa, altrimenti posto del giocatore
	s["andersen"] = [-1, -1, -1, -1]   # -1 libera, altrimenti chi l'ha usata nel round
	# primo round
	s["pila"] = []
	s["coda"] = []
	s["attesa"] = {}
	s["catena"] = {}
	_inizio_round(s)
	_log(s, "Inizia il Grand Tour. Gazzetta %s. Viaggiatori: %s." % [gz, ", ".join(vg.map(func(x): return D["viaggiatori"][x]["nome"]))])
	avanza(s)
	return s

static func _rifornisci(s: Dictionary) -> void:
	var quante := 3 if int(s["nn"]) >= 4 else 2
	for l in ["1", "2", "3"]:
		for c in s["mercato"][l]:
			s["mazzi"][l].append(c)
		s["mercato"][l] = []
		for k in quante:
			if s["mazzi"][l].size():
				s["mercato"][l].append(s["mazzi"][l].pop_front())

static func _log(s: Dictionary, t: String) -> void:
	s["log"].append(t)
	if s["log"].size() > 300:
		s["log"] = s["log"].slice(-250)

# ============================================================================ consultazione
static func g(s: Dictionary, p: int) -> Dictionary:
	return s["giocatori"][p]

static func nome(s: Dictionary, p: int) -> String:
	if p >= 100:
		return s["automi"][p - 100]["nome"]
	return s["giocatori"][p]["nome"]

## città dove si trova ogni viaggiatore nel round attuale: [[id, città], ...] (colonne della Gazzetta)
static func viaggiatori_pos(s: Dictionary) -> Array:
	var D := Dati.d()
	var r := clampi(int(s["round"]), 1, 5) - 1
	var out: Array = []
	for col in 3:
		out.append([s["viaggiatori"][col], D["gazzetta"][s["gazzetta"]]["citta"][col][r]])
	return out

static func citta_di(s: Dictionary, vid: String) -> String:
	for v in viaggiatori_pos(s):
		if v[0] == vid:
			return v[1]
	return ""

static func presso(s: Dictionary, p: int, vid: String) -> bool:
	var c := citta_di(s, vid)
	return c != "" and g(s, p)["pos"] == c

static func spazio_disponibile(s: Dictionary, col: int, r: int) -> bool:
	var mi: int = int(Dati.d()["gazzetta_min"][r][col])
	return int(s["nn"]) >= mi and s["gaz"][col][r] == null

static func categorie_round(s: Dictionary, p: int) -> Array:
	var cats: Array = []
	for a in g(s, p)["area"]:
		var ks: Array = ["giu"] if a["giu"] else info(a["id"])["cats"]
		for k in ks:
			if not cats.has(k):
				cats.append(k)
	return cats

static func idee_scritte(gg: Dictionary) -> int:
	var t := 0
	for d in gg["diari"]:
		for i in 6:
			if d["slot"][i] != null:
				t += 1
	return t

static func diario_def(id: String) -> Array:
	var parti := id.split("_")
	for d in Dati.d()["diari"][parti[0]]:
		if d[0] == parti[1]:
			return d
	return []

## genere richiesto da uno spazio del diario (0-5), "citta" (6) o "amico" (7)
static func slot_richiesta(id: String, k: int) -> String:
	var d := diario_def(id)
	if k < 3: return d[1]
	if k < 6: return d[2]
	if k == 6: return "citta:" + d[0]
	return "amico"

# ============================================================================ motore delle decisioni
static func avanza(s: Dictionary) -> void:
	var guardia := 0
	while not s["fine"] and s["attesa"].is_empty():
		guardia += 1
		if guardia > 5000:
			push_error("ciclo infinito nel motore")
			return
		if not s["pila"].is_empty():
			_passo_pila(s)
			continue
		if not s["coda"].is_empty():
			_passo_coda(s)
			continue
		_passo_flusso(s)

static func _attendi(s: Dictionary, chi: int, tipo: String, extra := {}) -> void:
	var a := {"chi": chi, "tipo": tipo}
	a.merge(extra)
	s["attesa"] = a

## porta in pila una sequenza di effetti per il giocatore p
static func _spingi(s: Dictionary, p: int, eff: Array, fonte := "") -> void:
	if eff.is_empty():
		return
	s["pila"].append({"chi": p, "eff": eff.duplicate(true), "fonte": fonte})

static func _passo_pila(s: Dictionary) -> void:
	var fr: Dictionary = s["pila"].back()
	if fr["eff"].is_empty():
		s["pila"].pop_back()
		return
	var e: Dictionary = fr["eff"].pop_front()
	_effetto(s, int(fr["chi"]), e)

# ---------------------------------------------------------------------------- flusso del round
static func _sequenza(s: Dictionary) -> Array:
	var seq: Array = []
	if s["solo"]:
		return [0, 100, 101]
	for k in int(s["n"]):
		seq.append((int(s["primo"]) + k) % int(s["n"]))
	return seq

static func _inizio_round(s: Dictionary) -> void:
	s["fase"] = "azione"
	s["seq"] = _sequenza(s)
	s["idx"] = 0
	s["giocate"] = {}
	for a in s["seq"]:
		s["giocate"][str(a)] = 0
	s["turno_iniziato"] = false
	for gg in s["giocatori"]:
		gg["avanzate_round"] = 0
		gg["ammirati"] = []
		gg["percy"] = []
		gg["andersen"] = false
	for k in 4:
		s["andersen"][k] = -1
	if not s["lebrun"]["mazzo"].is_empty() or not s["lebrun"]["scoperti"].is_empty():
		s["lebrun"]["scoperti"] = []
		var quanti := 2 if int(s["nn"]) == 2 else 3
		for k in quanti:
			if s["lebrun"]["mazzo"].size():
				s["lebrun"]["scoperti"].append(s["lebrun"]["mazzo"].pop_front())
	if s["solo"]:
		for au in s["automi"]:
			for c in au["giocate"]:
				au["mazzo"].append(c)
			au["giocate"] = []
			_mescola(s, au["mazzo"])
	_log(s, "— Round %s —" % ["", "I", "II", "III", "IV", "V"][int(s["round"])])

static func _passo_flusso(s: Dictionary) -> void:
	var fase: String = s["fase"]
	if fase == "azione":
		# fine di una carta giocata: catena ancora da completare?
		if not s["catena"].is_empty():
			var p: int = int(s["catena"]["chi"])
			if _opz_catena(s, p).size() > 1:
				_attendi(s, p, "catena")
				return
			s["catena"] = {}
		if s.get("giocata_in_corso", false):
			s["giocata_in_corso"] = false
			_fine_turno(s)
			return
		var attore: int = int(s["seq"][int(s["idx"])])
		if int(s["giocate"][str(attore)]) >= 5:
			# tutti hanno giocato?
			var tutti := true
			for a in s["seq"]:
				if int(s["giocate"][str(a)]) < 5:
					tutti = false
			if tutti:
				s["fase"] = "viaggiatori"
				_prepara_fine_round(s)
				return
			s["idx"] = (int(s["idx"]) + 1) % s["seq"].size()
			return
		if attore >= 100:
			_turno_automa(s, attore - 100)
			s["giocate"][str(attore)] = int(s["giocate"][str(attore)]) + 1
			s["idx"] = (int(s["idx"]) + 1) % s["seq"].size()
			return
		if not s["turno_iniziato"]:
			s["turno_iniziato"] = true
			s["mossa"] = int(s["mossa"]) + 1
			g(s, attore)["fatto"] = {}
			_inizio_turno(s, attore)
			if not s["attesa"].is_empty() or not s["pila"].is_empty():
				return
		_attendi(s, attore, "turno")
		return
	if fase == "fine":
		return
	# le altre fasi lavorano con la coda; quando la coda è vuota si passa oltre
	_prossima_fase(s)

static func _fine_turno(s: Dictionary) -> void:
	var attore: int = int(s["seq"][int(s["idx"])])
	s["giocate"][str(attore)] = int(s["giocate"][str(attore)]) + 1
	s["idx"] = (int(s["idx"]) + 1) % s["seq"].size()
	s["turno_iniziato"] = false

static func _inizio_turno(s: Dictionary, p: int) -> void:
	var gg := g(s, p)
	# Mostri di Villa Diodati: PV all'inizio del turno (non nel turno in cui sono stati presi)
	if s["esp"]["diodati"]:
		var tot := 0
		for k in gg["mostri"]:
			if int(gg["mostri"][k]) < int(s["mossa"]):
				tot += 1 if int(s["round"]) <= 3 else 2
		if tot > 0:
			gg["pv"] = int(gg["pv"]) + tot
			_log(s, "%s: i Mostri rendono %d PV." % [gg["nome"], tot])

# ---------------------------------------------------------------------------- fine del round
static func _prepara_fine_round(s: Dictionary) -> void:
	s["coda"] = []
	# Fase dei Viaggiatori Celebri: da sinistra a destra
	for col in 3:
		s["coda"].append({"t": "viaggiatore", "col": col})
	s["coda"].append({"t": "ammirazione"})
	if s["esp"]["napoleone"]:
		s["coda"].append({"t": "battaglia"})
	s["coda"].append({"t": "liszt"})
	s["coda"].append({"t": "mercato"})
	s["coda"].append({"t": "riorganizza"})

static func _prossima_fase(s: Dictionary) -> void:
	# coda vuota dopo la fine round: nuovo round o fine partita
	if s["fase"] == "viaggiatori":
		if int(s["round"]) >= 5:
			_punteggio_finale(s)
			return
		s["round"] = int(s["round"]) + 1
		if not s["solo"]:
			s["primo"] = (int(s["primo"]) + 1) % int(s["n"])
		if s["esp"]["diodati"] and int(s["round"]) == 4:
			_log(s, "La notte si fa più profonda: Villa Diodati e i Mostri si risvegliano.")
		_inizio_round(s)

static func _passo_coda(s: Dictionary) -> void:
	var t: Dictionary = s["coda"].pop_front()
	var D := Dati.d()
	match t["t"]:
		"viaggiatore":
			_fine_round_viaggiatore(s, int(t["col"]))
		"montagu":
			_attendi(s, int(t["p"]), "montagu")
		"napoleone":
			_attendi(s, int(t["p"]), "napoleone")
		"ammirazione":
			for p in _ordine_giocatori(s):
				for col in g(s, p)["ammirati"]:
					if int(g(s, p)["pv"]) >= 1:
						s["coda"].push_front({"t": "ammira", "p": p, "col": col})
		"ammira":
			_attendi(s, int(t["p"]), "ammira", {"col": int(t["col"])})
		"battaglia":
			_battaglia(s)
		"liszt":
			pass
		"mercato":
			# dal giocatore alla destra del primo, in senso antiorario
			for p in _ordine_giocatori(s):
				s["coda"].push_front({"t": "prendi", "p": p})
		"prendi":
			var p2: int = int(t["p"])
			var liv := _livello_mercato(s, p2)
			if liv > 0 and not _opz_compra(s, p2, {"gratis": liv}).is_empty():
				_attendi(s, p2, "mercato", {"liv": liv})
		"riorganizza":
			_riorganizza(s)
		"limite":
			var p3: int = int(t["p"])
			if g(s, p3)["mano"].size() > 8:
				_attendi(s, p3, "scarta")
				s["coda"].push_front({"t": "limite", "p": p3})
		_:
			push_error("compito sconosciuto " + str(t))

static func _ordine_giocatori(s: Dictionary) -> Array:
	var o: Array = []
	for a in _sequenza(s):
		if int(a) < 100:
			o.append(int(a))
	return o

static func _livello_mercato(s: Dictionary, p: int) -> int:
	var n := categorie_round(s, p).size()
	if s["esp"]["romantici"] and presso(s, p, "liszt"):
		n += 1
	if n >= 4: return 3
	if n >= 3: return 2
	if n >= 2: return 1
	return 0

static func _fine_round_viaggiatore(s: Dictionary, col: int) -> void:
	var vid: String = s["viaggiatori"][col]
	var c := citta_di(s, vid)
	var qui: Array = []
	for p in _ordine_giocatori(s):
		if g(s, p)["pos"] == c:
			qui.append(p)
	match vid:
		"montagu":
			for p in qui:
				s["coda"].push_front({"t": "montagu", "p": p})
		"mary_shelley":
			for p in qui:
				var n := idee_scritte(g(s, p))
				if n > 0:
					g(s, p)["pv"] = int(g(s, p)["pv"]) + n
					_log(s, "%s con Mary Shelley: +%d PV." % [nome(s, p), n])
		"keats":
			for p in qui:
				var n2: int = int(g(s, p)["avanzate_round"])
				if n2 > 0:
					g(s, p)["pv"] = int(g(s, p)["pv"]) + n2
					_log(s, "%s con Keats: +%d PV." % [nome(s, p), n2])
		"goethe":
			for p in qui:
				var n3 := mini(7, int(g(s, p)["monete"]))
				if n3 > 0:
					g(s, p)["pv"] = int(g(s, p)["pv"]) + n3
					_log(s, "%s con Goethe: +%d PV." % [nome(s, p), n3])
		"blessington":
			var dist := {}
			var mi := 999
			var ma := -1
			for p in _ordine_giocatori(s):
				var dd := Dati.distanza(g(s, p)["pos"], c)
				dist[p] = dd
				mi = mini(mi, dd)
				ma = maxi(ma, dd)
			for p in dist:
				if dist[p] == mi:
					g(s, p)["pv"] = int(g(s, p)["pv"]) + 3
					_log(s, "%s è il più vicino a Lady Blessington: +3 PV." % nome(s, p))
				elif dist[p] == ma:
					g(s, p)["pv"] = maxi(0, int(g(s, p)["pv"]) - 2)
					_log(s, "%s è il più lontano da Lady Blessington: meno 2 PV." % nome(s, p))
		"le_brun":
			s["lebrun"]["scoperti"] = []
		"napoleone":
			for p in qui:
				s["coda"].push_front({"t": "napoleone", "p": p})
		"paolina":
			for p in qui:
				g(s, p)["soldati"] = int(g(s, p)["soldati"]) + 1
				_log(s, "%s con Paolina Bonaparte: 1 Soldato Francese." % nome(s, p))
		"foscolo":
			for p in qui:
				var n4: int = 2 * int(g(s, p)["soldati"])
				if n4 > 0:
					g(s, p)["pv"] = int(g(s, p)["pv"]) + n4
					_log(s, "%s con Ugo Foscolo: +%d PV." % [nome(s, p), n4])

static func _battaglia(s: Dictionary) -> void:
	var D := Dati.d()
	var k: String = s["battaglia"]["attuale"]
	if k == "":
		return
	var b: Dictionary = D["battaglie"][k]
	var tot := 0
	var contr: Array = []
	for p in _ordine_giocatori(s):
		var n: int = int(g(s, p)["soldati"])
		tot += n
		if n > 0:
			contr.append([p, n])
	var forza: int = int(s["nn"]) + int(b["mod"])
	var vinta := tot >= forza
	_log(s, "Battaglia %s: %d Soldati Francesi contro forza %d: %s." % [k, tot, forza, "vittoria" if vinta else "sconfitta"])
	# premi: una volta per soldato (in ordine di turno)
	for c in contr:
		var p: int = c[0]
		var volte: int = c[1]
		var eff: Array = []
		if b.get("una_volta", false):
			eff = [{"compra_max": mini(3, volte)}]
		else:
			for i in volte:
				eff += b["premio"].duplicate(true)
		_spingi(s, p, eff, "Battaglia")
	if vinta and contr.size() > 0:
		contr.sort_custom(func(a, b2): return a[1] > b2[1])
		var primo: int = contr[0][1]
		var secondi: Array = []
		var primi: Array = []
		for c in contr:
			if c[1] == primo: primi.append(c[0])
		if primi.size() == 1:
			var resto: Array = contr.filter(func(x): return x[1] < primo)
			if resto.size():
				var sec: int = resto[0][1]
				for c in resto:
					if c[1] == sec: secondi.append(c[0])
		for p in primi:
			g(s, p)["pv"] = int(g(s, p)["pv"]) + int(b["pv"][0])
		for p in secondi:
			g(s, p)["pv"] = int(g(s, p)["pv"]) + int(b["pv"][1])
	for p in _ordine_giocatori(s):
		g(s, p)["soldati"] = 0
	s["battaglia"]["attuale"] = s["battaglia"]["mazzo"].pop_front() if s["battaglia"]["mazzo"].size() else ""

static func _riorganizza(s: Dictionary) -> void:
	var ultimo := int(s["round"]) >= 5
	if not ultimo:
		_rifornisci(s)
	for p in _ordine_giocatori(s):
		var gg := g(s, p)
		for a in gg["area"]:
			if String(a["id"]).begins_with("n:"):
				continue
			gg["mano"].append(a["id"])
		gg["area"] = []
		if gg["mano"].size() > 8:
			s["coda"].append({"t": "limite", "p": p})
	for k in 4:
		s["andersen"][k] = -1

# ---------------------------------------------------------------------------- punteggio finale
static func punteggi(s: Dictionary) -> Array:
	var D := Dati.d()
	var out: Array = []
	var n := int(s["n"])
	for p in n:
		var gg := g(s, p)
		var r := {"tracciato": int(gg["pv"]), "esplorazioni": 0, "diari": 0, "carte": 0, "esperienze": 0,
			"maggioranze": 0, "dipinti": 0, "pattuglie": 0}
		r["esplorazioni"] = int(D["tab_esplorazioni"][mini(8, gg["tessere"].size())])
		for d in gg["diari"]:
			var k := 0
			for x in d["slot"]:
				if x != null: k += 1
			r["diari"] += int(D["tab_diari"][k])
		for c in gg["mano"]:
			r["carte"] += pv_carta(s, p, c)
		# Affinità Elettive
		var aff: Array = []
		for col in 3:
			for rr in 5:
				var sp = s["gaz"][col][rr]
				if sp != null and int(sp["p"]) == p and sp["t"] == "affinita":
					aff.append(col)
		if aff.size() == 2 and aff[0] == aff[1]:
			r["esperienze"] = 6
		else:
			r["esperienze"] = 2 * aff.size()
		var tipi := {}
		for t in gg["dipinti"]:
			tipi[t] = true
		r["dipinti"] = int(D["tab_dipinti"][mini(5, tipi.size())])
		out.append(r)
	# maggioranze della Gazzetta (gli Automi contano per le posizioni ma non segnano)
	for col in 3:
		var conti := {}
		var alto := {}
		for rr in 5:
			var sp = s["gaz"][col][rr]
			if sp == null: continue
			var chi := int(sp["p"])
			conti[chi] = int(conti.get(chi, 0)) + (2 if sp["t"] == "notte" else 1)
			if not alto.has(chi): alto[chi] = rr
		var chi_l: Array = conti.keys()
		chi_l.sort_custom(func(a, b): return conti[a] > conti[b] or (conti[a] == conti[b] and alto[a] < alto[b]))
		var premi := [5] if (n == 2 and not s["solo"]) else [5, 3, 1]
		for i in mini(premi.size(), chi_l.size()):
			if int(chi_l[i]) < 100:
				out[int(chi_l[i])]["maggioranze"] += premi[i]
	# Pattuglie Austriache: 5 / 2
	if s["esp"]["napoleone"]:
		var lst: Array = []
		for p in n:
			lst.append([p, g(s, p)["pattuglie"].size()])
		lst.sort_custom(func(a, b): return a[1] > b[1])
		if lst.size() and lst[0][1] > 0:
			var top: int = lst[0][1]
			var primi := lst.filter(func(x): return x[1] == top)
			for x in primi: out[x[0]]["pattuglie"] += 5
			if primi.size() == 1:
				var resto := lst.filter(func(x): return x[1] < top and x[1] > 0)
				if resto.size():
					var sec: int = resto[0][1]
					for x in resto:
						if x[1] == sec: out[x[0]]["pattuglie"] += 2
	for r in out:
		r["totale"] = r["tracciato"] + r["esplorazioni"] + r["diari"] + r["carte"] + r["esperienze"] + r["maggioranze"] + r["dipinti"] + r["pattuglie"]
	return out

static func pv_carta(s: Dictionary, p: int, id: String) -> int:
	var i := info(id)
	if i["tipo"] != "a":
		return 0
	if i["cond"] == null:
		return int(i["pv"])
	var c: Dictionary = i["cond"]
	var gg := g(s, p)
	var n := 0
	match c["tipo"]:
		"carte_cat":
			for x in gg["mano"]:
				var ix := info(x)
				if ix["tipo"] != "n" and ix["cat"] == c["cat"]: n += 1
		"carte_liv":
			for x in gg["mano"]:
				if info(x)["liv"] == int(c["liv"]): n += 1
		"tessere_citta": n = gg["tessere"].size()
		"citta_presenza":
			for cc in Dati.citta():
				var ok := false
				for lato in 2:
					if s["citta"][cc]["lettere"][lato].has(p): ok = true
					for v in s["citta"][cc]["caffe"][lato]:
						if v != null and int(v) == p: ok = true
				if ok: n += 1
		"idee_scritte": n = idee_scritte(gg)
		"caffe": n = 6 - int(gg["caffe"])
		"idee_libere":
			for k in gg["idee"]: n += int(gg["idee"][k])
		"monete": n = int(gg["monete"])
	var v := (n / int(c["ogni"])) * int(c["pv"])
	if c.has("max"):
		v = mini(v, int(c["max"]))
	return v

static func _punteggio_finale(s: Dictionary) -> void:
	s["fase"] = "fine"
	s["fine"] = true
	var pt := punteggi(s)
	s["punteggi"] = pt
	var migliore := -1
	var vinc: Array = []
	for p in pt.size():
		var t: int = pt[p]["totale"]
		if t > migliore:
			migliore = t
			vinc = [p]
		elif t == migliore:
			vinc.append(p)
	if vinc.size() > 1:
		# parità: vince chi è più a sud sulla mappa
		var D := Dati.d()
		var sud := -1
		var v2: Array = []
		for p in vinc:
			var y: int = int(D["nodi"][g(s, p)["pos"]][1])
			if y > sud:
				sud = y
				v2 = [p]
			elif y == sud:
				v2.append(p)
		vinc = v2
	s["vincitori"] = vinc
	_log(s, "Fine del Grand Tour!")
	for p in pt.size():
		_log(s, "%s: %d PV." % [nome(s, p), pt[p]["totale"]])

# ============================================================================ Automi (solitario)
static func _turno_automa(s: Dictionary, k: int) -> void:
	var au: Dictionary = s["automi"][k]
	if au["mazzo"].is_empty():
		return
	var carta: String = au["mazzo"].pop_front()
	au["giocate"].append(carta)
	var cat: String = info(carta)["cat"]
	var chi := 100 + k
	var fallita := false
	match cat:
		"V":
			if k == 0:
				var e1 := _automa_esplora(s, au)
				var m1 := _automa_muovi(s, au)
				fallita = not (e1 or m1)
			else:
				var m2 := _automa_muovi(s, au)
				var e2 := _automa_esplora(s, au)
				fallita = not (m2 or e2)
		"A":
			fallita = not _automa_amicizia(s, k, au)
		"I":
			var c: String = au["pos"]
			var d := 0 if k == 0 else 1
			if s["citta"][c]["caffe"][d][0] == null:
				s["citta"][c]["caffe"][d][0] = chi
				au["caffe"] = int(au["caffe"]) - 1
				_log(s, "%s occupa un caffè a %s." % [au["nome"], c])
			else:
				fallita = true
	if fallita:
		_azione_fallita(s, k, carta)

static func _automa_esplora(s: Dictionary, au: Dictionary) -> bool:
	var c: String = au["pos"]
	if s["automa_espl"].size() >= 3 or s["citta"][c]["esplora"].is_empty():
		return false
	s["automa_espl"].append(s["citta"][c]["esplora"].pop_front())
	_log(s, "%s esplora %s e toglie una tessera." % [au["nome"], c])
	return true

static func _automa_muovi(s: Dictionary, au: Dictionary) -> bool:
	var ordine: Array = Dati.d()["ordine_automi"]
	var i := ordine.find(au["pos"])
	if i < 0 or i >= ordine.size() - 1:
		return false
	au["pos"] = ordine[i + 1]
	_log(s, "%s va a %s." % [au["nome"], au["pos"]])
	return true

static func _automa_amicizia(s: Dictionary, k: int, au: Dictionary) -> bool:
	var c: String = au["pos"]
	var chi := 100 + k
	var passi := ["lettera_sx", "amico", "esperienza"] if k == 0 else ["esperienza", "amico", "lettera_dx"]
	for i in passi.size():
		var ps: String = passi[i]
		var ultimo := i == passi.size() - 1
		match ps:
			"lettera_sx", "lettera_dx":
				var lato := 0 if ps == "lettera_sx" else 1
				var tot: int = s["citta"][c]["lettere"][0].size() + s["citta"][c]["lettere"][1].size()
				if s["citta"][c]["lettere"][lato].is_empty() and tot < _limite_lettere(s):
					s["citta"][c]["lettere"][lato].append(chi)
					_log(s, "%s mette una Lettera a %s." % [au["nome"], c])
					return true
			"amico":
				if int(s["citta"][c]["amico"]) >= 0:
					s["citta"][c]["amico"] = -1
					_log(s, "%s scarta la tessera Amico di %s." % [au["nome"], c])
					return true
			"esperienza":
				var col_ok := -1
				var r := int(s["round"]) - 1
				var vp := viaggiatori_pos(s)
				for col in range(2, -1, -1):
					if vp[col][1] == c:
						col_ok = col
						break
				if col_ok >= 0 and spazio_disponibile(s, col_ok, r) and au["esp"].size():
					s["gaz"][col_ok][r] = {"p": chi, "t": au["esp"].pop_front()}
					_log(s, "%s incontra %s." % [au["nome"], Dati.viaggiatore(vp[col_ok][0])["nome"]])
					return true
				if k == 0 and ultimo:
					return false
		if ultimo:
			return false
	return false

static func _azione_fallita(s: Dictionary, k: int, carta: String) -> void:
	s["fallite"].append(carta)
	var spazio: int = s["fallite"].size()
	var liv := "2" if spazio == 1 or spazio == 3 else "3"
	var pri := [1, 2, 0] if k == 0 else [2, 1, 0]
	var tolta := ""
	for col in pri:
		if col < s["mercato"][liv].size():
			tolta = s["mercato"][liv][col]
			s["mercato"][liv].remove_at(col)
			break
	_log(s, "Azione fallita per %s%s." % [s["automi"][k]["nome"], (": esce dal Mercato " + nome_carta(tolta)) if tolta != "" else ""])
	if s["fallite"].size() >= 5:
		# le 5 carte escono dal gioco
		for c in s["fallite"]:
			for au in s["automi"]:
				au["giocate"].erase(c)
		s["fallite"] = []

# ============================================================================ effetti
static func _effetto(s: Dictionary, p: int, e: Dictionary) -> void:
	var gg := g(s, p)
	if e.has("monete"):
		gg["monete"] = int(gg["monete"]) + int(e["monete"])
		return
	if e.has("pv"):
		gg["pv"] = int(gg["pv"]) + int(e["pv"])
		return
	if e.has("idea"):
		if e["idea"] == "*":
			_attendi(s, p, "idea", {"escludi": e.get("escludi", []), "poi": e.get("poi", 0)})
		else:
			prendi_idea(s, p, e["idea"])
		return
	if e.has("idee_diverse"):
		_attendi(s, p, "idea", {"escludi": [], "poi": int(e["idee_diverse"]) - 1})
		return
	if e.has("o"):
		_attendi(s, p, "o", {"rami": e["o"]})
		return
	if e.has("paga"):
		if int(gg["monete"]) >= int(e["paga"]):
			_attendi(s, p, "paga", {"n": int(e["paga"]), "poi": e["poi"]})
		return
	if e.has("paga_pv"):
		if int(gg["pv"]) >= int(e["paga_pv"]):
			_attendi(s, p, "paga_pv", {"n": int(e["paga_pv"]), "poi": e["poi"]})
		return
	if e.has("muovi"):
		var n := int(e["muovi"])
		if n <= 0: return
		if _opz_muovi(s, p, int(e.get("sconto", 0))).size() > 1:
			_attendi(s, p, "muovi", {"n": n, "sconto": int(e.get("sconto", 0))})
		return
	if e.has("vai"):
		_attendi(s, p, "vai", {"citta": e["vai"]})
		return
	if e.has("esplora"):
		var c: String = e.get("dove", gg["pos"])
		if not Dati.e_citta(c): return
		_attendi(s, p, "esplora", {"n": int(e["esplora"]), "citta": c})
		return
	if e.has("conversa"):
		if not Dati.e_citta(gg["pos"]): return
		if _opz_conversa(s, p).size() > 1:
			_attendi(s, p, "conversa", {"n": int(e["conversa"])})
		return
	if e.has("_extra"):
		if _opz_extra(s, p, e["_extra"]).size() > 1:
			_attendi(s, p, "extra", {"dove": e["_extra"]})
		return
	if e.has("lettera"):
		var fatte: Array = e.get("fatte", [])
		if _opz_lettera(s, p, e.get("diverse", false), fatte, false).size() > 1:
			_attendi(s, p, "lettera", {"n": int(e["lettera"]), "diverse": e.get("diverse", false), "fatte": fatte, "ovunque": false})
		return
	if e.has("lettera_ovunque"):
		if _opz_lettera(s, p, false, [], true).size() > 1:
			_attendi(s, p, "lettera", {"n": 1, "diverse": false, "fatte": [], "ovunque": true})
		return
	if e.has("scrivi"):
		if _opz_scrivi(s, p, e.get("usati", [])).size() > 1:
			_attendi(s, p, "scrivi", {"n": int(e["scrivi"]), "diversi": e.get("diversi", false), "usati": e.get("usati", [])})
		return
	if e.has("discuti"):
		var dove = e.get("dove", "")
		var sci: int = int(e.get("sconto_idea", 0))
		if _opz_discuti(s, p, e.get("ovunque", false), dove, sci).size() > 1:
			_attendi(s, p, "discuti", {"ovunque": e.get("ovunque", false), "dove": dove, "sconto": sci})
		return
	if e.has("compra"):
		var par := {"sconto": int(e.get("sconto", 0)), "risolvi": e.get("risolvi", false)}
		if _opz_compra(s, p, par).size() > 1:
			_attendi(s, p, "compra", par)
		return
	if e.has("compra_max"):
		var par2 := {"gratis": int(e["compra_max"])}
		if _opz_compra(s, p, par2).size() > 1:
			_attendi(s, p, "compra", par2)
		return
	if e.has("scambia_idea"):
		if _totale_idee(gg) > 0:
			_attendi(s, p, "scambia_idea")
		return
	if e.has("scambia2"):
		if _totale_idee(gg) >= 2:
			_attendi(s, p, "scambia2")
		return
	if e.has("coperta_muovi"):
		if _opz_coperta_muovi(s, p).size() > 1:
			_attendi(s, p, "coperta_muovi")
		return
	if e.has("riusa_esplorazione"):
		if _opz_tessere(s, p, true).size() > 1:
			_attendi(s, p, "riusa")
		return
	if e.has("attiva_esplorazione"):
		if _opz_tessere(s, p, false).size() > 1:
			_attendi(s, p, "attiva_tessera")
		return
	if e.has("rimuovi_I"):
		if _opz_rimuovi_I(s, p).size() > 1:
			_attendi(s, p, "rimuovi_I", {"poi": e["poi"]})
		return
	if e.has("_lebrun"):
		if _opz_lebrun(s, p).size() > 1:
			_attendi(s, p, "lebrun")
		return
	if e.has("_percy"):
		if _opz_percy(s, p).size() > 1:
			_attendi(s, p, "percy")
		return
	if e.has("_monstro"):
		_attendi(s, p, "mostro", {"cat": e["_monstro"]})
		return
	push_error("effetto sconosciuto " + str(e))

static func _totale_idee(gg: Dictionary) -> int:
	var t := 0
	for k in gg["idee"]:
		t += int(gg["idee"][k])
	return t

static func prendi_idea(s: Dictionary, p: int, genere: String) -> void:
	var gg := g(s, p)
	gg["idee"][genere] = int(gg["idee"][genere]) + 1
	if presso(s, p, "twain"):
		gg["pv"] = int(gg["pv"]) + 2
		_log(s, "%s con Mark Twain: +2 PV." % gg["nome"])

static func _bonus_addison(s: Dictionary, p: int) -> void:
	if presso(s, p, "addison"):
		g(s, p)["pv"] = int(g(s, p)["pv"]) + 1

static func _limite_lettere(s: Dictionary) -> int:
	return 3 if int(s["nn"]) >= 5 else 2

static func favore_eff(s: Dictionary, c: String, lato: int) -> Array:
	var ft: String = s["citta"][c]["favore"]
	return Dati.d()["favori"][ft][lato]

# ============================================================================ opzioni
static func opzioni(s: Dictionary) -> Array:
	var a: Dictionary = s["attesa"]
	if a.is_empty():
		return []
	var p: int = int(a["chi"])
	match a["tipo"]:
		"turno": return _opz_turno(s, p)
		"catena": return _opz_catena(s, p)
		"coperta": return _opz_coperta(s, p)
		"idea":
			var o: Array = []
			for ge in Dati.GENERI:
				if not a["escludi"].has(ge):
					o.append({"id": ge, "testo": "Idea " + ge, "idea": ge})
			return o
		"o":
			var o2: Array = []
			for i in a["rami"].size():
				o2.append({"id": str(i), "testo": testo_eff(a["rami"][i])})
			o2.append({"id": "salta", "testo": "Nessuno dei due"})
			return o2
		"paga":
			return [{"id": "si", "testo": "Paga %d monet%s: %s" % [int(a["n"]), "a" if int(a["n"]) == 1 else "e", testo_eff(a["poi"])]},
				{"id": "salta", "testo": "Non pagare"}]
		"paga_pv":
			return [{"id": "si", "testo": "Perdi %d PV: %s" % [int(a["n"]), testo_eff(a["poi"])]}, {"id": "salta", "testo": "No"}]
		"muovi": return _opz_muovi(s, p, int(a["sconto"]))
		"vai":
			var o3: Array = []
			for c in a["citta"]:
				o3.append({"id": c, "testo": "Vai a " + c, "nodo": c})
			o3.append({"id": "salta", "testo": "Resta qui"})
			return o3
		"esplora": return _opz_esplora(s, p, a["citta"])
		"conversa": return _opz_conversa(s, p)
		"extra": return _opz_extra(s, p, a["dove"])
		"togli_lettera": return _opz_togli_lettera(s, p, a["dove"])
		"esperienza": return _opz_esperienza(s, p, int(a["col"]))
		"lettera": return _opz_lettera(s, p, a["diverse"], a["fatte"], a["ovunque"])
		"scrivi": return _opz_scrivi(s, p, a["usati"])
		"discuti": return _opz_discuti(s, p, a["ovunque"], a.get("dove", ""), int(a.get("sconto", 0)))
		"compra": return _opz_compra(s, p, a)
		"mercato": return _opz_compra(s, p, {"gratis": int(a["liv"])})
		"scambia_idea": return _opz_scambia_idea(s, p)
		"scambia2": return _opz_scambia2(s, p)
		"coperta_muovi": return _opz_coperta_muovi(s, p)
		"riusa": return _opz_tessere(s, p, true)
		"attiva_tessera": return _opz_tessere(s, p, false)
		"rimuovi_I": return _opz_rimuovi_I(s, p)
		"lebrun": return _opz_lebrun(s, p)
		"percy": return _opz_percy(s, p)
		"mostro":
			var m: Dictionary = Dati.d()["mostri"][a["cat"]]
			var eff: Array = m["quiete"] if int(s["round"]) <= 3 else m["risveglio"]
			return [{"id": "si", "testo": "Bonus del Mostro: " + testo_eff(eff)}, {"id": "salta", "testo": "Rinuncia al bonus"}]
		"montagu":
			return [{"id": "idee", "testo": "2 Idee a scelta"}, {"id": "pv", "testo": "3 PV"}]
		"napoleone":
			return [{"id": "monete", "testo": "2 monete"},
				{"id": "pv", "testo": "%d PV (2 per Pattuglia)" % (2 * g(s, p)["pattuglie"].size())}]
		"ammira":
			var col: int = int(a["col"])
			return [{"id": "si", "testo": "Perdi 1 PV: di nuovo " + testo_eff(_premio_gazzetta(s, col))},
				{"id": "salta", "testo": "No"}]
		"scarta":
			var o4: Array = []
			var mano: Array = g(s, p)["mano"]
			for i in mano.size():
				o4.append({"id": str(i), "testo": "Scarta " + nome_carta(mano[i]), "carta": mano[i]})
			return o4
		"pattuglia":
			return [{"id": "usa", "testo": "Risolvi la carta"}, {"id": "elimina", "testo": "Elimina la Pattuglia"}]
	return []

static func _premio_gazzetta(s: Dictionary, col: int) -> Array:
	return Dati.d()["gazzetta"][s["gazzetta"]]["premi"][col]

# ---------------------------------------------------------------------------- turno
static func _opz_turno(s: Dictionary, p: int) -> Array:
	var gg := g(s, p)
	var o: Array = []
	for i in gg["mano"].size():
		var id: String = gg["mano"][i]
		var inf := info(id)
		o.append({"id": "su:%d" % i, "testo": "Gioca " + nome_carta(id), "carta": id, "giu": false})
		o.append({"id": "giu:%d" % i, "testo": "Gioca coperta " + nome_carta(id), "carta": id, "giu": true})
	if s["esp"]["romantici"] and presso(s, p, "andersen") and not gg["andersen"]:
		for k in 4:
			if int(s["andersen"][k]) < 0:
				o.append({"id": "and:%d" % k, "testo": "Gioca la carta Andersen " + Dati.d()["andersen"][k]["nome"], "carta": "n:%d" % k})
	o += _azioni_libere(s, p, true)
	return o

static func _azioni_libere(s: Dictionary, p: int, inizio: bool) -> Array:
	var gg := g(s, p)
	var o: Array = []
	for k in gg["tessere"].size():
		var t: Dictionary = gg["tessere"][k]
		if not t["usata"]:
			o.append({"id": "tes:%d" % k, "testo": "Attiva la tessera " + _testo_tessera(t["id"]), "libera": true, "tessera": t["id"]})
	if inizio and not gg["fatto"].has("byron") and s["viaggiatori"].has("byron") and int(gg["monete"]) >= 3:
		var cb := citta_di(s, "byron")
		if cb != gg["pos"]:
			o.append({"id": "byron", "testo": "Paga 3 monete: raggiungi Lord Byron a " + cb, "libera": true, "nodo": cb})
	if s["viaggiatori"].has("dickens") and not gg["fatto"].has("dickens") and int(gg["monete"]) >= 2:
		var cd := citta_di(s, "dickens")
		if _opz_discuti(s, p, false, cd).size() > 1:
			o.append({"id": "dickens_d", "testo": "Paga 2 monete: discuti a %s con Dickens" % cd, "libera": true})
		o.append({"id": "dickens_e", "testo": "Paga 2 monete: esplora a %s con Dickens" % cd, "libera": true})
	if s["esp"]["napoleone"] and not gg["fatto"].has("recluta") and int(gg["monete"]) >= 2:
		o.append({"id": "recluta", "testo": "Paga 2 monete: recluta un Soldato Francese", "libera": true})
	return o

static func _testo_tessera(id: String) -> String:
	var p := id.split("_")
	return "%s (%s)" % [p[0], testo_eff(Dati.d()["esplorazioni"][p[0]][int(p[1])])]

static func eff_tessera(id: String) -> Array:
	var p := id.split("_")
	return Dati.d()["esplorazioni"][p[0]][int(p[1])]

static func _opz_catena(s: Dictionary, p: int) -> Array:
	var o: Array = []
	var gg := g(s, p)
	if s["catena"].is_empty():
		return [{"id": "fine", "testo": "Fine"}]
	var cat: String = s["catena"]["cat"]
	for i in gg["area"].size():
		var a: Dictionary = gg["area"][i]
		if a["giu"] or s["catena"]["usate"].has(i):
			continue
		if info(a["id"])["cats"].has(cat):
			o.append({"id": "att:%d" % i, "testo": "Attiva " + nome_carta(a["id"]) + ": " + testo_eff(info(a["id"])["eff"]), "carta": a["id"]})
	o += _azioni_libere(s, p, false)
	o.append({"id": "fine", "testo": "Termina la catena"})
	return o

static func _opz_coperta(s: Dictionary, p: int) -> Array:
	var gg := g(s, p)
	var o: Array = [{"id": "monete", "testo": "Ottieni 2 monete"}]
	if _opz_muovi(s, p, 0).size() > 1:
		o.append({"id": "muovi", "testo": "Muovi di 1"})
	if _opz_compra(s, p, {"sconto": 0}).size() > 1:
		o.append({"id": "compra", "testo": "Compra una carta dal Mercato"})
	return o

# ---------------------------------------------------------------------------- movimento
static func _opz_muovi(s: Dictionary, p: int, sconto: int) -> Array:
	var gg := g(s, p)
	var o: Array = []
	for v in Dati.vicini(gg["pos"]):
		var costo: int = maxi(0, int(v[1]) - sconto)
		if costo <= int(gg["monete"]):
			o.append({"id": v[0], "testo": "Vai a %s%s" % [_nome_nodo(v[0]), (" (%d monet%s)" % [costo, "a" if costo == 1 else "e"]) if costo > 0 else ""],
				"nodo": v[0], "costo": costo})
	o.append({"id": "salta", "testo": "Non muovere"})
	return o

static func _nome_nodo(n: String) -> String:
	return n if Dati.e_citta(n) else "campagna"

# ---------------------------------------------------------------------------- esplorazione
static func _opz_esplora(s: Dictionary, p: int, c: String) -> Array:
	var gg := g(s, p)
	var o: Array = []
	var ha := false
	for t in gg["tessere"]:
		if String(t["id"]).begins_with(c + "_"):
			ha = true
	if not ha:
		for t in s["citta"][c]["esplora"]:
			o.append({"id": "t:" + t, "testo": "Prendi la tessera " + _testo_tessera(t), "tessera": t})
	o.append({"id": "premio", "testo": "Ricompensa della città: " + testo_eff(Dati.d()["plance"][c]["esplora_alt"])})
	o.append({"id": "salta", "testo": "Non esplorare"})
	return o

# ---------------------------------------------------------------------------- conversazione
static func _opz_conversa(s: Dictionary, p: int) -> Array:
	var gg := g(s, p)
	var c: String = gg["pos"]
	var o: Array = []
	if not Dati.e_citta(c):
		return [{"id": "salta", "testo": "Nessuno con cui parlare"}]
	var ab: Array = Dati.d()["abitanti"][c]
	for lato in 2:
		o.append({"id": "ab:%d" % lato, "testo": "Parla con %s: %s" % [ab[lato], testo_eff(favore_eff(s, c, lato))], "citta": c, "lato": lato})
	var r := int(s["round"]) - 1
	var vp := viaggiatori_pos(s)
	if gg["esp"].size() > 0:
		for col in 3:
			if vp[col][1] == c and spazio_disponibile(s, col, r) and not gg["bloccati"].has(col) and not _opz_esperienza(s, p, col).is_empty():
				o.append({"id": "vg:%d" % col, "testo": "Incontra %s: %s" % [Dati.viaggiatore(vp[col][0])["nome"], testo_eff(_premio_gazzetta(s, col))], "col": col})
	o.append({"id": "salta", "testo": "Non conversare"})
	return o

static func _opz_extra(s: Dictionary, p: int, dove: Dictionary) -> Array:
	var gg := g(s, p)
	var c: String = dove["citta"]
	var lato: int = int(dove["lato"])
	var o: Array = []
	if int(s["citta"][c]["amico"]) == lato:
		o.append({"id": "amico", "testo": "Prendi la tessera Amico di " + c})
	var mie: Array = s["citta"][c]["lettere"][lato]
	if not mie.has(p):
		var tot: int = s["citta"][c]["lettere"][0].size() + s["citta"][c]["lettere"][1].size()
		var gia_qui: bool = s["citta"][c]["lettere"][1 - lato].has(p)
		var spazio_ok: bool
		if int(s["nn"]) >= 5:
			spazio_ok = (tot - (1 if gia_qui else 0)) < 3
		else:
			spazio_ok = mie.is_empty() and (tot - (1 if gia_qui else 0)) < 2
		if spazio_ok:
			o.append({"id": "lettera", "testo": ("Sposta qui la tua Lettera" if gia_qui else "Lascia una Lettera") + " (" + Dati.d()["abitanti"][c][lato] + ")"})
	o.append({"id": "salta", "testo": "Nient’altro"})
	return o

static func _opz_togli_lettera(s: Dictionary, p: int, dove: Dictionary) -> Array:
	var o: Array = []
	for c in Dati.citta():
		for lato in 2:
			if s["citta"][c]["lettere"][lato].has(p):
				o.append({"id": "%s:%d" % [c, lato], "testo": "Riprendi la Lettera da " + c, "nodo": c})
	o.append({"id": "salta", "testo": "Lascia stare"})
	return o

static func _opz_esperienza(s: Dictionary, p: int, col: int) -> Array:
	var gg := g(s, p)
	var o: Array = []
	var vid: String = s["viaggiatori"][col]
	var visti := {}
	for t in gg["esp"]:
		if visti.has(t): continue
		visti[t] = true
		if t == "duello" and Dati.viaggiatore(vid).get("no_duello", false):
			continue
		o.append({"id": t, "testo": Dati.ESPERIENZE[t], "esperienza": t})
	return o

# ---------------------------------------------------------------------------- lettere
static func _opz_lettera(s: Dictionary, p: int, diverse: bool, fatte: Array, ovunque: bool) -> Array:
	var gg := g(s, p)
	var o: Array = []
	var rousseau: bool = s["viaggiatori"].has("rousseau") and presso(s, p, "rousseau")
	for c in Dati.citta():
		if c == gg["pos"] and not ovunque:
			continue
		for lato in 2:
			var k := "%s:%d" % [c, lato]
			if diverse and fatte.has(k):
				continue
			var mia: bool = s["citta"][c]["lettere"][lato].has(p)
			var ok := mia
			if ovunque:
				ok = not mia
			elif rousseau and c != gg["pos"]:
				ok = true
			if ok:
				o.append({"id": k, "testo": "Lettera %s (%s): %s" % [a_chi(Dati.d()["abitanti"][c][lato]), c, testo_eff(favore_eff(s, c, lato))], "nodo": c, "citta": c, "lato": lato})
	o.append({"id": "salta", "testo": "Non scrivere lettere"})
	return o

# ---------------------------------------------------------------------------- diario
static func _opz_scrivi(s: Dictionary, p: int, usati: Array) -> Array:
	var gg := g(s, p)
	var o: Array = []
	for di in 2:
		if usati.has(di):
			continue
		var d: Dictionary = gg["diari"][di]
		var fatti := {}
		for k in 8:
			if d["slot"][k] != null:
				continue
			var req := slot_richiesta(d["id"], k)
			if fatti.has(req):
				continue
			fatti[req] = true
			if Dati.GENERI.has(req):
				if int(gg["idee"][req]) > 0:
					o.append({"id": "%d:%d:%s" % [di, k, req], "testo": "Scrivi un’Idea %s nel Diario di %s" % [req, d["id"].substr(2)], "diario": di, "slot": k})
			elif req.begins_with("citta:"):
				var c := req.substr(6)
				for ti in gg["tessere"].size():
					var t: Dictionary = gg["tessere"][ti]
					if not t.get("diario", false) and String(t["id"]).begins_with(c + "_"):
						o.append({"id": "%d:%d:t%d" % [di, k, ti], "testo": "Scrivi la tessera di %s nel Diario" % c, "diario": di, "slot": k})
			else:
				for ai in gg["amici"].size():
					if not gg["amici"][ai].get("diario", false):
						o.append({"id": "%d:%d:a%d" % [di, k, ai], "testo": "Scrivi l’Amico di %s nel Diario di %s" % [gg["amici"][ai]["citta"], d["id"].substr(2)], "diario": di, "slot": k})
						break
	o.append({"id": "salta", "testo": "Non scrivere"})
	return o

# ---------------------------------------------------------------------------- caffè
## pagamenti possibili per una discussione: [{genere: n}]
static func pagamenti(s: Dictionary, p: int, c: String, d: int, sconto := 0) -> Array:
	var gg := g(s, p)
	var disc: Dictionary = Dati.d()["plance"][c]["caffe"][d]
	var base: Array = []
	if disc.get("o", false):
		for k in disc["costo"]:
			base.append({k: int(disc["costo"][k])})
	else:
		var x := {}
		for k in disc["costo"]:
			x[k] = int(disc["costo"][k])
		base.append(x)
	var tutti: Array = []
	var meno: int = sconto + (1 if s["viaggiatori"].has("craven") and citta_di(s, "craven") == c else 0)
	tutti = base
	for volta in meno:
		var nuovi: Array = []
		for b in tutti:
			if b.is_empty():
				nuovi.append(b)
				continue
			for k in b:
				var y: Dictionary = b.duplicate()
				y[k] = int(y[k]) - 1
				if int(y[k]) <= 0: y.erase(k)
				nuovi.append(y)
		tutti = nuovi
	var ok: Array = []
	var visti := {}
	for t in tutti:
		var puo := true
		for k in t:
			if int(gg["idee"][k]) < int(t[k]): puo = false
		var chiave := JSON.stringify(t)
		if puo and not visti.has(chiave):
			visti[chiave] = true
			ok.append(t)
	return ok

static func _testo_costo(t: Dictionary) -> String:
	var parti: Array = []
	for k in t:
		parti.append("%d %s" % [int(t[k]), k])
	return ", ".join(parti) if parti.size() else "gratis"

static func _opz_discuti(s: Dictionary, p: int, ovunque: bool, dove = "", sconto := 0) -> Array:
	var gg := g(s, p)
	var o: Array = []
	if int(gg["caffe"]) > 0:
		for c in Dati.citta():
			if dove != "" and dove != null and c != dove:
				continue
			var ammesso: bool = ovunque or c == gg["pos"] or s["citta"][c]["lettere"][0].has(p) or s["citta"][c]["lettere"][1].has(p)
			if dove != "" and dove != null:
				ammesso = true
			if not ammesso:
				continue
			for d in 2:
				var spazi: Array = s["citta"][c]["caffe"][d]
				var libero := -1
				for k in 2:
					if spazi[k] == null:
						libero = k
						break
				if libero < 0:
					continue
				var pv: int = int(Dati.d()["plance"][c]["caffe"][d]["pv"][libero])
				if s["viaggiatori"].has("montesquieu") and citta_di(s, "montesquieu") == c:
					pv += 4
				var pg := pagamenti(s, p, c, d, sconto)
				for k in pg.size():
					o.append({"id": "%s:%d:%d" % [c, d, k], "testo": "Caffè di %s: paga %s, +%d PV" % [c, _testo_costo(pg[k]), pv], "nodo": c, "citta": c, "disc": d, "pv": pv})
	o.append({"id": "salta", "testo": "Non discutere"})
	return o

# ---------------------------------------------------------------------------- mercato
static func costo_carta(id: String, sconto: int) -> int:
	return maxi(0, int(COSTO_LIVELLO[info(id)["liv"]]) - sconto)

static func _opz_compra(s: Dictionary, p: int, par: Dictionary) -> Array:
	var gg := g(s, p)
	var o: Array = []
	var gratis: int = int(par.get("gratis", 0))
	for l in ["1", "2", "3"]:
		var lv := int(l)
		var lista: Array = []
		for k in s["mercato"][l].size():
			lista.append(["m:%s:%d" % [l, k], s["mercato"][l][k]])
		if s["mazzi"][l].size():
			lista.append(["d:%s" % l, s["mazzi"][l][0]])
		for it in lista:
			var costo := 0
			if gratis > 0:
				if lv > gratis: continue
			else:
				costo = costo_carta(it[1], int(par.get("sconto", 0)))
				if costo > int(gg["monete"]): continue
			o.append({"id": it[0], "testo": "Prendi %s%s" % [nome_carta(it[1]), (" per %d monete" % costo) if costo > 0 else ""], "carta": it[1], "costo": costo})
	if not o.is_empty() or gratis == 0:
		o.append({"id": "salta", "testo": "Non prendere carte"})
	return o

# ---------------------------------------------------------------------------- varie
static func _opz_scambia_idea(s: Dictionary, p: int) -> Array:
	var gg := g(s, p)
	var o: Array = []
	for a in Dati.GENERI:
		if int(gg["idee"][a]) <= 0: continue
		for b in Dati.GENERI:
			if b != a:
				o.append({"id": "%s:%s" % [a, b], "testo": "Cedi %s, prendi %s" % [a, b]})
		o.append({"id": "%s:monete" % a, "testo": "Cedi %s, prendi 3 monete" % a})
	o.append({"id": "salta", "testo": "Non scambiare"})
	return o

static func _opz_scambia2(s: Dictionary, p: int) -> Array:
	var gg := g(s, p)
	var o: Array = []
	for i in Dati.GENERI.size():
		for j in range(i, Dati.GENERI.size()):
			var a: String = Dati.GENERI[i]
			var b: String = Dati.GENERI[j]
			var ok := int(gg["idee"][a]) >= (2 if a == b else 1) and int(gg["idee"][b]) >= 1
			if ok:
				o.append({"id": "%s:%s" % [a, b], "testo": "Cedi %s e %s" % [a, b]})
	o.append({"id": "salta", "testo": "Non scambiare"})
	return o

static func _opz_coperta_muovi(s: Dictionary, p: int) -> Array:
	var gg := g(s, p)
	var o: Array = []
	for i in gg["area"].size():
		if not gg["area"][i]["giu"]:
			o.append({"id": str(i), "testo": "Gira coperta " + nome_carta(gg["area"][i]["id"]), "carta": gg["area"][i]["id"]})
	o.append({"id": "salta", "testo": "No"})
	return o

static func _opz_tessere(s: Dictionary, p: int, usate: bool) -> Array:
	var gg := g(s, p)
	var o: Array = []
	for k in gg["tessere"].size():
		var t: Dictionary = gg["tessere"][k]
		if bool(t["usata"]) == usate:
			o.append({"id": str(k), "testo": ("Riusa " if usate else "Attiva ") + _testo_tessera(t["id"]), "tessera": t["id"]})
	o.append({"id": "salta", "testo": "No"})
	return o

static func _opz_rimuovi_I(s: Dictionary, p: int) -> Array:
	var gg := g(s, p)
	var o: Array = []
	if gg["mano"].size() - 1 >= 5:
		for i in gg["mano"].size():
			if info(gg["mano"][i])["liv"] == 1:
				o.append({"id": str(i), "testo": "Elimina " + nome_carta(gg["mano"][i]), "carta": gg["mano"][i]})
	o.append({"id": "salta", "testo": "No"})
	return o

static func _opz_lebrun(s: Dictionary, p: int) -> Array:
	var gg := g(s, p)
	var o: Array = []
	for i in s["lebrun"]["scoperti"].size():
		var t: int = int(s["lebrun"]["scoperti"][i])
		if not gg["dipinti"].has(t):
			o.append({"id": str(i), "testo": "Prendi il Dipinto %d di Le Brun" % (t + 1), "dipinto": t})
	o.append({"id": "salta", "testo": "Nessun Dipinto"})
	return o

static func _opz_percy(s: Dictionary, p: int) -> Array:
	var gg := g(s, p)
	var o: Array = []
	for ge in Dati.GENERI:
		if int(gg["idee"][ge]) > 0 and not gg["percy"].has(ge):
			o.append({"id": ge, "testo": "Lascia un’Idea %s a Percy Shelley: +3 PV" % ge})
	o.append({"id": "salta", "testo": "No"})
	return o

# ============================================================================ applica una scelta
static func applica(s: Dictionary, id: String) -> bool:
	var ok := false
	for o in opzioni(s):
		if o["id"] == id:
			ok = true
			break
	if not ok:
		return false
	var a: Dictionary = s["attesa"]
	s["attesa"] = {}
	var p: int = int(a["chi"])
	var gg := g(s, p)
	match a["tipo"]:
		"turno": _app_turno(s, p, id, a)
		"catena":
			if id == "fine":
				s["catena"] = {}
			elif id.begins_with("att:"):
				var i := int(id.substr(4))
				s["catena"]["usate"].append(i)
				var cid: String = gg["area"][i]["id"]
				_spingi(s, p, info(cid)["eff"], nome_carta(cid))
			else:
				_azione_libera(s, p, id)
		"coperta":
			match id:
				"monete": gg["monete"] = int(gg["monete"]) + 2
				"muovi": _spingi(s, p, [{"muovi": 1}])
				"compra": _spingi(s, p, [{"compra": 1}])
		"idea":
			prendi_idea(s, p, id)
			var poi: int = int(a.get("poi", 0))
			if poi > 0:
				var esc: Array = a["escludi"].duplicate()
				esc.append(id)
				s["pila"].append({"chi": p, "eff": [{"idea": "*", "escludi": esc, "poi": poi - 1}], "fonte": ""})
		"o":
			if id != "salta":
				_spingi(s, p, a["rami"][int(id)])
		"paga":
			if id == "si":
				gg["monete"] = int(gg["monete"]) - int(a["n"])
				_spingi(s, p, a["poi"])
		"paga_pv":
			if id == "si":
				gg["pv"] = int(gg["pv"]) - int(a["n"])
				_spingi(s, p, a["poi"])
		"muovi":
			if id != "salta":
				var costo := 0
				for o in _opz_muovi(s, p, int(a["sconto"])):
					if o["id"] == id: costo = int(o["costo"])
				var vero := 0
				for v in Dati.vicini(gg["pos"]):
					if v[0] == id: vero = int(v[1])
				gg["monete"] = int(gg["monete"]) - costo
				gg["pos"] = id
				_log(s, "%s va a %s." % [gg["nome"], _nome_nodo(id)])
				var sc: int = int(a["sconto"])
				if vero > 0: sc = 0   # lo sconto vale per un solo costo
				if int(a["n"]) > 1:
					s["pila"].append({"chi": p, "eff": [{"muovi": int(a["n"]) - 1, "sconto": sc}], "fonte": ""})
		"vai":
			if id != "salta":
				gg["pos"] = id
				_log(s, "%s raggiunge %s." % [gg["nome"], id])
		"esplora": _app_esplora(s, p, id, a)
		"conversa": _app_conversa(s, p, id, a)
		"extra":
			var c: String = a["dove"]["citta"]
			var lato: int = int(a["dove"]["lato"])
			if id == "amico":
				s["citta"][c]["amico"] = -1
				gg["amici"].append({"citta": c, "lato": lato, "diario": false})
				_log(s, "%s fa amicizia a %s." % [gg["nome"], c])
			elif id == "lettera":
				if s["citta"][c]["lettere"][1 - lato].has(p):
					s["citta"][c]["lettere"][1 - lato].erase(p)
					s["citta"][c]["lettere"][lato].append(p)
				elif int(gg["lettere"]) > 0:
					gg["lettere"] = int(gg["lettere"]) - 1
					s["citta"][c]["lettere"][lato].append(p)
					_log(s, "%s lascia una Lettera a %s." % [gg["nome"], c])
				else:
					_attendi(s, p, "togli_lettera", {"dove": a["dove"]})
		"togli_lettera":
			if id != "salta":
				var pz := id.split(":")
				s["citta"][pz[0]]["lettere"][int(pz[1])].erase(p)
				var dv: Dictionary = a["dove"]
				s["citta"][dv["citta"]]["lettere"][int(dv["lato"])].append(p)
				_log(s, "%s sposta una Lettera da %s a %s." % [gg["nome"], pz[0], dv["citta"]])
		"esperienza": _app_esperienza(s, p, id, int(a["col"]))
		"lettera":
			if id != "salta":
				var pz2 := id.split(":")
				_log(s, "%s scrive %s (%s)." % [gg["nome"], a_chi(Dati.d()["abitanti"][pz2[0]][int(pz2[1])]), pz2[0]])
				var fatte: Array = a["fatte"].duplicate()
				fatte.append(id)
				if int(a["n"]) > 1:
					s["pila"].append({"chi": p, "eff": [{"lettera": int(a["n"]) - 1, "diverse": a["diverse"], "fatte": fatte}], "fonte": ""})
				_spingi(s, p, favore_eff(s, pz2[0], int(pz2[1])), "Lettera")
				_bonus_addison(s, p)
		"scrivi": _app_scrivi(s, p, id, a)
		"discuti":
			if id != "salta":
				var pz3 := id.split(":")
				var c3: String = pz3[0]
				var d3 := int(pz3[1])
				var pg: Dictionary = pagamenti(s, p, c3, d3, int(a.get("sconto", 0)))[int(pz3[2])]
				for k in pg:
					gg["idee"][k] = int(gg["idee"][k]) - int(pg[k])
				var spazi: Array = s["citta"][c3]["caffe"][d3]
				var libero := 0 if spazi[0] == null else 1
				spazi[libero] = p
				gg["caffe"] = int(gg["caffe"]) - 1
				var pv: int = int(Dati.d()["plance"][c3]["caffe"][d3]["pv"][libero])
				if s["viaggiatori"].has("montesquieu") and citta_di(s, "montesquieu") == c3:
					pv += 4
				gg["pv"] = int(gg["pv"]) + pv
				_log(s, "%s discute al caffè di %s: +%d PV." % [gg["nome"], c3, pv])
		"compra", "mercato": _app_compra(s, p, id, a)
		"scambia_idea":
			if id != "salta":
				var pz4 := id.split(":")
				gg["idee"][pz4[0]] = int(gg["idee"][pz4[0]]) - 1
				if pz4[1] == "monete":
					gg["monete"] = int(gg["monete"]) + 3
				else:
					prendi_idea(s, p, pz4[1])
		"scambia2":
			if id != "salta":
				var pz5 := id.split(":")
				gg["idee"][pz5[0]] = int(gg["idee"][pz5[0]]) - 1
				gg["idee"][pz5[1]] = int(gg["idee"][pz5[1]]) - 1
				_spingi(s, p, [{"idea": "*"}, {"idea": "*"}])
		"coperta_muovi":
			if id != "salta":
				gg["area"][int(id)]["giu"] = true
				_spingi(s, p, [{"muovi": 2}])
		"riusa", "attiva_tessera":
			if id != "salta":
				var t: Dictionary = gg["tessere"][int(id)]
				t["usata"] = true
				_spingi(s, p, eff_tessera(t["id"]), "Tessera")
		"rimuovi_I":
			if id != "salta":
				gg["mano"].remove_at(int(id))
				_spingi(s, p, a["poi"])
		"lebrun":
			if id != "salta":
				var t2: int = int(s["lebrun"]["scoperti"][int(id)])
				s["lebrun"]["scoperti"].remove_at(int(id))
				gg["dipinti"].append(t2)
				_log(s, "%s riceve un Dipinto da Vigée Le Brun." % gg["nome"])
		"percy":
			if id != "salta":
				gg["idee"][id] = int(gg["idee"][id]) - 1
				gg["percy"].append(id)
				gg["pv"] = int(gg["pv"]) + 3
		"mostro":
			if id == "si":
				var m: Dictionary = Dati.d()["mostri"][a["cat"]]
				_spingi(s, p, m["quiete"] if int(s["round"]) <= 3 else m["risveglio"], m["nome"])
		"montagu":
			if id == "pv":
				gg["pv"] = int(gg["pv"]) + 3
			else:
				_spingi(s, p, [{"idea": "*"}, {"idea": "*"}], "Lady Montagu")
		"napoleone":
			if id == "monete":
				gg["monete"] = int(gg["monete"]) + 2
			else:
				gg["pv"] = int(gg["pv"]) + 2 * gg["pattuglie"].size()
		"ammira":
			if id == "si":
				gg["pv"] = int(gg["pv"]) - 1
				_spingi(s, p, _premio_gazzetta(s, int(a["col"])), "Perso nell’Ammirazione")
		"scarta":
			var cid2: String = gg["mano"][int(id)]
			gg["mano"].remove_at(int(id))
			_log(s, "%s scarta %s." % [gg["nome"], nome_carta(cid2)])
		"pattuglia":
			var cid3: String = a["carta"]
			if id == "elimina":
				_prendi_pattuglia(s, p)
			else:
				_risolvi_carta_giocata(s, p, cid3, int(a["idx"]))
	avanza(s)
	return true

# ---------------------------------------------------------------------------- dettagli
static func _app_turno(s: Dictionary, p: int, id: String, a: Dictionary) -> void:
	var gg := g(s, p)
	if id.begins_with("su:") or id.begins_with("and:"):
		var cid: String
		if id.begins_with("su:"):
			var i := int(id.substr(3))
			cid = gg["mano"][i]
			gg["mano"].remove_at(i)
		else:
			var k := int(id.substr(4))
			cid = "n:%d" % k
			s["andersen"][k] = p
			gg["andersen"] = true
		s["giocata_in_corso"] = true
		_gioca_scoperta(s, p, cid)
	elif id.begins_with("giu:"):
		var i2 := int(id.substr(4))
		var cid2: String = gg["mano"][i2]
		gg["mano"].remove_at(i2)
		gg["area"].append({"id": cid2, "giu": true})
		s["giocata_in_corso"] = true
		_log(s, "%s gioca una carta coperta." % gg["nome"])
		_ritorno_mostri(s, p)
		_attendi(s, p, "coperta")
	else:
		_azione_libera(s, p, id)

static func _azione_libera(s: Dictionary, p: int, id: String) -> void:
	var gg := g(s, p)
	if id.begins_with("tes:"):
		var t: Dictionary = gg["tessere"][int(id.substr(4))]
		t["usata"] = true
		var eff := eff_tessera(t["id"])
		var volte := 1
		if s["viaggiatori"].has("stendhal") and presso(s, p, "stendhal") and not gg["fatto"].has("stendhal"):
			gg["fatto"]["stendhal"] = true
			volte = 2
		for v in volte:
			_spingi(s, p, eff, "Tessera")
		_log(s, "%s attiva una tessera Esplorazione di %s." % [gg["nome"], String(t["id"]).split("_")[0]])
	elif id == "byron":
		gg["fatto"]["byron"] = true
		gg["monete"] = int(gg["monete"]) - 3
		gg["pos"] = citta_di(s, "byron")
		_log(s, "%s raggiunge Lord Byron a %s." % [gg["nome"], gg["pos"]])
	elif id == "dickens_d" or id == "dickens_e":
		gg["fatto"]["dickens"] = true
		gg["monete"] = int(gg["monete"]) - 2
		var cd := citta_di(s, "dickens")
		if id == "dickens_d":
			_spingi(s, p, [{"discuti": 1, "dove": cd}], "Dickens")
		else:
			_spingi(s, p, [{"esplora": 1, "dove": cd}], "Dickens")
	elif id == "recluta":
		gg["fatto"]["recluta"] = true
		gg["monete"] = int(gg["monete"]) - 2
		gg["soldati"] = int(gg["soldati"]) + 1
		_log(s, "%s recluta un Soldato Francese." % gg["nome"])
	# dopo un'azione libera si torna alla stessa decisione
	if s["catena"].is_empty() and not s.get("giocata_in_corso", false):
		pass

static func _gioca_scoperta(s: Dictionary, p: int, cid: String) -> void:
	var gg := g(s, p)
	var inf := info(cid)
	var cat: String = inf["cat"]
	var gia := false
	# categoria della catena: quella (fra le categorie della carta) con più carte già giocate
	var meglio := 0
	for c in inf["cats"]:
		var n := 0
		for a in gg["area"]:
			if not a["giu"] and info(a["id"])["cats"].has(c):
				n += 1
		if n > meglio:
			meglio = n
			cat = c
	gia = meglio > 0
	gg["area"].append({"id": cid, "giu": false})
	var idx: int = gg["area"].size() - 1
	_log(s, "%s gioca %s." % [gg["nome"], nome_carta(cid)])
	if inf["tipo"] == "a":
		gg["avanzate_round"] = int(gg["avanzate_round"]) + 1
		if presso(s, p, "keats"):
			gg["pv"] = int(gg["pv"]) + 2
	# Pattuglia Austriaca nella città
	if s["esp"]["napoleone"] and Dati.e_citta(gg["pos"]) and s["citta"][gg["pos"]]["pattuglia"] != "" and inf["cats"].has(s["citta"][gg["pos"]]["pattuglia"]):
		if s["viaggiatori"].has("paolina") and presso(s, p, "paolina"):
			_attendi(s, p, "pattuglia", {"carta": cid, "idx": idx, "gia": gia})
			return
		_prendi_pattuglia(s, p)
		return
	if gia:
		# Villa Diodati: si prende il Mostro della categoria
		if s["esp"]["diodati"] and int(s["villa"].get(cat, -1)) < 0:
			s["villa"][cat] = p
			gg["mostri"][cat] = int(s["mossa"])
			_log(s, "%s prende il controllo di %s." % [gg["nome"], Dati.d()["mostri"][cat]["nome"]])
			s["pila"].append({"chi": p, "eff": [{"_monstro": cat}], "fonte": ""})
		s["catena"] = {"chi": p, "cat": cat, "usate": []}
		return
	_risolvi_carta_giocata(s, p, cid, idx)

static func _risolvi_carta_giocata(s: Dictionary, p: int, cid: String, idx: int) -> void:
	_spingi(s, p, info(cid)["eff"], nome_carta(cid))

static func _prendi_pattuglia(s: Dictionary, p: int) -> void:
	var gg := g(s, p)
	var c: String = gg["pos"]
	gg["pattuglie"].append(s["citta"][c]["pattuglia"])
	s["citta"][c]["pattuglia"] = ""
	_log(s, "%s elimina la Pattuglia Austriaca di %s (la carta non ha effetto)." % [gg["nome"], c])

static func _ritorno_mostri(s: Dictionary, p: int) -> void:
	if not s["esp"]["diodati"]:
		return
	var n := 0
	for cat in s["villa"]:
		var chi: int = int(s["villa"][cat])
		if chi >= 0:
			n += 1
			g(s, chi)["mostri"].erase(cat)
			s["villa"][cat] = -1
	if n > 0:
		var pv: int = 1 + n * (1 if int(s["round"]) <= 3 else 2)
		g(s, p)["pv"] = int(g(s, p)["pv"]) + pv
		_log(s, "%s rimanda %d Mostr%s alla Villa: +%d PV." % [nome(s, p), n, "o" if n == 1 else "i", pv])

static func _app_esplora(s: Dictionary, p: int, id: String, a: Dictionary) -> void:
	var gg := g(s, p)
	var c: String = a["citta"]
	if id == "salta":
		return
	if int(a["n"]) > 1:
		s["pila"].append({"chi": p, "eff": [{"esplora": int(a["n"]) - 1, "dove": c}], "fonte": ""})
	# Le Brun: in aggiunta all'esplorazione
	if s["viaggiatori"].has("le_brun") and citta_di(s, "le_brun") == c and s["lebrun"]["scoperti"].size():
		s["pila"].append({"chi": p, "eff": [{"_lebrun": 1}], "fonte": ""})
	if id.begins_with("t:"):
		var t := id.substr(2)
		s["citta"][c]["esplora"].erase(t)
		gg["tessere"].append({"id": t, "usata": false, "diario": false})
		_log(s, "%s esplora %s e prende una tessera." % [gg["nome"], c])
	else:
		_spingi(s, p, Dati.d()["plance"][c]["esplora_alt"], "Esplorazione")
		_log(s, "%s esplora %s." % [gg["nome"], c])
	_bonus_addison(s, p)

static func _app_conversa(s: Dictionary, p: int, id: String, a: Dictionary) -> void:
	var gg := g(s, p)
	if id == "salta":
		return
	if int(a["n"]) > 1:
		s["pila"].append({"chi": p, "eff": [{"conversa": int(a["n"]) - 1}], "fonte": ""})
	_bonus_addison(s, p)
	if id.begins_with("ab:"):
		var lato := int(id.substr(3))
		var c: String = gg["pos"]
		_log(s, "%s parla con %s a %s." % [gg["nome"], Dati.d()["abitanti"][c][lato], c])
		s["pila"].append({"chi": p, "eff": [{"_extra": {"citta": c, "lato": lato}}], "fonte": ""})
		_spingi(s, p, favore_eff(s, c, lato), "Favore")
	else:
		var col := int(id.substr(3))
		_attendi(s, p, "esperienza", {"col": col})

static func _app_esperienza(s: Dictionary, p: int, t: String, col: int) -> void:
	var gg := g(s, p)
	var r := int(s["round"]) - 1
	gg["esp"].erase(t)
	s["gaz"][col][r] = {"p": p, "t": t}
	var premio := _premio_gazzetta(s, col)
	_log(s, "%s incontra %s (%s)." % [gg["nome"], Dati.viaggiatore(s["viaggiatori"][col])["nome"], Dati.ESPERIENZE[t]])
	if t == "duello":
		gg["bloccati"].append(col)
		_spingi(s, p, premio + premio, "Duello d’Onore")
	else:
		_spingi(s, p, premio, "Gazzetta")
	if t == "ammirazione":
		gg["ammirati"].append(col)

static func _app_scrivi(s: Dictionary, p: int, id: String, a: Dictionary) -> void:
	var gg := g(s, p)
	if id == "salta":
		return
	var pz := id.split(":")
	var di := int(pz[0])
	var k := int(pz[1])
	var cosa := pz[2]
	var d: Dictionary = gg["diari"][di]
	if cosa.begins_with("t"):
		var ti := int(cosa.substr(1))
		gg["tessere"][ti]["diario"] = true
		d["slot"][k] = "t:" + String(gg["tessere"][ti]["id"])
	elif cosa.begins_with("a"):
		var ai := int(cosa.substr(1))
		gg["amici"][ai]["diario"] = true
		d["slot"][k] = "a:%s_%d" % [gg["amici"][ai]["citta"], int(gg["amici"][ai].get("lato", 0))]
	else:
		gg["idee"][cosa] = int(gg["idee"][cosa]) - 1
		d["slot"][k] = cosa
	_log(s, "%s scrive nel Diario di %s." % [gg["nome"], d["id"].substr(2)])
	if int(a["n"]) > 1:
		var usati: Array = a["usati"].duplicate()
		if a["diversi"]:
			usati.append(di)
		s["pila"].append({"chi": p, "eff": [{"scrivi": int(a["n"]) - 1, "diversi": a["diversi"], "usati": usati}], "fonte": ""})
	if s["viaggiatori"].has("percy_shelley") and presso(s, p, "percy_shelley"):
		s["pila"].append({"chi": p, "eff": [{"_percy": 1}], "fonte": ""})

static func _app_compra(s: Dictionary, p: int, id: String, a: Dictionary) -> void:
	var gg := g(s, p)
	if id == "salta":
		return
	var cid: String
	var costo := 0
	for o in _opz_compra(s, p, a if a["tipo"] == "compra" else {"gratis": int(a["liv"])}):
		if o["id"] == id:
			costo = int(o["costo"])
	if id.begins_with("m:"):
		var pz := id.split(":")
		cid = s["mercato"][pz[1]][int(pz[2])]
		s["mercato"][pz[1]].remove_at(int(pz[2]))
	else:
		cid = s["mazzi"][id.substr(2)].pop_front()
	gg["monete"] = int(gg["monete"]) - costo
	gg["mano"].append(cid)
	_log(s, "%s prende %s." % [gg["nome"], nome_carta(cid)])
	if a.get("risolvi", false):
		_spingi(s, p, info(cid)["eff"], nome_carta(cid))
