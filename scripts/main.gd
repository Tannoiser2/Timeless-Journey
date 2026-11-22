extends Node

const Firebase = preload("res://scripts/firebase_service.gd")
const INK := Color("#162632")
const PAPER := Color("#efe2c1")
const GOLD := Color("#c89b45")
const TEAL := Color("#286d70")
const WINE := Color("#783d45")
const CITIES := [
	{"name":"Torino", "pos":Vector3(-2.8,0,-4.6), "color":Color("#5079a7")},
	{"name":"Venezia", "pos":Vector3(2.5,0,-4.0), "color":Color("#438e76")},
	{"name":"Bologna", "pos":Vector3(0.8,0,-2.4), "color":Color("#c6813f")},
	{"name":"Firenze", "pos":Vector3(0.1,0,-0.9), "color":Color("#5e936b")},
	{"name":"Perugia", "pos":Vector3(1.3,0,0.4), "color":Color("#84659e")},
	{"name":"Roma", "pos":Vector3(0.3,0,2.1), "color":Color("#a94745")},
	{"name":"Napoli", "pos":Vector3(1.5,0,4.0), "color":Color("#3d929a")},
	{"name":"Palermo", "pos":Vector3(-0.2,0,7.1), "color":Color("#a45f88")}
]
const ACTIONS := ["Viaggio", "Amicizia", "Ispirazione", "Festività"]
const IDEA_NAMES := ["Arte", "Storia", "Filosofia", "Scienza"]

var rng := RandomNumberGenerator.new()
var firebase: FirebaseService
var world: Node3D
var camera: Camera3D
var hud: Control
var center: Control
var toast: Label
var phase_label: Label
var stats_label: Label
var log_label: RichTextLabel
var hand_box: HBoxContainer
var action_box: HBoxContainer
var city_buttons: Array[Button] = []
var mode := ""
var room_code := ""
var round_no := 1
var turn_no := 1
var current_player := 0
var awaiting_city := false
var players: Array = []
var deck: Array[String] = []
var hand: Array[String] = []
var played: Array[String] = []
var market := ["Passo deciso", "Conversazione brillante", "Taccuino curioso"]

func _ready() -> void:
	rng.randomize()
	firebase = Firebase.new()
	add_child(firebase)
	firebase.errore.connect(_notify)
	_build_world()
	_build_ui()
	_show_menu()

func _build_world() -> void:
	world = Node3D.new()
	add_child(world)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#0b1720")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#f2dca9")
	environment.ambient_light_energy = 0.7
	env.environment = environment
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55,-25,0)
	light.light_color = Color("#ffe1a6")
	light.light_energy = 1.25
	light.shadow_enabled = true
	world.add_child(light)
	var board := MeshInstance3D.new()
	var board_mesh := BoxMesh.new()
	board_mesh.size = Vector3(11,0.3,15)
	board.mesh = board_mesh
	board.position = Vector3(0,-0.25,1)
	board.material_override = _material(Color("#d6c79f"),0.85)
	world.add_child(board)
	for i in range(CITIES.size()-1): _make_route(CITIES[i].pos, CITIES[i+1].pos)
	for i in CITIES.size(): _make_city(i)
	_make_route(CITIES[0].pos, CITIES[2].pos)
	_make_route(CITIES[3].pos, CITIES[5].pos)
	camera = Camera3D.new()
	camera.position = Vector3(10,14,16)
	camera.look_at_from_position(camera.position, Vector3(0,0,1))
	camera.fov = 48
	world.add_child(camera)

func _material(color: Color, rough := 0.6) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = rough
	return material

func _make_route(a: Vector3, b: Vector3) -> void:
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	var distance := a.distance_to(b)
	cylinder.height = distance
	cylinder.top_radius = 0.055
	cylinder.bottom_radius = 0.055
	mesh.mesh = cylinder
	mesh.position = (a+b)/2.0 + Vector3(0,0.08,0)
	mesh.rotation.x = PI/2.0
	mesh.rotation.z = atan2(b.x-a.x,b.z-a.z)
	mesh.material_override = _material(Color("#8f6e3e"))
	world.add_child(mesh)

func _make_city(index: int) -> void:
	var data: Dictionary = CITIES[index]
	var base := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.height = 0.35
	cylinder.top_radius = 0.52
	cylinder.bottom_radius = 0.65
	base.mesh = cylinder
	base.position = data.pos + Vector3(0,0.18,0)
	base.material_override = _material(data.color)
	world.add_child(base)
	var dome := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.28
	sphere.height = 0.5
	dome.mesh = sphere
	dome.position = data.pos + Vector3(0,0.55,0)
	dome.material_override = _material(GOLD,0.25)
	world.add_child(dome)

func _build_ui() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hud)
	var title := Label.new()
	title.text = "TIMELESS JOURNEY"
	title.position = Vector2(34,22)
	title.add_theme_font_size_override("font_size",30)
	title.add_theme_color_override("font_color",GOLD)
	hud.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "IL GRAND TOUR ITALIANO"
	subtitle.position = Vector2(37,58)
	subtitle.add_theme_font_size_override("font_size",15)
	subtitle.add_theme_color_override("font_color",PAPER)
	hud.add_child(subtitle)
	phase_label = Label.new()
	phase_label.position = Vector2(34,100)
	phase_label.add_theme_font_size_override("font_size",18)
	phase_label.add_theme_color_override("font_color",Color.WHITE)
	hud.add_child(phase_label)
	stats_label = Label.new()
	stats_label.position = Vector2(34,132)
	stats_label.add_theme_font_size_override("font_size",17)
	stats_label.add_theme_color_override("font_color",PAPER)
	hud.add_child(stats_label)
	log_label = RichTextLabel.new()
	log_label.position = Vector2(28,590)
	log_label.size = Vector2(360,250)
	log_label.fit_content = false
	log_label.bbcode_enabled = true
	log_label.add_theme_font_size_override("normal_font_size",15)
	log_label.add_theme_color_override("default_color",PAPER)
	hud.add_child(log_label)
	action_box = HBoxContainer.new()
	action_box.position = Vector2(410,718)
	action_box.add_theme_constant_override("separation",12)
	hud.add_child(action_box)
	hand_box = HBoxContainer.new()
	hand_box.position = Vector2(410,790)
	hand_box.add_theme_constant_override("separation",8)
	hud.add_child(hand_box)
	toast = Label.new()
	toast.position = Vector2(1040,26)
	toast.size = Vector2(360,80)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.add_theme_font_size_override("font_size",16)
	toast.add_theme_color_override("font_color",Color("#f7d68a"))
	hud.add_child(toast)
	for i in CITIES.size():
		var button := Button.new()
		button.text = CITIES[i].name
		button.custom_minimum_size = Vector2(110,34)
		button.visible = false
		button.pressed.connect(_city_selected.bind(i))
		hud.add_child(button)
		city_buttons.append(button)
	center = Control.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(center)

func _show_menu() -> void:
	clear_children(center)
	for button in city_buttons: button.visible = false
	var veil := ColorRect.new()
	veil.color = Color(0.02,0.04,0.05,0.82)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.add_child(veil)
	var panel := VBoxContainer.new()
	panel.position = Vector2(455,185)
	panel.size = Vector2(530,570)
	panel.add_theme_constant_override("separation",14)
	center.add_child(panel)
	var heading := Label.new()
	heading.text = "Il tuo viaggio comincia a Torino"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size",28)
	heading.add_theme_color_override("font_color",GOLD)
	panel.add_child(heading)
	var intro := Label.new()
	intro.text = "Attraversa l’Italia, incontra viaggiatori illustri e raccogli idee da affidare ai tuoi diari. Cinque round, una storia irripetibile."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.custom_minimum_size.y = 88
	intro.add_theme_font_size_override("font_size",17)
	intro.add_theme_color_override("font_color",PAPER)
	panel.add_child(intro)
	_add_menu_button(panel,"Partita in solitario",func(): _start_game("solo",2))
	_add_menu_button(panel,"Gioca contro 3 viaggiatori IA",func(): _start_game("ia",4))
	_add_menu_button(panel,"Passa e gioca (2–5)",func(): _show_player_picker())
	_add_menu_button(panel,"Multiplayer online — crea stanza",func(): _create_online_room())
	_add_menu_button(panel,"Continua partita salvata",func(): _continue_game())
	var note := Label.new()
	note.text = "Interfaccia e carte in italiano · Salvataggio automatico locale\nFirebase abilita stanze e salvataggi cloud quando configurato"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size",14)
	note.add_theme_color_override("font_color",Color("#b9b6a7"))
	panel.add_child(note)

func _add_menu_button(parent: Control, text_value: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(500,52)
	button.add_theme_font_size_override("font_size",17)
	button.pressed.connect(callback)
	parent.add_child(button)

func _show_player_picker() -> void:
	clear_children(center)
	var box := VBoxContainer.new()
	box.position = Vector2(540,285)
	box.add_theme_constant_override("separation",12)
	center.add_child(box)
	var title := Label.new(); title.text = "Numero di viaggiatori"; title.add_theme_font_size_override("font_size",26); box.add_child(title)
	for count in range(2,6): _add_menu_button(box,str(count),_start_game.bind("locale",count))

func _create_online_room() -> void:
	room_code = "%04d" % rng.randi_range(1000,9999)
	if not firebase.enabled:
		_notify("Stanza %s pronta in modalità dimostrativa. Configura Firebase per invitare altri browser." % room_code)
	_start_game("online",2)

func _start_game(selected_mode: String, count: int) -> void:
	mode = selected_mode
	players.clear()
	for i in count:
		players.append({"name":"Tu" if i == 0 else ("Automa %s" % char(945+i-1) if selected_mode in ["solo","ia"] else "Viaggiatore %s" % (i+1)), "city":0, "coins":1 if i < 2 else 2, "vp":0, "ideas":[0,0,0,0], "explore":[], "friends":0, "journal":0, "is_ai": i > 0 and selected_mode in ["solo","ia"]})
	deck = ["Viaggio","Viaggio","Amicizia","Amicizia","Ispirazione","Ispirazione","Festività"]
	rng.shuffle(deck)
	hand = deck.duplicate()
	played.clear(); round_no = 1; turn_no = 1; current_player = 0; awaiting_city = false
	clear_children(center)
	_log("[color=#c89b45]La carrozza lascia Torino. Il Grand Tour ha inizio.[/color]")
	_layout_city_buttons()
	_refresh()
	_save()

func _layout_city_buttons() -> void:
	var positions := [Vector2(492,245),Vector2(716,266),Vector2(648,340),Vector2(610,410),Vector2(665,468),Vector2(615,535),Vector2(668,610),Vector2(570,680)]
	for i in city_buttons.size(): city_buttons[i].position = positions[i]

func _refresh() -> void:
	if players.is_empty(): return
	var player: Dictionary = players[current_player]
	phase_label.text = "ROUND %s / 5   ·   TURNO %s / 5" % [round_no,turn_no]
	stats_label.text = "%s  ·  %s  ·  %s monete  ·  %s PV\nIdee: Arte %s  Storia %s  Filosofia %s  Scienza %s\nDiario: %s pagine  ·  Esplorazioni: %s  ·  Amici: %s" % [player.name,CITIES[player.city].name,player.coins,player.vp,player.ideas[0],player.ideas[1],player.ideas[2],player.ideas[3],player.journal,player.explore.size(),player.friends]
	clear_children(action_box)
	clear_children(hand_box)
	if player.is_ai:
		var timer := get_tree().create_timer(0.65)
		timer.timeout.connect(_ai_turn)
		return
	for action in ACTIONS:
		var button := Button.new(); button.text = action; button.custom_minimum_size = Vector2(150,52); button.pressed.connect(_play_action.bind(action)); action_box.add_child(button)
	var down := Button.new(); down.text = "Carta coperta: +2 monete"; down.custom_minimum_size = Vector2(208,52); down.pressed.connect(_play_face_down); action_box.add_child(down)
	for card in hand:
		var label := Label.new(); label.text = card; label.custom_minimum_size = Vector2(112,34); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.add_theme_color_override("font_color",PAPER); hand_box.add_child(label)

func _play_action(action: String) -> void:
	if awaiting_city: return
	var index := hand.find(action)
	if index < 0:
		_notify("Non hai una carta %s in mano." % action)
		return
	hand.remove_at(index); played.append(action)
	match action:
		"Viaggio":
			awaiting_city = true
			for i in city_buttons.size(): city_buttons[i].visible = abs(i-int(players[current_player].city)) == 1
			_notify("Scegli una città adiacente")
			return
		"Amicizia":
			players[current_player].friends += 1
			players[current_player].coins += 1
			_log("%s conversa con un abitante di %s: un nuovo amico e 1 moneta." % [players[current_player].name,CITIES[players[current_player].city].name])
		"Ispirazione":
			var idea := rng.randi_range(0,3); players[current_player].ideas[idea] += 1; players[current_player].vp += 1
			_log("%s trova un’idea di %s e ottiene 1 PV." % [players[current_player].name,IDEA_NAMES[idea]])
		"Festività":
			var p: Dictionary = players[current_player]
			if p.ideas.max() > 0:
				var idea_index: int = p.ideas.find(p.ideas.max()); p.ideas[idea_index] -= 1; p.journal += 1; p.vp += 2 + p.journal
				_log("%s scrive nel Diario di viaggio: +%s PV." % [p.name,2+p.journal])
			else:
				p.coins += 2; _log("Nessuna idea da annotare: %s riceve 2 monete." % p.name)
	_resolve_chain(action)
	_end_turn()

func _resolve_chain(action: String) -> void:
	var repeats := played.count(action)-1
	if repeats <= 0: return
	players[current_player].coins += repeats
	players[current_player].vp += repeats
	_log("Catena di %s: %s riattivazioni, +%s monete e +%s PV." % [action,repeats,repeats,repeats])

func _play_face_down() -> void:
	if hand.is_empty(): return
	hand.pop_back(); played.append("Coperta"); players[current_player].coins += 2
	_log("%s gioca una carta coperta e guadagna 2 monete." % players[current_player].name)
	_end_turn()

func _city_selected(index: int) -> void:
	if not awaiting_city: return
	for button in city_buttons: button.visible = false
	awaiting_city = false
	var p: Dictionary = players[current_player]
	p.city = index
	if index not in p.explore:
		p.explore.append(index); p.vp += 1 + int(index/3)
		_log("%s raggiunge %s e la esplora: +%s PV." % [p.name,CITIES[index].name,1+int(index/3)])
	else: _log("%s torna a %s." % [p.name,CITIES[index].name])
	_resolve_chain("Viaggio")
	_end_turn()

func _ai_turn() -> void:
	if players.is_empty() or not players[current_player].is_ai: return
	var choices := ACTIONS.duplicate()
	var action: String = choices[rng.randi_range(0,choices.size()-1)]
	var p: Dictionary = players[current_player]
	match action:
		"Viaggio":
			if p.city < CITIES.size()-1: p.city += 1
			if p.city not in p.explore: p.explore.append(p.city)
			p.vp += 2
		"Amicizia": p.friends += 1; p.coins += 1
		"Ispirazione": p.ideas[rng.randi_range(0,3)] += 1; p.vp += 1
		"Festività":
			if p.ideas.max() > 0: p.journal += 1; p.vp += 2+p.journal
	_log("%s sceglie %s a %s." % [p.name,action,CITIES[p.city].name])
	_end_turn()

func _end_turn() -> void:
	current_player += 1
	if current_player >= players.size():
		current_player = 0; turn_no += 1
		if turn_no > 5: _end_round(); return
	_save(); _refresh()

func _end_round() -> void:
	for p in players:
		if p.city == 7: p.vp += 3
	_log("[color=#c89b45]Fine round %s: mercato e viaggiatori illustri risolti.[/color]" % round_no)
	if round_no >= 5:
		_finish_game(); return
	round_no += 1; turn_no = 1
	hand = deck.duplicate(); rng.shuffle(hand); played.clear()
	_save(); _refresh()

func _finish_game() -> void:
	for p in players:
		var exploration_score: int = [0,1,2,3,4,6,9,13,18][min(p.explore.size(),8)]
		p.vp += exploration_score + p.journal * (p.journal+1)/2 + p.friends
	players.sort_custom(func(a,b): return a.vp > b.vp)
	clear_children(action_box); clear_children(hand_box)
	for button in city_buttons: button.visible = false
	var panel := VBoxContainer.new(); panel.position = Vector2(480,250); panel.size = Vector2(500,450); panel.add_theme_constant_override("separation",12); center.add_child(panel)
	var title := Label.new(); title.text = "IL GRAND TOUR È COMPIUTO"; title.add_theme_font_size_override("font_size",28); title.add_theme_color_override("font_color",GOLD); panel.add_child(title)
	for i in players.size():
		var row := Label.new(); row.text = "%s. %s — %s PV" % [i+1,players[i].name,players[i].vp]; row.add_theme_font_size_override("font_size",22); row.add_theme_color_override("font_color",PAPER); panel.add_child(row)
	_add_menu_button(panel,"Nuovo viaggio",_show_menu)
	_save()

func _save() -> void:
	if players.is_empty(): return
	var data := {"mode":mode,"room":room_code,"round":round_no,"turn":turn_no,"current":current_player,"players":players,"deck":deck,"hand":hand,"played":played}
	firebase.salva_locale(data)
	if mode == "online" and room_code != "": firebase.salva_cloud(room_code,data)

func _continue_game() -> void:
	var data := firebase.carica_locale()
	if data.is_empty(): _notify("Nessuna partita salvata"); return
	mode = data.get("mode","locale"); room_code = data.get("room",""); round_no = int(data.get("round",1)); turn_no = int(data.get("turn",1)); current_player = int(data.get("current",0)); players = data.get("players",[]); deck.assign(data.get("deck",[])); hand.assign(data.get("hand",[])); played.assign(data.get("played",[]))
	clear_children(center); _layout_city_buttons(); _log("Partita ripristinata."); _refresh()

func _notify(message: String) -> void:
	toast.text = message
	var timer := get_tree().create_timer(4.0)
	timer.timeout.connect(func(): if toast.text == message: toast.text = "")

func _log(message: String) -> void:
	log_label.append_text(message+"\n")
	log_label.scroll_to_line(max(0,log_label.get_line_count()-5))

func clear_children(node: Node) -> void:
	for child in node.get_children(): child.queue_free()
