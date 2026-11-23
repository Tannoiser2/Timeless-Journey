class_name Mappa3D
extends SubViewportContainer
## Il tabellone in 3D sul tavolo: pedine a forma di meeple, sagome dei viaggiatori in piedi, pile di tessere.
## Mouse: trascina per ruotare, tasto destro per spostare, rotella per lo zoom.
## Tocco: un dito ruota, due dita pizzicano (zoom), girano (rotazione) e spostano.

signal nodo_cliccato(nodo: String)
signal citta_cliccata(citta: String)

const SC := 0.01   # pixel del tabellone -> metri

var vp: SubViewport
var cam: Camera3D
var radice: Node3D
var dinamici: Node3D
var s: Dictionary = {}
var evidenzia: Dictionary = {}
var yaw := 0.0
var pitch := 62.0
var dist := 23.0
var bersaglio := Vector3(0, 0, 0)
var _tocchi := {}
var _g0 := {}
var _premuto := false
var _destro := false
var _mosso := 0.0
var _anelli: Array = []
var _t := 0.0
var _costruito := false

func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.handle_input_locally = false
	add_child(vp)

func _costruisci() -> void:
	_costruito = true
	radice = Node3D.new()
	vp.add_child(radice)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("1c1510")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d8c8b0")
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.85
	env.tonemap_white = 1.6
	we.environment = env
	radice.add_child(we)
	var luce := DirectionalLight3D.new()
	luce.rotation_degrees = Vector3(-52, 35, 0)
	luce.light_energy = 0.5
	luce.light_color = Color("fff1dc")
	luce.shadow_enabled = true
	luce.shadow_blur = 2.0
	radice.add_child(luce)
	var riempi := DirectionalLight3D.new()
	riempi.rotation_degrees = Vector3(-35, -150, 0)
	riempi.light_energy = 0.12
	radice.add_child(riempi)
	# tavolo
	var tav := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 30)
	tav.mesh = pm
	var mt := StandardMaterial3D.new()
	mt.albedo_texture = Stile.tex("res://assets/img/plance/tavolo.webp")
	mt.roughness = 1.0
	mt.metallic_specular = 0.0
	mt.uv1_scale = Vector3(1, 1, 1)
	tav.material_override = mt
	tav.position.y = -0.06
	radice.add_child(tav)
	# tabellone con spessore
	var corpo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(10.8, 0.05, 18.25)
	corpo.mesh = bm
	var mc := StandardMaterial3D.new()
	mc.albedo_color = Color("2a1d14")
	corpo.material_override = mc
	corpo.position.y = -0.025
	radice.add_child(corpo)
	var tab := MeshInstance3D.new()
	var pt := PlaneMesh.new()
	pt.size = Vector2(10.8, 18.25)
	tab.mesh = pt
	var mb := StandardMaterial3D.new()
	mb.albedo_texture = Stile.tex("res://assets/img/plance/tabellone.webp")
	mb.roughness = 0.9
	mb.metallic_specular = 0.0
	mb.roughness = 1.0
	tab.material_override = mb
	tab.position.y = 0.002
	radice.add_child(tab)
	cam = Camera3D.new()
	cam.fov = 42
	radice.add_child(cam)
	dinamici = Node3D.new()
	radice.add_child(dinamici)
	_camera()

func a3d(px: Vector2) -> Vector3:
	return Vector3((px.x - 540.0) * SC, 0, (px.y - 912.5) * SC)

func _camera() -> void:
	if cam == null:
		return
	pitch = clampf(pitch, 18, 89)
	dist = clampf(dist, 4, 30)
	var dir := Vector3(sin(deg_to_rad(yaw)) * cos(deg_to_rad(pitch)), sin(deg_to_rad(pitch)), cos(deg_to_rad(yaw)) * cos(deg_to_rad(pitch)))
	cam.position = bersaglio + dir * dist
	cam.look_at(bersaglio, Vector3.UP)

func aggiorna(stato: Dictionary, ev: Dictionary) -> void:
	if not _costruito:
		_costruisci()
	s = stato
	evidenzia = ev
	for c in dinamici.get_children():
		c.queue_free()
	_anelli = []
	if s.is_empty():
		return
	var D := Dati.d()
	# pedine
	var per_nodo := {}
	for p in s["giocatori"].size():
		var n: String = s["giocatori"][p]["pos"]
		if not per_nodo.has(n): per_nodo[n] = []
		per_nodo[n].append(Stile.colore(s["giocatori"][p]["colore"]))
	for au in s.get("automi", []):
		if not per_nodo.has(au["pos"]): per_nodo[au["pos"]] = []
		per_nodo[au["pos"]].append(Stile.colore(au["colore"]))
	for n2 in per_nodo:
		var base := a3d(Vector2(D["nodi"][n2][0], D["nodi"][n2][1]))
		var lista: Array = per_nodo[n2]
		for i in lista.size():
			var m := _meeple(lista[i])
			m.position = base + Vector3((i - (lista.size() - 1) / 2.0) * 0.32, 0, (i % 2) * 0.12)
			dinamici.add_child(m)
	# viaggiatori in piedi
	var per_citta := {}
	for v in Motore.viaggiatori_pos(s):
		if not per_citta.has(v[1]): per_citta[v[1]] = []
		per_citta[v[1]].append(v[0])
	for c in per_citta:
		var st := a3d(Vector2(D["stelle"][c][0], D["stelle"][c][1]))
		var k := 0
		for vid in per_citta[c]:
			var sp := Sprite3D.new()
			var tx := Stile.tex("res://assets/img/viaggiatori/sagoma_%s.webp" % vid)
			if tx == null:
				tx = Stile.tex("res://assets/img/viaggiatori/sagoma_byron.webp")
				sp.modulate = Color(0.75, 0.7, 0.65)
			sp.texture = tx
			sp.pixel_size = 1.25 / tx.get_height()
			sp.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
			sp.shaded = false
			sp.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
			sp.position = st + Vector3(k * 0.45, 0.62, k * 0.1)
			dinamici.add_child(sp)
			var basetta := MeshInstance3D.new()
			var cy := CylinderMesh.new()
			cy.top_radius = 0.22
			cy.bottom_radius = 0.24
			cy.height = 0.06
			basetta.mesh = cy
			var mm := StandardMaterial3D.new()
			mm.albedo_color = Color("3b2a1c")
			basetta.material_override = mm
			basetta.position = st + Vector3(k * 0.45, 0.03, k * 0.1)
			dinamici.add_child(basetta)
			k += 1
	# pile di tessere esplorazione
	for c2 in D["citta"]:
		var n3: int = s["citta"][c2]["esplora"].size()
		if n3 <= 0: continue
		var q := a3d(Vector2(D["nodi"][c2][0], D["nodi"][c2][1]) + Vector2(-52, 36))
		var pila := MeshInstance3D.new()
		var bx := BoxMesh.new()
		bx.size = Vector3(0.36, 0.03 * n3, 0.36)
		pila.mesh = bx
		var mx := StandardMaterial3D.new()
		mx.albedo_texture = Stile.tex("res://assets/img/tessere/espl_%s_retro.webp" % c2)
		mx.uv1_triplanar = true
		mx.uv1_scale = Vector3(2.7, 2.7, 2.7)
		pila.material_override = mx
		pila.position = q + Vector3(0, 0.015 * n3, 0)
		dinamici.add_child(pila)
	# pattuglie
	for c3 in D["citta"]:
		var pc: String = s["citta"][c3]["pattuglia"]
		if pc == "": continue
		var sh := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.18
		cyl.bottom_radius = 0.18
		cyl.height = 0.08
		sh.mesh = cyl
		var ms := StandardMaterial3D.new()
		ms.albedo_color = Color("c8302a")
		sh.material_override = ms
		sh.position = a3d(Vector2(D["stelle"][c3][0], D["stelle"][c3][1]) + Vector2(0, 50)) + Vector3(0, 0.04, 0)
		dinamici.add_child(sh)
		var dot := MeshInstance3D.new()
		var cyl2 := CylinderMesh.new()
		cyl2.top_radius = 0.09
		cyl2.bottom_radius = 0.09
		cyl2.height = 0.1
		dot.mesh = cyl2
		var md := StandardMaterial3D.new()
		md.albedo_color = Stile.COLORE_CAT[pc]
		dot.material_override = md
		dot.position = sh.position + Vector3(0, 0.01, 0)
		dinamici.add_child(dot)
	# luoghi da scegliere
	for n4 in evidenzia:
		if not D["nodi"].has(n4): continue
		var an := MeshInstance3D.new()
		var tor := TorusMesh.new()
		tor.inner_radius = 0.3
		tor.outer_radius = 0.38
		an.mesh = tor
		var ma := StandardMaterial3D.new()
		ma.albedo_color = Color(1.0, 0.8, 0.25)
		ma.emission_enabled = true
		ma.emission = Color(0.9, 0.6, 0.1)
		ma.emission_energy_multiplier = 0.6
		an.material_override = ma
		an.position = a3d(Vector2(D["nodi"][n4][0], D["nodi"][n4][1])) + Vector3(0, 0.05, 0)
		dinamici.add_child(an)
		_anelli.append(an)

func _meeple(col: Color) -> Node3D:
	var m := CSGPolygon3D.new()
	var pts := PackedVector2Array([
		Vector2(-12, -48), Vector2(12, -48), Vector2(16, -36), Vector2(13, -24), Vector2(38, -14), Vector2(42, -2),
		Vector2(20, 0), Vector2(28, 44), Vector2(8, 44), Vector2(0, 22), Vector2(-8, 44), Vector2(-28, 44),
		Vector2(-20, 0), Vector2(-42, -2), Vector2(-38, -14), Vector2(-13, -24), Vector2(-16, -36)])
	var p2 := PackedVector2Array()
	for p in pts:
		p2.append(Vector2(p.x, -p.y) * 0.0062)
	m.polygon = p2
	m.depth = 0.14
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.55
	m.material = mat
	var nodo := Node3D.new()
	m.position = Vector3(0, 44 * 0.0062, 0.07)
	nodo.add_child(m)
	nodo.rotation.y = deg_to_rad(yaw)
	return nodo

func _process(d: float) -> void:
	_t += d
	for a in _anelli:
		if is_instance_valid(a):
			var k := 1.0 + 0.12 * sin(_t * 5)
			a.scale = Vector3(k, 1, k)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed:
			_tocchi[e.index] = e.position
		else:
			_tocchi.erase(e.index)
		_g0 = {}
		accept_event()
		return
	if e is InputEventScreenDrag:
		var prima: Dictionary = _tocchi.duplicate()
		_tocchi[e.index] = e.position
		if _tocchi.size() >= 2:
			var k: Array = _tocchi.keys()
			var a: Vector2 = _tocchi[k[0]]
			var b: Vector2 = _tocchi[k[1]]
			if _g0.is_empty():
				_g0 = {"d": (a - b).length(), "ang": (b - a).angle(), "mid": (a + b) / 2, "dist": dist, "yaw": yaw}
			else:
				var dd := (a - b).length()
				if dd > 10:
					dist = _g0["dist"] * _g0["d"] / dd
				yaw = _g0["yaw"] + rad_to_deg((b - a).angle() - _g0["ang"])
				var mid: Vector2 = (a + b) / 2
				_sposta(mid - _g0["mid"])
				_g0["mid"] = mid
			_mosso += 20
		else:
			yaw -= e.relative.x * 0.3
			pitch += e.relative.y * 0.2
			_mosso += e.relative.length()
		_camera()
		_aggiorna_meeple()
		accept_event()
		return
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			dist /= 1.1
			_camera()
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			dist *= 1.1
			_camera()
		elif e.button_index == MOUSE_BUTTON_LEFT:
			_premuto = e.pressed
			if e.pressed:
				_mosso = 0
			elif _mosso < 8 and _tocchi.size() <= 1:
				_clic(e.position)
		elif e.button_index == MOUSE_BUTTON_RIGHT:
			_destro = e.pressed
		accept_event()
		return
	if e is InputEventMouseMotion and _tocchi.is_empty():
		if _premuto:
			_mosso += e.relative.length()
			if _mosso > 5:
				yaw -= e.relative.x * 0.3
				pitch += e.relative.y * 0.2
				_camera()
				_aggiorna_meeple()
		elif _destro:
			_sposta(e.relative)
			_camera()
		accept_event()

func _aggiorna_meeple() -> void:
	if dinamici == null:
		return
	for c in dinamici.get_children():
		if c.get_child_count() == 1 and c.get_child(0) is CSGPolygon3D:
			c.rotation.y = deg_to_rad(yaw)

func _sposta(rel: Vector2) -> void:
	var f := dist * 0.0016
	var destra := Vector3(cos(deg_to_rad(yaw)), 0, -sin(deg_to_rad(yaw)))
	var avanti := Vector3(-sin(deg_to_rad(yaw)), 0, -cos(deg_to_rad(yaw)))
	bersaglio -= destra * rel.x * f
	bersaglio -= avanti * rel.y * f * -1
	bersaglio.x = clampf(bersaglio.x, -6, 6)
	bersaglio.z = clampf(bersaglio.z, -10, 10)

func _clic(pos: Vector2) -> void:
	if cam == null or s.is_empty():
		return
	var sc := Vector2(vp.size) / size
	var o := cam.project_ray_origin(pos * sc)
	var d := cam.project_ray_normal(pos * sc)
	if absf(d.y) < 0.001:
		return
	var t := -o.y / d.y
	var hit := o + d * t
	var px := Vector2(hit.x / SC + 540.0, hit.z / SC + 912.5)
	var D := Dati.d()
	var migliore := ""
	var dmin := 60.0
	for n in D["nodi"]:
		var q := Vector2(D["nodi"][n][0], D["nodi"][n][1])
		if q.distance_to(px) < dmin:
			dmin = q.distance_to(px)
			migliore = n
	if migliore == "":
		return
	if evidenzia.has(migliore):
		nodo_cliccato.emit(migliore)
	elif Dati.e_citta(migliore):
		citta_cliccata.emit(migliore)
