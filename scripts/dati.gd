class_name Dati
extends RefCounted
## Dati del gioco (assets/dati/gioco.json) e piccole funzioni di consultazione.

static var _d: Dictionary = {}
static var _vicini: Dictionary = {}

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
