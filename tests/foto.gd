extends SceneTree
## Fotografie dell'interfaccia: xvfb-run -a godot --path . -s tests/foto.gd -- cartella larghezza altezza [esp]
func _foto(dir: String, nome: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, nome])
	print("foto ", nome)

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var dir := a[0] if a.size() else "/tmp/foto"
	if a.size() >= 3:
		root.size = Vector2i(int(a[1]), int(a[2]))
	var esps := a[3] if a.size() >= 4 else ""
	DirAccess.make_dir_recursive_absolute(dir)
	await process_frame
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.5).timeout
	await _foto(dir, "0_menu")
	main._impostazioni()
	await create_timer(0.3).timeout
	await _foto(dir, "1_impostazioni")
	var gs := [{"nome": "Stefano", "colore": "rosso", "tipo": "umano"}, {"nome": "Giulia", "colore": "verde", "tipo": "ia"},
		{"nome": "Marco", "colore": "blu", "tipo": "ia"}]
	var esp := {"napoleone": esps.contains("n"), "diodati": esps.contains("d"), "romantici": esps.contains("r")}
	var s := Motore.nuova({"giocatori": gs, "seme": 4242, "esp": esp, "modo_viaggiatori": "D" if esps == "" else "caso", "viaggiatori": ["andersen", "napoleone", "liszt"] if esps != "" else []})
	main._gioca(s, "locale", 0)
	var p: Partita = main.partita
	await create_timer(0.6).timeout
	await _foto(dir, "2_inizio")
	if a.size() >= 5 and a[4] == "breve":
		p._vista("gazzetta")
		await _foto(dir, "2_gazzetta")
		if esps != "":
			p._vista("espansioni")
			await _foto(dir, "2_espansioni")
		p._cambia_3d()
		await create_timer(0.5).timeout
		await _foto(dir, "2_3d")
		var m3: Mappa3D = p.mappa3d
		m3.yaw = 40.0
		m3.pitch = 18.0
		m3.dist = 4.0
		m3.bersaglio = m3.a3d(Vector2(464, 620))
		m3._camera()
		await create_timer(0.3).timeout
		await _foto(dir, "2_3d_vicino")
		m3.yaw = -60.0
		m3._camera()
		await create_timer(0.3).timeout
		await _foto(dir, "2_3d_vicino2")
		quit()
		return
	# il giocatore gioca come il computer, gli altri giocano da soli
	var t0 := Time.get_ticks_msec()
	var foto_fatte := {}
	while not p.s["fine"] and Time.get_ticks_msec() - t0 < 240000:
		var chi := p.chi_deve()
		if chi == 0:
			var tipo: String = p.s["attesa"]["tipo"]
			if not foto_fatte.has(tipo) and tipo in ["esplora", "conversa", "discuti", "scrivi", "compra", "mercato", "muovi", "catena", "esperienza", "lettera"]:
				foto_fatte[tipo] = true
				p._aggiorna()
				await create_timer(0.2).timeout
				await _foto(dir, "3_%s" % tipo)
			var id := IA.scegli(p.s, 2)
			p._applica(id)
		await create_timer(0.05).timeout
		if int(p.s["round"]) == 3 and not foto_fatte.has("r3"):
			foto_fatte["r3"] = true
			await _foto(dir, "4_round3")
			p._vista("gazzetta")
			await _foto(dir, "4_gazzetta")
			p._vista("diari")
			await _foto(dir, "4_diari")
			p._vista("mercato")
			await _foto(dir, "4_mercato")
			p._cambia_3d()
			await create_timer(0.5).timeout
			await _foto(dir, "4_3d")
			p._cambia_3d()
			p._vista("citta")
	await create_timer(0.5).timeout
	await _foto(dir, "5_fine")
	quit()
