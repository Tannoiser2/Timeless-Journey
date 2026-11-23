extends SceneTree
func _init() -> void:
	var tot := 0
	for k in 8:
		var gs: Array = []
		for i in 3 + k % 3:
			gs.append({"nome": "IA %d" % i, "tipo": "ia", "colore": Dati.d()["colori"][i]})
		var vg: Array = [["andersen", "napoleone", "liszt"], ["paolina", "foscolo", "andersen"], ["stendhal", "rousseau", "percy_shelley"], ["andersen", "craven", "napoleone"]][k % 4]
		var s := Motore.nuova({"giocatori": gs, "seme": 300 + k, "esp": {"napoleone": true, "diodati": true, "romantici": true}, "viaggiatori": vg})
		var n := 0
		var andersen := 0
		while not s["fine"] and n < 5000:
			var id := IA.scegli(s, 1)
			if id.begins_with("and:"): andersen += 1
			if id == "" or not Motore.applica(s, id):
				print("BLOCCO ", s["attesa"]); break
			n += 1
		print(k, " fine=", s["fine"], " decisioni=", n, " andersen=", andersen, " ", s["punteggi"].map(func(x): return x["totale"]) if s["fine"] else [])
	quit()
