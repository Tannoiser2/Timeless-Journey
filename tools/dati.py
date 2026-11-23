#!/usr/bin/env python3
"""Scrive assets/dati/gioco.json: tutti i dati del gioco trascritti dal materiale originale (regolamento italiano,
plance, carte e tessere del modulo TTS). Gli effetti usano un piccolo linguaggio comune a carte, tessere e Gazzetta:

  {"monete":n} {"pv":n} {"idea":"Arte"|"*"} {"muovi":n,"sconto":k} {"esplora":n} {"conversa":n}
  {"lettera":n,"diverse":true} {"scrivi":n,"diversi":true} {"discuti":1,"ovunque":true}
  {"compra":1,"sconto":k,"risolvi":true} {"paga":n,"poi":[...]} {"paga_pv":n,"poi":[...]} {"o":[[...],[...]]}
  {"scambia_idea":1} {"scambia2":1} {"coperta_muovi":2} {"vai":[città,città]} {"riusa_esplorazione":1}
  {"lettera_ovunque":1} {"rimuovi_I":1,"poi":[...]} {"idee_diverse":2} {"attiva_esplorazione":1}
  {"compra_max":n}   (carta gratis di livello massimo n: battaglie di Napoleone)
"""
import json, os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'dati', 'gioco.json')

CITTA = ['Torino', 'Venezia', 'Bologna', 'Firenze', 'Perugia', 'Roma', 'Napoli', 'Palermo']

# ------------------------------------------------------------------ mappa (pixel sul tabellone 1080x1825)
NODI = {
    'Torino': [300, 228], 'Venezia': [754, 312], 'Bologna': [592, 512], 'Firenze': [464, 620],
    'Perugia': [622, 780], 'Roma': [502, 968], 'Napoli': [642, 1214], 'Palermo': [354, 1570],
    'c1': [512, 330], 'c2': [406, 418], 'c3': [690, 626], 'c4': [520, 755], 'c5': [410, 774],
    'c6': [494, 858], 'c7': [748, 884], 'c8': [620, 958], 'c9': [630, 1036], 'c10': [792, 1066],
    'c11': [582, 1126], 'c12': [564, 1330], 'c13': [772, 1328], 'c14': [802, 1476], 'c15': [622, 1650],
}
# [a, b, costo, tipo]  tipo: "terra", "mare" (tratteggiata), "nave" (diretta Palermo-Roma/Venezia)
STRADE = [
    ['Torino', 'Venezia', 0, 'terra'], ['Torino', 'c1', 1, 'terra'], ['c1', 'Venezia', 1, 'terra'],
    ['c1', 'c2', 0, 'terra'], ['c1', 'Bologna', 0, 'terra'], ['c2', 'Firenze', 1, 'terra'],
    ['Bologna', 'c3', 2, 'terra'], ['Firenze', 'c3', 0, 'terra'], ['Firenze', 'c4', 2, 'terra'],
    ['c3', 'c4', 3, 'terra'], ['c4', 'c5', 0, 'terra'], ['c4', 'Perugia', 0, 'terra'],
    ['c5', 'c6', 0, 'terra'], ['c6', 'Roma', 0, 'terra'], ['Perugia', 'c7', 0, 'terra'],
    ['c7', 'c8', 2, 'terra'], ['c8', 'Roma', 0, 'terra'], ['c7', 'c10', 0, 'terra'],
    ['Roma', 'c9', 0, 'terra'], ['c9', 'c11', 0, 'terra'], ['c10', 'Napoli', 2, 'terra'],
    ['c11', 'Napoli', 0, 'terra'], ['c11', 'c12', 0, 'mare'], ['c12', 'Palermo', 6, 'mare'],
    ['Napoli', 'c13', 0, 'terra'], ['c13', 'c14', 0, 'terra'], ['c14', 'c15', 3, 'terra'],
    ['c15', 'Palermo', 0, 'terra'], ['Palermo', 'Roma', 6, 'nave'], ['Palermo', 'Venezia', 6, 'nave'],
]
# posizione della stella bianca accanto al nome (pattuglie austriache, sagome iniziali)
STELLE = {'Venezia': [930, 320], 'Bologna': [795, 530], 'Firenze': [255, 632], 'Perugia': [817, 773],
          'Roma': [303, 947], 'Napoli': [845, 1215], 'Palermo': [137, 1572], 'Torino': [205, 215]}

# ------------------------------------------------------------------ plance città
# discussioni: costo (dizionario idee; "o": true = basta UNA delle due idee) e PV dei due spazi
CITTA_DATI = {
    'Torino': {'favore': 1, 'esplora_alt': [{'monete': 1}], 'lato': 'sinistra',
               'caffe': [{'costo': {'Storia': 1, 'Filosofia': 1}, 'o': True, 'pv': [3, 1]},
                         {'costo': {'Arte': 1, 'Scienza': 1}, 'o': True, 'pv': [3, 1]}]},
    'Venezia': {'favore': 1, 'esplora_alt': [{'idea': 'Arte'}], 'lato': 'destra',
                'caffe': [{'costo': {'Storia': 1, 'Arte': 1}, 'pv': [5, 3]},
                          {'costo': {'Filosofia': 1, 'Scienza': 1}, 'pv': [5, 3]}]},
    'Bologna': {'favore': 1, 'esplora_alt': [{'idea': 'Scienza'}], 'lato': 'destra',
                'caffe': [{'costo': {'Storia': 1, 'Scienza': 2}, 'pv': [6, 4]},
                          {'costo': {'Filosofia': 1, 'Arte': 2}, 'pv': [6, 4]}]},
    'Firenze': {'favore': 1, 'esplora_alt': [{'idea': 'Storia'}], 'lato': 'sinistra',
                'caffe': [{'costo': {'Scienza': 1, 'Filosofia': 2}, 'pv': [8, 6]},
                          {'costo': {'Arte': 1, 'Storia': 2}, 'pv': [8, 6]}]},
    'Perugia': {'favore': 2, 'esplora_alt': [{'idea': 'Filosofia'}], 'lato': 'destra',
                'caffe': [{'costo': {'Arte': 2, 'Scienza': 2}, 'pv': [11, 9]},
                          {'costo': {'Storia': 2, 'Filosofia': 2}, 'pv': [11, 9]}]},
    'Roma': {'favore': 2, 'esplora_alt': [{'lettera': 1}], 'lato': 'sinistra',
             'caffe': [{'costo': {'Arte': 5}, 'pv': [13, 10]}, {'costo': {'Scienza': 5}, 'pv': [13, 10]}]},
    'Napoli': {'favore': 2, 'esplora_alt': [{'pv': 1}], 'lato': 'destra',
               'caffe': [{'costo': {'Filosofia': 5}, 'pv': [15, 12]}, {'costo': {'Storia': 5}, 'pv': [15, 12]}]},
    'Palermo': {'favore': 2, 'esplora_alt': [{'scrivi': 1}], 'lato': 'sinistra',
                'caffe': [{'costo': {'Arte': 1, 'Storia': 2, 'Scienza': 2}, 'pv': [17, 13]},
                          {'costo': {'Scienza': 1, 'Arte': 2, 'Filosofia': 2}, 'pv': [17, 13]}]},
}
# nomi degli abitanti (sinistra, destra) come appaiono sulle plance
ABITANTI = {
    'Torino': ['il pittore', 'la dama in blu'], 'Venezia': ['il poeta', 'la dama in rosso'],
    'Bologna': ['lo studente', 'la letterata'], 'Firenze': ['la pittrice', 'il frate'],
    'Perugia': ['la popolana', 'il soldato'], 'Roma': ['il cardinale', 'la suora'],
    'Napoli': ['il flautista', 'la locandiera'], 'Palermo': ['la cantante', 'il gentiluomo'],
}

def idea_o(a, b):
    return {'o': [[{'idea': a}], [{'idea': b}]]}

def paga_idee():
    return {'o': [[{'paga': 1, 'poi': [{'idea': '*'}]}], [{'paga': 3, 'poi': [{'idea': '*'}, {'idea': '*'}]}]]}

FAVORI = {
    'FT01': [[{'monete': 2}], [{'idea': 'Arte'}]],
    'FT02': [[{'idea': 'Scienza'}], [{'muovi': 1}]],
    'FT03': [[{'paga': 1, 'poi': [{'idea': '*'}]}], [{'idea': 'Storia'}]],
    'FT04': [[{'idea': 'Filosofia'}], [{'scrivi': 1}]],
    'FT05': [[{'scambia_idea': 1}], [{'coperta_muovi': 2}]],
    'FT06': [[{'monete': 1}, {'pv': 1}], [{'paga_pv': 1, 'poi': [{'idea': '*'}]}]],
    'FT07': [[idea_o('Arte', 'Storia')], [{'monete': 2}, {'pv': 1}]],
    'FT08': [[idea_o('Scienza', 'Filosofia')], [{'compra': 1}]],
    'FT09': [[idea_o('Arte', 'Filosofia')], [{'muovi': 1}, {'pv': 1}]],
    'FT10': [[idea_o('Scienza', 'Storia')], [{'paga': 2, 'poi': [{'scrivi': 2, 'diversi': True}]}]],
    'FT11': [[{'paga': 2, 'poi': [{'idee_diverse': 2}]}], [{'paga': 2, 'poi': [{'pv': 3}]}]],
    'FT12': [[{'rimuovi_I': 1, 'poi': [{'monete': 2}, {'pv': 3}]}], [{'discuti': 1, 'ovunque': True}]],
}
FAVORI_LIVELLO = {k: (1 if int(k[2:]) <= 6 else 2) for k in FAVORI}
FAVORI_INTRO = ['FT01', 'FT02', 'FT03', 'FT04', 'FT07', 'FT08', 'FT09', 'FT10']

ESPLORAZIONI = {
    'Torino': [[{'conversa': 1}], [{'idea': 'Storia'}], [{'idea': 'Scienza'}], [{'lettera': 1}], [{'muovi': 1}],
               [{'monete': 2}]],
    'Venezia': [[{'scrivi': 1}], [{'idea': 'Arte'}], [{'idea': 'Filosofia'}], [{'discuti': 1}], [paga_idee()],
                [{'monete': 1}, {'compra': 1}]],
    'Bologna': [[{'monete': 1}, {'lettera': 1}], [{'idea': 'Storia'}], [{'idea': 'Scienza'}],
                [{'monete': 1}, {'conversa': 1}], [{'monete': 1}, {'muovi': 1}], [paga_idee()]],
    'Firenze': [[{'idea': 'Filosofia'}], [{'monete': 3}], [{'monete': 1}, {'discuti': 1}],
                [{'monete': 2}, {'compra': 1}], [{'idea': 'Arte'}], [{'monete': 1}, {'scrivi': 1}]],
    'Perugia': [[{'monete': 1}, {'pv': 1}], [{'monete': 1}, {'muovi': 1}], [{'idea': '*'}],
                [{'conversa': 1}, {'pv': 1}], [{'muovi': 2}], [{'monete': 3}]],
    'Roma': [[{'monete': 2}, {'compra': 1}], [{'o': [[{'discuti': 1}], [{'scrivi': 1}]]}],
             [{'vai': ['Bologna', 'Firenze']}], [{'idea': '*'}], [{'idea': 'Filosofia'}, {'idea': 'Storia'}],
             [paga_idee()]],
    'Napoli': [[{'muovi': 1, 'sconto': 2}], [{'vai': ['Roma', 'Perugia']}], [{'idea': 'Arte'}, {'idea': 'Scienza'}],
               [{'o': [[{'monete': 2}], [{'pv': 2}]]}], [{'lettera': 2, 'diverse': True}], [{'monete': 4}]],
    'Palermo': [[{'monete': 2}, {'compra': 1}], [{'o': [[{'conversa': 1}], [{'lettera': 1}]]}],
                [{'vai': ['Firenze', 'Roma']}], [{'monete': 1}, {'pv': 2}], [{'scrivi': 2}],
                [{'idea': '*'}, {'paga': 1, 'poi': [{'idea': '*'}]}]],
}

# ------------------------------------------------------------------ carte azione
BASE = [  # indice immagine sul foglio, categoria, effetto
    {'img': 0, 'cat': 'V', 'eff': [{'muovi': 1}], 'nome': 'Movimento'},
    {'img': 1, 'cat': 'V', 'eff': [{'esplora': 1}], 'nome': 'Esplorazione'},
    {'img': 2, 'cat': 'A', 'eff': [{'conversa': 1}], 'nome': 'Conversare'},
    {'img': 3, 'cat': 'A', 'eff': [{'lettera': 1}], 'nome': 'Inviare una lettera'},
    {'img': 4, 'cat': 'I', 'eff': [{'o': [[{'discuti': 1}], [{'scrivi': 1}]]}], 'nome': 'Caffè o Diario'},
    {'img': 5, 'cat': 'I', 'eff': [], 'nome': 'Idea'},  # idea del colore (grigio: 2 monete)
    {'img': 0, 'cat': 'V', 'eff': [{'muovi': 1}], 'nome': 'Movimento', 'settima': True},
]
COLORI = ['rosso', 'giallo', 'verde', 'blu', 'grigio']
IDEA_COLORE = {'rosso': [{'idea': 'Arte'}], 'giallo': [{'idea': 'Storia'}], 'verde': [{'idea': 'Scienza'}],
               'blu': [{'idea': 'Filosofia'}], 'grigio': [{'monete': 2}]}

V, I, A, F = 'V', 'I', 'A', 'F'
AV = {  # numero: [livello, categoria, PV, effetto, condizione, copie]
    1: [1, V, 1, [{'muovi': 1}, {'paga': 1, 'poi': [{'muovi': 1}]}], None, 2],
    2: [1, V, 0, [{'esplora': 1}, {'monete': 1}], None, 2],
    3: [1, V, 1, [{'o': [[{'esplora': 1}], [{'muovi': 1}]]}], None, 2],
    4: [1, I, 1, [paga_idee()], None, 1],
    5: [1, I, 1, [{'o': [[{'monete': 2}], [{'scambia2': 1}]]}], None, 1],
    6: [1, I, 1, [{'monete': 1}, {'scrivi': 1}], None, 2],
    7: [1, I, 2, [{'monete': 1}, {'discuti': 1}], None, 2],
    8: [1, A, 1, [{'o': [[{'conversa': 1}], [{'lettera': 1}]]}], None, 2],
    9: [1, A, 0, [{'monete': 1}, {'conversa': 1}], None, 2],
    10: [1, A, 0, [{'monete': 1}, {'lettera': 1}], None, 2],
    11: [1, F, 2, [{'monete': 1}, {'muovi': 1}], None, 2],
    12: [1, F, 2, [{'idea': '*'}], None, 2],
    13: [1, F, 2, [{'monete': 2}, {'pv': 1}], None, 2],
    14: [1, F, 2, [{'pv': 1}, {'lettera': 1}], None, 1],
    15: [1, I, 1, [{'o': [[{'idea': 'Storia'}], [{'discuti': 1}]]}], None, 1],
    16: [1, A, 1, [{'o': [[{'idea': 'Scienza'}], [{'monete': 3}]]}], None, 1],
    17: [2, V, 0, [{'esplora': 1}, {'muovi': 1}], None, 2],
    18: [2, V, 2, [{'muovi': 1, 'sconto': 2}], None, 1],
    19: [2, F, 3, [{'pv': 1}, {'conversa': 1}], None, 2],
    20: [2, V, 0, [{'esplora': 2}], None, 1],
    21: [2, I, 1, [{'scrivi': 1}, {'discuti': 1}], None, 2],
    22: [2, I, 2, [{'o': [[{'idea': '*'}], [{'scrivi': 1}]]}], None, 2],
    23: [2, I, 2, [{'o': [[{'idea': '*'}], [{'discuti': 1}]]}], None, 2],
    24: [2, A, 0, [{'lettera': 1}, {'conversa': 1}], None, 2],
    25: [2, A, 3, [{'lettera': 1}, {'paga': 1, 'poi': [{'lettera': 1}]}], None, 2],
    26: [2, A, 0, [{'conversa': 2}], None, 2],
    27: [2, F, 3, [{'monete': 1}, {'muovi': 2}], None, 1],
    28: [2, F, 3, [{'monete': 2}, {'scrivi': 1}], None, 2],
    29: [2, F, 3, [{'compra': 1, 'sconto': 2}], None, 2],
    30: [2, V, 2, [{'muovi': 2}], None, 2],
    31: [2, V, 2, [{'idea': 'Arte'}, {'muovi': 1}], None, 1],
    32: [2, A, 2, [{'idea': 'Filosofia'}, {'lettera': 1}], None, 1],
    33: [3, V, 2, [{'o': [[{'esplora': 2}], [{'muovi': 2}]]}], None, 1],
    34: [3, V, 2, [{'muovi': 1, 'sconto': 2}, {'muovi': 1}], None, 1],
    35: [3, V, 2, [{'esplora': 1}, {'muovi': 1, 'sconto': 2}], None, 1],
    36: [3, I, 4, [{'paga': 1, 'poi': [{'idea': '*'}]}, {'scrivi': 1}], None, 1],
    37: [3, I, 3, [{'idea': '*'}, {'discuti': 1}], None, 1],
    38: [3, I, 0, [{'idea': '*'}, {'paga': 1, 'poi': [{'scrivi': 2, 'diversi': True}]}], None, 1],
    39: [3, A, 2, [{'o': [[{'lettera': 2, 'diverse': True}], [{'conversa': 2}]]}], None, 1],
    40: [3, A, 2, [{'paga': 1, 'poi': [{'lettera': 3, 'diverse': True}]}], None, 1],
    41: [3, A, 3, [{'lettera': 2, 'diverse': True}, {'paga': 1, 'poi': [{'conversa': 1}]}], None, 1],
    42: [3, F, 3, [{'compra': 1, 'risolvi': True}], None, 1],
    43: [3, F, 3, [{'esplora': 2}, {'muovi': 1}], None, 1],
    44: [3, F, 3, [{'monete': 1}, {'lettera_ovunque': 1}], None, 1],
    45: [3, F, 2, [{'monete': 1}, {'scrivi': 2, 'diversi': True}], None, 1],
    46: [3, V, 2, [{'o': [[{'esplora': 2}], [{'riusa_esplorazione': 1}]]}], None, 1],
    47: [3, V, 0, [{'muovi': 2}], {'tipo': 'carte_cat', 'cat': V, 'ogni': 2, 'pv': 3}, 1],
    48: [3, V, 0, [{'esplora': 2}], {'tipo': 'tessere_citta', 'ogni': 1, 'pv': 1}, 1],
    49: [3, V, 0, [{'esplora': 1}, {'muovi': 1}], {'tipo': 'citta_presenza', 'ogni': 1, 'pv': 2}, 1],
    50: [3, I, 0, [{'scrivi': 1}, {'discuti': 1}], {'tipo': 'carte_cat', 'cat': I, 'ogni': 2, 'pv': 3}, 1],
    51: [3, I, 0, [{'paga': 1, 'poi': [{'idea': '*'}]}, {'scrivi': 1}], {'tipo': 'idee_scritte', 'ogni': 3, 'pv': 2}, 1],
    52: [3, I, 0, [{'o': [[{'idea': '*'}], [{'discuti': 1}]]}], {'tipo': 'caffe', 'ogni': 1, 'pv': 2, 'max': 8}, 1],
    53: [3, A, 0, [{'lettera': 1}, {'conversa': 1}], {'tipo': 'idee_libere', 'ogni': 1, 'pv': 2, 'max': 8}, 1],
    54: [3, A, 0, [{'lettera': 2, 'diverse': True}], {'tipo': 'carte_cat', 'cat': A, 'ogni': 2, 'pv': 3}, 1],
    55: [3, A, 0, [{'conversa': 2}], {'tipo': 'monete', 'ogni': 1, 'pv': 1, 'max': 8}, 1],
    56: [3, F, 0, [{'monete': 1}, {'muovi': 2}], {'tipo': 'carte_liv', 'liv': 2, 'ogni': 2, 'pv': 3}, 1],
    57: [3, F, 0, [{'monete': 2}, {'scrivi': 1}], {'tipo': 'carte_cat', 'cat': F, 'ogni': 2, 'pv': 3}, 1],
    58: [3, F, 0, [{'compra': 1, 'sconto': 2}], {'tipo': 'carte_liv', 'liv': 3, 'ogni': 2, 'pv': 3}, 1],
    59: [3, A, 0, [{'idea': '*'}, {'lettera': 2, 'diverse': True}], {'tipo': 'carte_liv', 'liv': 1, 'ogni': 2, 'pv': 3}, 1],
}
# copie: livello I e II arrivano a 27 carte, il III ne ha 27 (una per effetto)
for liv in (1, 2, 3):
    tot = sum(v[5] for v in AV.values() if v[0] == liv)
    assert tot == 27, (liv, tot)

# ------------------------------------------------------------------ diari di viaggio (città, idee x3, idee x3)
DIARI = {
    'A': [['Bologna', 'Storia', 'Filosofia'], ['Firenze', 'Arte', 'Storia'], ['Napoli', 'Filosofia', 'Arte'],
          ['Palermo', 'Arte', 'Filosofia'], ['Perugia', 'Arte', 'Scienza'], ['Roma', 'Storia', 'Arte'],
          ['Torino', 'Storia', 'Filosofia'], ['Venezia', 'Arte', 'Storia']],
    'B': [['Perugia', 'Filosofia', 'Storia'], ['Roma', 'Scienza', 'Filosofia'], ['Torino', 'Scienza', 'Arte'],
          ['Venezia', 'Filosofia', 'Scienza'], ['Bologna', 'Scienza', 'Arte'], ['Firenze', 'Filosofia', 'Scienza'],
          ['Napoli', 'Scienza', 'Storia'], ['Palermo', 'Storia', 'Scienza']],
}

# ------------------------------------------------------------------ Gazzetta: per ogni lato tre colonne
# ogni colonna: premio dello spazio e città del viaggiatore nei round I..V; min = giocatori minimi dello spazio
MIN = [[3, 0, 0], [0, 3, 0], [4, 0, 3], [0, 4, 0], [0, 0, 4]]  # [round][colonna]
GAZZETTA = {
    'A': {'premi': [[{'monete': 2}], [{'idea': 'Arte'}], [{'scrivi': 1}]],
          'citta': [['Bologna', 'Firenze', 'Perugia', 'Napoli', 'Palermo'],
                    ['Venezia', 'Bologna', 'Firenze', 'Palermo', 'Roma'],
                    ['Firenze', 'Venezia', 'Roma', 'Firenze', 'Palermo']]},
    'B': {'premi': [[{'discuti': 1}], [{'idea': 'Storia'}], [{'muovi': 1}]],
          'citta': [['Bologna', 'Firenze', 'Perugia', 'Roma', 'Napoli'],
                    ['Venezia', 'Perugia', 'Napoli', 'Roma', 'Palermo'],
                    ['Firenze', 'Venezia', 'Firenze', 'Roma', 'Perugia']]},
    'C': {'premi': [[{'pv': 2}], [{'idea': 'Scienza'}], [{'compra': 1}]],
          'citta': [['Bologna', 'Firenze', 'Perugia', 'Napoli', 'Palermo'],
                    ['Venezia', 'Bologna', 'Firenze', 'Palermo', 'Roma'],
                    ['Firenze', 'Perugia', 'Bologna', 'Roma', 'Napoli']]},
    'D': {'premi': [[{'esplora': 1}], [{'idea': 'Filosofia'}], [{'lettera': 1}]],
          'citta': [['Bologna', 'Perugia', 'Perugia', 'Firenze', 'Roma'],
                    ['Venezia', 'Bologna', 'Firenze', 'Palermo', 'Napoli'],
                    ['Firenze', 'Perugia', 'Bologna', 'Roma', 'Napoli']]},
}

VIAGGIATORI = {
    'addison': {'nome': 'Joseph Addison', 'anni': '1672–1719', 'chi': 'Saggista inglese', 'periodo': 'A',
                'testo': 'Ogni volta che esegui un’azione di Conversazione, Invio di una Lettera o Esplorazione mentre il tuo segnalino è nella sua città, ottieni 1 PV.'},
    'montagu': {'nome': 'Lady Montagu', 'anni': '1689–1762', 'chi': 'Corrispondente e riformatrice inglese', 'periodo': 'A',
                'testo': 'Fine round: se il tuo segnalino è nella sua città, ottieni 2 segnalini Idea a scelta oppure 3 PV.'},
    'montesquieu': {'nome': 'Montesquieu', 'anni': '1689–1755', 'chi': 'Filosofo francese', 'periodo': 'A',
                    'testo': 'Ogni volta che discuti in un caffè nella sua città (con il segnalino o con una Lettera) ottieni 4 PV extra.'},
    'craven': {'nome': 'Lady Craven', 'anni': '1750–1828', 'chi': 'Drammaturga e memorialista inglese', 'periodo': 'B',
               'testo': 'Le discussioni al caffè nella sua città costano 1 segnalino Idea in meno.'},
    'goethe': {'nome': 'Goethe', 'anni': '1749–1832', 'chi': 'Poeta e polimata tedesco', 'periodo': 'B',
               'testo': 'Fine round: se il tuo segnalino è nella sua città, ottieni 1 PV per ogni moneta che possiedi (massimo 7).'},
    'le_brun': {'nome': 'Vigée Le Brun', 'anni': '1755–1842', 'chi': 'Pittrice francese', 'periodo': 'B',
                'testo': 'A ogni round si scoprono 3 Dipinti (2 in due giocatori). Quando esplori nella sua città puoi prendere un Dipinto che non hai. Fine partita: 1/2/3/4/5 Dipinti diversi valgono 1/3/7/13/20 PV.'},
    'byron': {'nome': 'Lord Byron', 'anni': '1788–1824', 'chi': 'Poeta inglese', 'periodo': 'C',
              'testo': 'All’inizio del tuo turno puoi spendere 3 monete per spostarti nella sua città.'},
    'keats': {'nome': 'John Keats', 'anni': '1795–1821', 'chi': 'Poeta inglese', 'periodo': 'C',
              'testo': 'Ottieni 2 PV ogni volta che giochi una carta Avanzata nella sua città. Fine round: se sei ancora lì, 1 PV per ogni carta Avanzata giocata nel round.'},
    'mary_shelley': {'nome': 'Mary Shelley', 'anni': '1797–1851', 'chi': 'Romanziera inglese', 'periodo': 'C',
                     'testo': 'Fine round: se il tuo segnalino è nella sua città, ottieni 1 PV per ogni segnalino Idea già scritto nei tuoi Diari.'},
    'blessington': {'nome': 'Lady Blessington', 'anni': '1789–1849', 'chi': 'Scrittrice e padrona di salotto irlandese', 'periodo': 'D',
                    'testo': 'Fine round: chi è più vicino a lei (spazi lungo le strade) ottiene 3 PV, chi è più lontano perde 2 PV. Non si può duellare con lei.',
                    'no_duello': True},
    'dickens': {'nome': 'Charles Dickens', 'anni': '1812–1870', 'chi': 'Romanziere inglese', 'periodo': 'D',
                'testo': 'Una volta per turno, oltre alla tua azione, puoi pagare 2 monete per una Discussione o un’Esplorazione nella sua città, come se fossi lì.'},
    'twain': {'nome': 'Mark Twain', 'anni': '1835–1910', 'chi': 'Umorista e scrittore di viaggi americano', 'periodo': 'D',
              'testo': 'Ogni volta che sei nella sua città e ottieni un segnalino Idea, ottieni anche 2 PV.'},
    # espansione Napoleone
    'napoleone': {'nome': 'Napoleone', 'anni': '1769–1821', 'chi': 'Generale e statista francese', 'esp': 'napoleone',
                  'testo': 'Fine round: se sei nella sua città, ottieni 2 monete oppure 2 PV per ogni Pattuglia Austriaca nella tua area.'},
    'paolina': {'nome': 'Paolina Bonaparte', 'anni': '1780–1825', 'chi': 'Aristocratica francese', 'esp': 'napoleone',
                'testo': 'Nella sua città le Pattuglie non bloccano: scegli se risolvere la carta o eliminare la Pattuglia. Fine round: se sei lì, 1 Soldato Francese per la battaglia.'},
    'foscolo': {'nome': 'Ugo Foscolo', 'anni': '1778–1827', 'chi': 'Poeta e romanziere italiano', 'esp': 'napoleone',
                'testo': 'Fine round: se sei nella sua città, ottieni 2 PV per ogni Soldato Francese nella tua area.'},
    # espansione I Romantici
    'rousseau': {'nome': 'Rousseau', 'anni': '1712–1778', 'chi': 'Filosofo svizzero', 'esp': 'romantici',
                 'testo': 'Se sei nella sua città, puoi inviare una lettera a un abitante di un’altra città anche senza un tuo segnalino Lettera.'},
    'stendhal': {'nome': 'Stendhal', 'anni': '1783–1842', 'chi': 'Romanziere francese', 'esp': 'romantici',
                 'testo': 'Se sei nella sua città, una volta per turno quando attivi una tessera Esplorazione ne ottieni due volte la ricompensa.'},
    'andersen': {'nome': 'H. C. Andersen', 'anni': '1805–1875', 'chi': 'Scrittore danese', 'esp': 'romantici',
                 'testo': 'Se sei nella sua città puoi giocare una carta della riserva Andersen invece di una dalla mano (una per round a testa).'},
    'liszt': {'nome': 'Liszt', 'anni': '1811–1886', 'chi': 'Compositore ungherese', 'esp': 'romantici',
              'testo': 'Se sei nella sua città alla fine del round, la Musica conta come categoria in più per il Mercato; con 5 o più categorie ottieni 3 PV.'},
    'percy_shelley': {'nome': 'Percy Shelley', 'anni': '1792–1822', 'chi': 'Poeta inglese', 'esp': 'romantici', 'no_duello': True,
                      'testo': 'Se sei nella sua città quando scrivi nel Diario, puoi mettere 1 Idea sulla sua carta per 3 PV (un genere per round). Non si può duellare con lui.'},
}
PERIODI = {'A': ['addison', 'montagu', 'montesquieu'], 'B': ['craven', 'goethe', 'le_brun'],
           'C': ['byron', 'keats', 'mary_shelley'], 'D': ['blessington', 'dickens', 'twain']}
INTRO = ['montesquieu', 'montagu', 'mary_shelley']

# ------------------------------------------------------------------ espansioni
BATTAGLIE = {
    'A1': {'premio': [{'monete': 2}, {'pv': 1}], 'mod': 0, 'pv': [3, 1]},
    'A2': {'premio': [{'idea': '*'}], 'mod': 0, 'pv': [4, 1]},
    'A3': {'premio': [{'muovi': 1}, {'monete': 1}], 'mod': 1, 'pv': [4, 1]},
    'A4': {'premio': [{'attiva_esplorazione': 1}], 'mod': 2, 'pv': [5, 2]},
    'A5': {'premio': [{'o': [[{'lettera': 1}], [{'conversa': 1}]]}], 'mod': 1, 'pv': [4, 2]},
    'A6': {'premio': [{'lettera': 1}], 'mod': 2, 'pv': [5, 3]},
    'A7': {'premio': [{'compra_max': 1}], 'mod': 2, 'pv': [5, 2], 'una_volta': True},
    'B1': {'premio': [{'compra_max': 1}], 'mod': 3, 'pv': [6, 3], 'una_volta': True},
    'B2': {'premio': [{'scrivi': 1}], 'mod': 2, 'pv': [5, 3]},
    'B3': {'premio': [{'discuti': 1, 'ovunque': True}], 'mod': 0, 'pv': [4, 1]},
    'B4': {'premio': [{'scrivi': 1}], 'mod': 1, 'pv': [4, 2]},
    'B5': {'premio': [{'pv': 2}], 'mod': 3, 'pv': [6, 3]},
}
PATTUGLIE = ['V', 'V', 'V', 'A', 'A', 'A', 'I', 'I', 'I']
# Villa Diodati: i bonus delle carte Mostro non sono scritti nel regolamento; questi sono provvisori
MOSTRI = {
    'V': {'nome': 'Il Vampiro di Polidori', 'quiete': [{'muovi': 1}], 'risveglio': [{'muovi': 2}]},
    'A': {'nome': 'Il Cavallo dell’Incubo', 'quiete': [{'lettera': 1}], 'risveglio': [{'conversa': 1}]},
    'I': {'nome': 'L’Incubo', 'quiete': [{'idea': '*'}], 'risveglio': [{'idea': '*'}, {'idea': '*'}]},
    'F': {'nome': 'La Creatura di Frankenstein', 'quiete': [{'monete': 2}], 'risveglio': [{'monete': 3}, {'pv': 1}]},
}
# carte Azione Speciale di Andersen: il regolamento non ne riporta il testo; effetti provvisori, una per categoria
ANDERSEN = [
    {'cat': 'V', 'nome': 'La Sirenetta', 'eff': [{'esplora': 1}, {'muovi': 1}]},
    {'cat': 'A', 'nome': 'Il Brutto Anatroccolo', 'eff': [{'conversa': 1}, {'lettera': 1}]},
    {'cat': 'I', 'nome': 'La Regina delle Nevi', 'eff': [{'idea': '*'}, {'scrivi': 1}]},
    {'cat': 'F', 'nome': 'L’Acciarino Magico', 'eff': [{'monete': 2}, {'pv': 1}]},
]

dati = {
    'citta': CITTA, 'nodi': NODI, 'strade': STRADE, 'stelle': STELLE,
    'plance': CITTA_DATI, 'abitanti': ABITANTI,
    'favori': FAVORI, 'favori_livello': FAVORI_LIVELLO, 'favori_intro': FAVORI_INTRO,
    'esplorazioni': ESPLORAZIONI,
    'base': BASE, 'colori': COLORI, 'idea_colore': IDEA_COLORE,
    'avanzate': {str(k): {'liv': v[0], 'cat': v[1], 'pv': v[2], 'eff': v[3], 'cond': v[4], 'copie': v[5]} for k, v in AV.items()},
    'diari': DIARI, 'gazzetta': GAZZETTA, 'gazzetta_min': MIN,
    'viaggiatori': VIAGGIATORI, 'periodi': PERIODI, 'intro': INTRO,
    'tab_esplorazioni': [0, 1, 2, 3, 4, 6, 9, 13, 18],
    'tab_diari': [0, 2, 4, 6, 9, 12, 15, 21, 28],
    'tab_dipinti': [0, 1, 3, 7, 13, 20],
    'battaglie': BATTAGLIE, 'pattuglie': PATTUGLIE, 'mostri': MOSTRI, 'andersen': ANDERSEN,
    'ordine_automi': CITTA,
}
os.makedirs(os.path.dirname(OUT), exist_ok=True)
json.dump(dati, open(OUT, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('scritto', OUT)
