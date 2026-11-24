extends SceneTree
## Fotografia del tavolo TV: xvfb-run -a godot --path . -s tests/foto_tavolo.gd -- /tmp/ft 1920 1080
func _foto(dir: String, nome: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, nome])

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var dir := a[0] if a.size() else "/tmp/ft"
	if a.size() >= 3:
		root.size = Vector2i(int(a[1]), int(a[2]))
	DirAccess.make_dir_recursive_absolute(dir)
	await process_frame
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.3).timeout
	main._metti_tavolo(true)
	main._impostazioni()
	await create_timer(0.3).timeout
	await _foto(dir, "0_impostazioni")
	var gs := [{"nome": "Stefano", "colore": "rosso", "tipo": "rete", "uid": "u1"}, {"nome": "Giulia", "colore": "verde", "tipo": "rete", "uid": "u2"},
		{"nome": "Marco", "colore": "blu", "tipo": "ia"}, {"nome": "Lucia", "colore": "giallo", "tipo": "ia"}]
	var s := Motore.nuova({"giocatori": gs, "seme": 77, "esp": {"napoleone": true}, "modo_viaggiatori": "C"})
	main._gioca(s, "tavolo", 0)
	var p = main.partita
	# i telefoni rispondono come il computer
	var t0 := Time.get_ticks_msec()
	var fatto := false
	while Time.get_ticks_msec() - t0 < 200000:
		var chi: int = p.chi_deve()
		if chi >= 0 and p.s["giocatori"][chi]["tipo"] == "rete":
			var pk: Dictionary = p.pacchetto()
			var id := IA.scegli(p.s, 1)
			p.mossa_remota({"id": id, "p": chi, "n": pk["n"]}, p.s["giocatori"][chi]["uid"])
		await create_timer(0.03).timeout
		if int(p.s["round"]) == 4 and not fatto:
			fatto = true
			var g0: Dictionary = p.s["giocatori"][0]
			g0["diari"][0]["slot"][0] = "Arte"
			g0["diari"][0]["slot"][3] = "Storia"
			g0["diari"][1]["slot"][6] = "t:%s_2" % g0["diari"][1]["id"].substr(2)
			g0["diari"][1]["slot"][7] = "a:Roma_0"
			p._aggiorna()
			await _foto(dir, "1_tavolo")
			p._viaggiatore(1)
			await create_timer(0.2).timeout
			await _foto(dir, "2_viaggiatore")
			p._chiudi_popup()
			p._ingrandisci_citta("Roma")
			await create_timer(0.2).timeout
			await _foto(dir, "3_citta")
			p._chiudi_popup()
			print(JSON.stringify(p.pacchetto()).length())
			break
	quit()
