class_name Regole
extends RefCounted
## Riassunto delle regole mostrato nel gioco.

const TESTO := """[b]Scopo[/b]
Siete i primi turisti del Grand Tour: in cinque round attraversate l’Italia da Torino a Palermo raccogliendo idee, amicizie e scoperte. Vince chi ha più Punti Vittoria (PV) alla fine.

[b]Il round[/b]
1. [b]Azioni[/b]: a turno ognuno gioca una carta dalla mano, finché tutti ne hanno giocate 5.
2. [b]Viaggiatori Celebri[/b]: si applicano le abilità di fine round dei tre viaggiatori (da sinistra a destra).
3. [b]Mercato[/b]: dal giocatore alla destra del primo, in senso antiorario, ognuno prende gratis una carta Azione Avanzata. Contano le categorie diverse giocate nel round (Viaggio, Amicizia, Ispirazione, Festività, carta coperta): 2 categorie = livello I, 3 = fino al II, 4 = qualsiasi livello.
4. [b]Riorganizzazione[/b]: il Mercato si rinnova, ognuno riprende in mano le carte giocate (massimo 8: le altre escono dal gioco), i viaggiatori si spostano nella città della riga successiva della Gazzetta e il segnalino Primo Giocatore passa a sinistra.

[b]Giocare una carta[/b]
Scoperta: se è la prima carta di quella categoria nel round se ne usa l’effetto. Se avevi già giocato una carta della stessa categoria parte una [b]catena di azioni[/b]: puoi attivare tutte le carte di quella categoria nella tua area, nell’ordine che vuoi (anche quella appena giocata). Ogni effetto è facoltativo.
Coperta: qualsiasi carta, per 2 monete, oppure per muoverti di un passo (pagando la strada), oppure per comprare una carta dal Mercato (livello I gratis, II 2 monete, III 5 monete). Una carta coperta non fa mai partire una catena ma conta come categoria per il Mercato. Anche la carta in cima a ogni mazzo del Mercato si può prendere.

[b]Le azioni[/b]
[b]Movimento[/b]: segui una strada fino al luogo vicino; se c’è una moneta disegnata la paghi. Le navi da Palermo portano direttamente a Roma o Venezia per 6 monete.
[b]Esplorazione[/b] (in città): guardi le tessere coperte e ne prendi una (una sola per città), oppure prendi la ricompensa stampata sulla plancia. Le tessere si attivano una volta sola, quando vuoi nel tuo turno.
[b]Conversare[/b] (in città): parli con uno dei due abitanti e ottieni il favore sopra di lui; poi puoi prendere la sua tessera Amico oppure lasciargli una Lettera. Oppure incontri un Viaggiatore Celebre che è in città: metti un segnalino Esperienza nella sua colonna della Gazzetta, nella riga del round, e ottieni il premio.
[b]Inviare una lettera[/b]: ottieni il favore di un abitante di un’altra città dove hai una tua Lettera.
[b]Idee[/b]: prendi il segnalino Idea indicato (Arte, Storia, Filosofia, Scienza).
[b]Discutere al caffè[/b]: dove sei o dove hai una Lettera, paghi le Idee richieste, metti un segnalino Caffè nello spazio libero più alto e prendi i PV.
[b]Scrivere nel Diario[/b]: sposti un’Idea, una tessera Esplorazione della città giusta o una tessera Amico in uno spazio libero dei tuoi due Diari di Viaggio.

[b]Fine della partita[/b]
Dopo il Mercato del quinto round si contano: le tessere Esplorazione raccolte (1-8 tessere: 1, 2, 3, 4, 6, 9, 13, 18 PV), ogni Diario secondo gli spazi riempiti (1-8: 2, 4, 6, 9, 12, 15, 21, 28 PV), i PV delle carte Avanzate in mano, le Affinità Elettive (2 PV ciascuna, 6 se entrambe con lo stesso viaggiatore) e le maggioranze di segnalini Esperienza in ogni colonna della Gazzetta (5/3/1 PV; in due solo il primo; una Notte da Ricordare conta doppio). In caso di parità vince chi è più a sud.

[b]Solitario[/b]
Giochi contro due Automi che non fanno punti ma occupano spazi: rivelano una carta a ogni turno ed eseguono l’azione della categoria (Viaggio: esplorano e si spostano verso sud; Amicizia: Lettere, tessere Amico, Esperienze; Ispirazione: caffè). Quando falliscono un’azione tolgono una carta di livello II o III dal Mercato. Alla fine: fino a 40 PV Turista Smarrito, 41-80 Esploratore Curioso, 81-110 Illustre Grand Tourist, oltre 110 Leggenda del Grand Tour.

[b]Espansioni[/b]
[b]Napoleone[/b]: le Pattuglie Austriache bloccano nella loro città la prima carta della loro categoria (la carta elimina la Pattuglia invece di dare il suo effetto). Una volta per turno puoi pagare 2 monete per un Soldato Francese; a fine round la battaglia è vinta se i Soldati sono almeno quanti i giocatori più il modificatore della carta Battaglia. Premi per ogni Soldato, PV ai primi due se si vince; a fine partita 5 e 2 PV per chi ha eliminato più Pattuglie.
[b]Villa Diodati[/b]: quando fai partire una catena prendi il Mostro di quella categoria (e il suo bonus); all’inizio di ogni tuo turno ogni Mostro rende 1 PV (2 nei round 4 e 5). Chi gioca una carta coperta rimanda tutti i Mostri alla Villa e guadagna PV. Bonus dei Mostri, nella quiete e risvegliati: Vampiro muovi di 1 (poi muovi o esplora), Cavallo conversa (poi lettera o conversa), Incubo scrivi nel Diario (poi scrivi o discuti), Creatura 2 monete (poi un’Idea a scelta).
[b]I Romantici[/b]: cinque nuovi viaggiatori (Rousseau, Stendhal, Andersen, Liszt, Percy Shelley). Le quattro carte Andersen: 2 PV (Festività); Scrivi e Lettera (Amicizia e Ispirazione); Caffè ed Esplorazione (Viaggio e Ispirazione); Conversa e Muovi (Viaggio e Amicizia). Le carte di due categorie contano per entrambe.
"""
