class_name Rete
extends Node
## Ponte tra Godot e la pagina web (web/js/ponte.js): stanza su Firebase, telefoni, ospiti, salvataggi, suoni.
## Fuori dal browser (editor di Godot, prove) non fa nulla: si gioca in locale.

signal evento(e: Dictionary)

var web := false
var fr = null
var codice := ""
var url := ""
var uid := ""

func _ready() -> void:
	web = OS.has_feature("web")
	if web:
		fr = JavaScriptBridge.get_interface("FR")
		if fr == null:
			web = false

func _process(_d: float) -> void:
	if fr == null:
		return
	var s = fr.preleva()
	if s == null or str(s) == "" or str(s) == "[]":
		return
	var l = JSON.parse_string(str(s))
	if l is Array:
		for e in l:
			if e is Dictionary:
				if e.get("e") == "stanza":
					codice = e.get("codice", "")
					url = e.get("url", "")
					uid = e.get("uid", "")
				elif e.get("e") == "dentro":
					codice = e.get("codice", "")
					uid = e.get("uid", "")
				evento.emit(e)

func parametri() -> Dictionary:
	if fr == null:
		return {}
	var p = JSON.parse_string(str(fr.parametri()))
	return p if p is Dictionary else {}

## Apre una stanza (chi ospita). riprendi: il codice di prima, per continuare una gara salvata.
func avvia(riprendi := "") -> void:
	if fr:
		fr.avvia(riprendi)

## Entra in una stanza come ospite.
func entra(c: String, nome: String) -> void:
	if fr:
		fr.entra(c, nome)

func chiudi() -> void:
	if fr:
		fr.chiudi()
	codice = ""

func stato(d: Dictionary) -> void:
	if fr:
		fr.stato(JSON.stringify(d))

func azione(k: String, d: Dictionary) -> void:
	if fr:
		fr.azione(k, JSON.stringify(d))

func suono(n: String) -> void:
	if fr:
		fr.suono(n)

func schermo_intero() -> void:
	if fr:
		fr.schermoIntero()

func qr(testo: String) -> String:
	if fr:
		return str(fr.qr(testo))
	return ""

func salva(k: String, v: String) -> void:
	if fr:
		fr.salva(k, v)
	else:
		var f := FileAccess.open("user://%s.txt" % k, FileAccess.WRITE)
		if f:
			f.store_string(v)

func carica(k: String) -> String:
	if fr:
		var s = fr.carica(k)
		return "" if s == null else str(s)
	if FileAccess.file_exists("user://%s.txt" % k):
		return FileAccess.get_file_as_string("user://%s.txt" % k)
	return ""

## Copia del salvataggio su Firebase (timeless/salvataggi/<uid>).
func salva_remoto(v: String) -> void:
	if fr:
		fr.salvaRemoto(v)

## Copia del salvataggio dentro la stanza aperta.
func salva_stanza(v: String) -> void:
	if fr:
		fr.salvaStanza(v)

func chiedi_remoto() -> void:
	if fr:
		fr.caricaRemoto()
