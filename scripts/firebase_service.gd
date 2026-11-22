class_name FirebaseService
extends Node

signal caricamento_completato(dati: Dictionary)
signal errore(messaggio: String)

var database_url := ""
var api_key := ""
var player_id := ""
var enabled := false

func _ready() -> void:
	player_id = _load_player_id()
	_load_config()

func _load_player_id() -> String:
	var path := "user://player_id.txt"
	if FileAccess.file_exists(path):
		return FileAccess.get_file_as_string(path).strip_edges()
	var value := "%s-%s" % [Time.get_unix_time_from_system(), randi_range(1000, 9999)]
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value)
	return value

func _load_config() -> void:
	if not FileAccess.file_exists("res://firebase_config.json"):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://firebase_config.json"))
	if parsed is Dictionary:
		database_url = str(parsed.get("database_url", "")).trim_suffix("/")
		api_key = str(parsed.get("api_key", ""))
		enabled = database_url.begins_with("https://")

func salva_locale(dati: Dictionary) -> void:
	var file := FileAccess.open("user://partita.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(dati))

func carica_locale() -> Dictionary:
	if not FileAccess.file_exists("user://partita.json"):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("user://partita.json"))
	return parsed if parsed is Dictionary else {}

func salva_cloud(slot: String, dati: Dictionary) -> void:
	if not enabled:
		errore.emit("Firebase non configurato: salvataggio locale attivo")
		return
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(_result, code, _headers, _body):
		if code < 200 or code >= 300: errore.emit("Salvataggio cloud non riuscito (%s)" % code)
		req.queue_free())
	var url := "%s/partite/%s.json" % [database_url, slot.uri_encode()]
	req.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_PUT, JSON.stringify(dati))

func carica_cloud(slot: String) -> void:
	if not enabled:
		caricamento_completato.emit({})
		return
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(_result, code, _headers, body):
		var parsed = JSON.parse_string(body.get_string_from_utf8()) if code == 200 else {}
		caricamento_completato.emit(parsed if parsed is Dictionary else {})
		req.queue_free())
	req.request("%s/partite/%s.json" % [database_url, slot.uri_encode()])

