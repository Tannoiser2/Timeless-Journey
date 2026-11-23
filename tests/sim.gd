extends SceneTree
## Partite automatiche: godot --headless --path . -s tests/sim.gd -- [partite] [giocatori] [esp: n,d,r] [solo]
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var partite := int(a[0]) if a.size() > 0 else 3
	var ng := int(a[1]) if a.size() > 1 else 3
	var esp_s := a[2] if a.size() > 2 else ""
	var solo := a.size() > 3 and a[3] == "solo"
	var livello := int(a[4]) if a.size() > 4 else 2
	var tot_t := 0
	for k in partite:
		var gs: Array = []
		for i in ng:
			gs.append({"nome": "IA %d" % (i + 1), "tipo": "ia", "colore": Dati.d()["colori"][i]})
		var esp := {"napoleone": esp_s.contains("n"), "diodati": esp_s.contains("d"), "romantici": esp_s.contains("r")}
		var mv: String = ["caso", "A", "B", "C", "D", "intro"][k % 6]
		var s := Motore.nuova({"giocatori": gs, "solo": solo, "seme": 1000 + k * 77, "esp": esp, "modo_viaggiatori": mv})
		var t0 := Time.get_ticks_msec()
		var passi := 0
		var conta := {}
		while not s["fine"] and passi < 4000:
			var t: String = s["attesa"].get("tipo", "?")
			conta[t] = int(conta.get(t, 0)) + 1
			var id := IA.scegli(s, livello)
			if id == "" or not Motore.applica(s, id):
				print("BLOCCO: ", s["attesa"], " opz=", Motore.opzioni(s))
				break
			passi += 1
		var dt := Time.get_ticks_msec() - t0
		tot_t += dt
		var pt: Array = s.get("punteggi", [])
		var riga := "partita %d (%s, viaggiatori %s): %d decisioni, %d ms, round %d, fine=%s  " % [k, s["gazzetta"], ",".join(s["viaggiatori"]), passi, dt, s["round"], s["fine"]]
		for p in pt.size():
			riga += " %d[%d tr %d es %d di %d ca %d ma %d]" % [p, pt[p]["totale"], pt[p]["tracciato"], pt[p]["esplorazioni"], pt[p]["diari"], pt[p]["carte"], pt[p]["maggioranze"]]
		print(riga)
		if k == 0:
			print(conta)
	print("media ms: ", tot_t / maxi(1, partite))
	quit()
