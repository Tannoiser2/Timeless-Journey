# Timeless Journeys: The Italian Grand Tour - versione digitale

*Timeless Journeys: The Italian Grand Tour* di Nestore Mangone e Andrea Robbiani (Lirius Games, illustrazioni di Laura Guglielmo), in Godot 4.7, per la ludoteca digitale.

Da Torino a Palermo sulle orme dei primi turisti del Grand Tour: carte in catena, esplorazioni, abitanti, lettere, caffè letterari, Diari di Viaggio e Viaggiatori Celebri della Gazzetta.

## Cosa c'è

- **Regolamento italiano completo**: cinque round con Fase di Azione, Viaggiatori Celebri, Mercato e Riorganizzazione; carte scoperte e coperte, catene di azioni, mercato a livelli secondo le categorie giocate, limite di 8 carte, punteggio finale (tessere Esplorazione, Diari, carte Avanzate, Affinità Elettive, maggioranze della Gazzetta), parità vinte da chi è più a sud.
- **Tutto il materiale**: tabellone con le strade e i loro costi (navi da Palermo comprese), 8 plance Città con i caffè, 12 tessere Favore, 48 tessere Esplorazione, 7 tessere Amico, 16 Diari di Viaggio, 4 lati della Gazzetta, 12 Viaggiatori Celebri con le loro abilità, 81 carte Azione Avanzata, Dipinti di Vigée Le Brun, segnalini Esperienza.
- **Modi di scegliere i viaggiatori**: partita introduttiva, Immersione Storica (quattro periodi), Timeless Jam (a caso), Viaggio da Esperti (li scegli tu).
- **Da 1 a 5 giocatori**: persone sullo stesso dispositivo, computer, persone online (stanze su Firebase, radice `timeless`).
- **Solitario ufficiale** con i due Automi (Alfa e Beta), azioni fallite che svuotano il Mercato e valutazione finale del viaggio.
- **Espansioni**: Napoleone (Pattuglie Austriache, Soldati Francesi, battaglie, Napoleone, Paolina Bonaparte, Ugo Foscolo), Una Notte di Terrore a Villa Diodati (i quattro Mostri), I Romantici (Rousseau, Stendhal, Andersen, Liszt, Percy Shelley).
- **Tabellone in 2D e in 3D**: si sposta, si ingrandisce e (in 3D) si ruota anche con le dita su iPad.
- Partita salvata a ogni mossa nel browser e su Firebase a ogni round.

## Note sul materiale

- La grafica viene dal modulo Tabletop Simulator. Il modulo usa una versione più vecchia delle carte: le carte 47, 50 e 54 sono state corrette (3 PV ogni 2 carte, come nel regolamento italiano), le carte 15, 16, 31, 32 e 59 dell'edizione italiana sono state composte con le icone originali, e il numero in basso a destra è quello del regolamento italiano (`tools/componi_carte.py`).
- Le espansioni (Mostri, Villa Diodati, carte Battaglia, carte Andersen, Viaggiatori, Pattuglie e Soldati) vengono dalle scansioni dell'edizione da collezione; le sagome dei nuovi viaggiatori sono ricavate dal ritratto delle loro carte.

## Struttura

- `scripts/motore.gd` - le regole (stato JSON puro, riproducibile con un seme), Automi del solitario, espansioni
- `scripts/ia.gd` - il giocatore guidato dal computer
- `scripts/mappa.gd`, `scripts/mappa3d.gd` - il tabellone in 2D e in 3D
- `scripts/plancia.gd` - plance delle città, Gazzetta, Mercato, Diari
- `scripts/mano.gd`, `scripts/giocatori.gd`, `scripts/partita.gd`, `scripts/main.gd` - interfaccia, partita, menu, online
- `assets/dati/gioco.json` - i dati del gioco, generati da `tools/dati.py`
- `tools/prepara_grafica.py`, `tools/componi_carte.py` - preparazione della grafica dal modulo TTS

## Prove

- `godot --headless --path . -s tests/sim.gd -- 3 3` - partite automatiche (partite, giocatori, espansioni `ndr`, `solo`)
- `xvfb-run -a godot --path . -s tests/foto.gd -- /tmp/foto 1920 1080` - fotografie dell'interfaccia
- `python3 tools/controlla_glifi.py` - controllo dei caratteri nei font

## Pubblicazione

Solo a richiesta: Actions, Pubblica, Run workflow, oppure un commit con `[pubblica]` nel messaggio. La ludoteca privata su Cloudflare lo prende da sé.
