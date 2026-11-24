class_name Dati
extends RefCounted
## Dati del gioco (assets/dati/gioco.json) e piccole funzioni di consultazione.

static var _d: Dictionary = {}
static var _vicini: Dictionary = {}
static var _tracciati: Dictionary = {}

static func d() -> Dictionary:
	if _d.is_empty():
		var t := FileAccess.get_file_as_string("res://assets/dati/gioco.json")
		_d = JSON.parse_string(t)
		_vicini = {}
		for st in _d["strade"]:
			var a: String = st[0]
			var b: String = st[1]
			if not _vicini.has(a): _vicini[a] = []
			if not _vicini.has(b): _vicini[b] = []
			_vicini[a].append([b, int(st[2]), st[3]])
			_vicini[b].append([a, int(st[2]), st[3]])
	return _d

## [[nodo, costo, tipo], ...]
static func vicini(nodo: String) -> Array:
	d()
	return _vicini.get(nodo, [])

static func citta() -> Array:
	return d()["citta"]

static func e_citta(nodo: String) -> bool:
	return d()["citta"].has(nodo)

static func avanzata(num: int) -> Dictionary:
	return d()["avanzate"][str(num)]

static func viaggiatore(id: String) -> Dictionary:
	return d()["viaggiatori"][id]

## disegno vero della strada fra due luoghi vicini (dal tabellone, tools/traccia_strade.py), da a verso b
static func tratto(a: String, b: String) -> PackedVector2Array:
	if _tracciati.is_empty() and FileAccess.file_exists("res://assets/dati/tracciati.json"):
		_tracciati = JSON.parse_string(FileAccess.get_file_as_string("res://assets/dati/tracciati.json"))
	var out := PackedVector2Array()
	var inverso := false
	var lista = _tracciati.get(a + "|" + b, null)
	if lista == null:
		lista = _tracciati.get(b + "|" + a, null)
		inverso = true
	if lista == null:
		out.append(Vector2(d()["nodi"][a][0], d()["nodi"][a][1]))
		out.append(Vector2(d()["nodi"][b][0], d()["nodi"][b][1]))
		return out
	for q in lista:
		out.append(Vector2(q[0], q[1]))
	if inverso:
		out.reverse()
	return out

## strada più breve fra due luoghi (meno tappe, poi meno monete): elenco dei nodi da a a b compresi
static func strada(a: String, b: String, peso_nave := 1) -> Array:
	if a == b:
		return [a]
	var dist := {a: [0, 0]}
	var prima := {}
	var coda := [a]
	while not coda.is_empty():
		# coda con priorità semplice: prendi il nodo con distanza minore
		var mi := 0
		for i in coda.size():
			var x: Array = dist[coda[i]]
			var y: Array = dist[coda[mi]]
			if x[0] < y[0] or (x[0] == y[0] and x[1] < y[1]):
				mi = i
		var n: String = coda[mi]
		coda.remove_at(mi)
		if n == b:
			break
		for v in vicini(n):
			var nd: Array = [dist[n][0] + (peso_nave if v[2] == "nave" else 1), dist[n][1] + int(v[1])]
			if not dist.has(v[0]) or nd[0] < dist[v[0]][0] or (nd[0] == dist[v[0]][0] and nd[1] < dist[v[0]][1]):
				dist[v[0]] = nd
				prima[v[0]] = n
				if not coda.has(v[0]):
					coda.append(v[0])
	var out: Array = [b]
	var k := b
	while prima.has(k):
		k = prima[k]
		out.push_front(k)
	return out

## distanza in passi lungo le strade (Lady Blessington)
static func distanza(a: String, b: String) -> int:
	if a == b:
		return 0
	var visti := {a: 0}
	var coda := [a]
	while not coda.is_empty():
		var x: String = coda.pop_front()
		for v in vicini(x):
			if not visti.has(v[0]):
				visti[v[0]] = visti[x] + 1
				if v[0] == b:
					return visti[v[0]]
				coda.append(v[0])
	return 99

const GENERI := ["Arte", "Storia", "Filosofia", "Scienza"]
const CATEGORIE := {"V": "Viaggio", "A": "Amicizia", "I": "Ispirazione", "F": "Festività"}
const COLORI_GIOCATORE := {
	"rosso": Color("#d8453b"), "giallo": Color("#e9b92d"), "verde": Color("#3f9d4c"),
	"blu": Color("#3fa9c9"), "grigio": Color("#8b8f96"),
}
const NOMI_COLORE := {"rosso": "Rosso", "giallo": "Giallo", "verde": "Verde", "blu": "Azzurro", "grigio": "Grigio"}
const ESPERIENZE := {
	"duello": "Duello d’Onore", "notte": "Una Notte da Ricordare",
	"ammirazione": "Perso nell’Ammirazione", "affinita": "Affinità Elettive",
}
