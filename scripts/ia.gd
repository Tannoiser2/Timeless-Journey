class_name IA
extends RefCounted
## Giocatore guidato dal computer. Per ogni decisione prova ogni scelta su una copia dello stato, completa il
## proprio turno scegliendo ogni passo successivo con lo stesso criterio (un passo avanti) e tiene la scelta
## che lascia la posizione migliore secondo una stima del punteggio finale.

const PROFONDITA := 8

static func scegli(s: Dictionary, livello := 2) -> String:
	var opz := Motore.opzioni(s)
	if opz.is_empty():
		return ""
	if opz.size() == 1:
		return opz[0]["id"]
	var p: int = int(s["attesa"]["chi"])
	var meglio := ""
	var vmeglio := -INF
	var rng := RandomNumberGenerator.new()
	rng.seed = int(s["rng"]) ^ (int(s["mossa"]) * 7919) ^ opz.size()
	var profondo: bool = livello >= 2 and s["attesa"]["tipo"] in ["turno", "catena", "coperta", "conversa", "esplora", "o", "extra", "esperienza", "compra", "mercato", "lettera", "discuti", "muovi"]
	for o in opz:
		var c: Dictionary = s.duplicate(true)
		Motore.applica(c, o["id"])
		if profondo:
			_completa(c, p, s)
		var v := valore(c, p) + rng.randf() * (0.15 if livello >= 2 else 1.5)
		if v > vmeglio:
			vmeglio = v
			meglio = o["id"]
	return meglio

## porta avanti le decisioni dello stesso giocatore nello stesso turno con la scelta migliore a un passo
static func _completa(c: Dictionary, p: int, orig: Dictionary) -> void:
	var mossa: int = int(orig["mossa"])
	var fase: String = orig["fase"]
	for k in PROFONDITA:
		if c["fine"] or c["attesa"].is_empty():
			return
		if int(c["attesa"]["chi"]) != p or int(c["mossa"]) != mossa or c["fase"] != fase:
			return
		if c["attesa"]["tipo"] == "turno":
			return
		var opz := Motore.opzioni(c)
		var best := ""
		var bv := -INF
		for o in opz:
			var d: Dictionary = c.duplicate(true)
			Motore.applica(d, o["id"])
			var v := valore(d, p)
			if v > bv:
				bv = v
				best = o["id"]
		if best == "":
			return
		Motore.applica(c, best)

## stima del punteggio finale del giocatore p
static func valore(s: Dictionary, p: int) -> float:
	if s["fine"]:
		var pt: Array = s["punteggi"]
		var mio: float = pt[p]["totale"]
		var altri := 0.0
		for q in pt.size():
			if q != p: altri = maxf(altri, pt[q]["totale"])
		return mio * 1.0 + (5.0 if mio >= altri else 0.0)
	var D := Dati.d()
	var gg: Dictionary = s["giocatori"][p]
	var r: int = int(s["round"])
	var resto := float(5 - r) + (1.0 - float(s.get("giocate", {}).get(str(p), 0)) / 5.0 if s["fase"] == "azione" else 0.0)
	var v := float(gg["pv"])
	# tessere esplorazione
	var nt: int = gg["tessere"].size()
	v += float(D["tab_esplorazioni"][mini(8, nt)])
	for t in gg["tessere"]:
		if not t["usata"]:
			v += 1.6
	# diari: valore attuale + parte del valore dei pezzi pronti da scrivere
	var pronti_idee := {}
	for ge in Dati.GENERI:
		pronti_idee[ge] = int(gg["idee"][ge])
	var tess_libere: Array = []
	for t in gg["tessere"]:
		if not t.get("diario", false):
			tess_libere.append(String(t["id"]).split("_")[0])
	var amici_liberi := 0
	for a in gg["amici"]:
		if not a.get("diario", false):
			amici_liberi += 1
	var idee_avanzo := 0
	for d in gg["diari"]:
		var k := 0
		var potenziali := 0
		for i in 8:
			if d["slot"][i] != null:
				k += 1
				continue
			var req := Motore.slot_richiesta(d["id"], i)
			if Dati.GENERI.has(req):
				if int(pronti_idee[req]) > 0:
					pronti_idee[req] = int(pronti_idee[req]) - 1
					potenziali += 1
			elif req.begins_with("citta:"):
				if tess_libere.has(req.substr(6)):
					tess_libere.erase(req.substr(6))
					potenziali += 1
			elif amici_liberi > 0:
				amici_liberi -= 1
				potenziali += 1
		var att := float(D["tab_diari"][k])
		var pot := float(D["tab_diari"][mini(8, k + potenziali)])
		v += att + (pot - att) * 0.6
	for ge in Dati.GENERI:
		idee_avanzo += int(pronti_idee[ge])
	v += idee_avanzo * 0.7 + amici_liberi * 0.3
	# monete
	var mon: int = int(gg["monete"])
	v += minf(mon, 8) * 0.5 + maxf(0, mon - 8) * 0.15
	# lettere sparse per l'Italia
	var lett := 0
	for c in Dati.citta():
		for lato in 2:
			if s["citta"][c]["lettere"][lato].has(p):
				lett += 1
	v += lett * (0.6 + 0.4 * resto)
	# carte in mano
	var mano: Array = gg["mano"]
	for id in mano:
		var inf := Motore.info(id)
		if inf["tipo"] == "a":
			v += Motore.pv_carta(s, p, id) + 0.4 * inf["liv"] * minf(resto, 2.0)
	for id in gg["area"]:
		var inf2 := Motore.info(id["id"])
		if inf2["tipo"] == "a":
			v += Motore.pv_carta(s, p, id["id"])
	# esperienze: maggioranze attuali e gettoni ancora da usare
	var pt := Motore.punteggi(s)
	v += float(pt[p]["maggioranze"]) * 0.8 + float(pt[p]["esperienze"]) + float(pt[p]["dipinti"]) + float(pt[p]["pattuglie"]) * 0.8
	v += gg["esp"].size() * 0.9 * minf(resto, 2.0)
	# opportunità del luogo in cui ci si trova
	if resto > 0.05:
		v += _potenziale(s, p) * minf(1.0, resto)
	# varietà di categorie per il Mercato
	if s["fase"] == "azione":
		var nc: int = Motore.categorie_round(s, p).size()
		v += [0.0, 0.0, 1.5, 3.0, 4.5, 4.5, 4.5][mini(nc, 6)] * (1.0 if r < 5 else 0.7)
	# soldati e mostri
	v += int(gg["soldati"]) * 1.2
	v += gg["mostri"].size() * (1.0 if r <= 3 else 2.0) * minf(resto, 2.0)
	return v

static func _potenziale(s: Dictionary, p: int) -> float:
	var gg: Dictionary = s["giocatori"][p]
	var c: String = gg["pos"]
	var D := Dati.d()
	if not Dati.e_citta(c):
		# in campagna: vale la città migliore vicina
		var best := 0.0
		for v in Dati.vicini(c):
			if Dati.e_citta(v[0]):
				best = maxf(best, _valore_citta(s, p, v[0]) * 0.7)
		return best - 0.5
	return _valore_citta(s, p, c)

static func _valore_citta(s: Dictionary, p: int, c: String) -> float:
	var gg: Dictionary = s["giocatori"][p]
	var v := 0.0
	var ha := false
	for t in gg["tessere"]:
		if String(t["id"]).begins_with(c + "_"):
			ha = true
	if not ha and s["citta"][c]["esplora"].size() > 0:
		v += 2.5
	for d in 2:
		if Motore.pagamenti(s, p, c, d).size() > 0 and int(gg["caffe"]) > 0:
			var spazi: Array = s["citta"][c]["caffe"][d]
			for k in 2:
				if spazi[k] == null:
					v += float(Dati.d()["plance"][c]["caffe"][d]["pv"][k]) * 0.45
					break
	var r := int(s["round"]) - 1
	var vp := Motore.viaggiatori_pos(s)
	for col in 3:
		if vp[col][1] == c and Motore.spazio_disponibile(s, col, r) and gg["esp"].size() > 0 and not gg["bloccati"].has(col):
			v += 2.0
	if int(s["citta"][c]["amico"]) >= 0:
		v += 1.2
	return v
