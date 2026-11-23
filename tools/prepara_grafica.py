#!/usr/bin/env python3
"""Prepara la grafica del gioco dal modulo TTS estratto (cartella di lavoro con le immagini già copiate).

Uso: python3 tools/prepara_grafica.py <cartella immagini estratte>
Taglia i fogli delle carte in carte singole, riduce plance e tessere e salva tutto in assets/img in WebP.
Non serve per giocare: è il passaggio fatto una volta per preparare i file del repository.
"""
import os, sys, glob
from PIL import Image

SRC = sys.argv[1] if len(sys.argv) > 1 else '/home/claude/img'
R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'img')


def salva(im, rel, larg=None, q=86):
    if larg and im.size[0] > larg:
        im = im.resize((larg, round(im.size[1] * larg / im.size[0])), Image.LANCZOS)
    p = os.path.join(R, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    if im.mode not in ('RGB', 'RGBA'):
        im = im.convert('RGBA')
    im.save(p, 'WEBP', quality=q, method=6)


def foglio(path, cols, rows, n):
    im = Image.open(path)
    w, h = im.size[0] // cols, im.size[1] // rows
    return [im.crop(((i % cols) * w, (i // cols) * h, (i % cols + 1) * w, (i // cols + 1) * h)) for i in range(n)]


def S(n):
    return os.path.join(SRC, n)


# tabellone, plance città, gazzette, mercato, punteggio
salva(Image.open(S('tabellone.png')), 'plance/tabellone.webp')
for c in ['Torino', 'Venezia', 'Bologna', 'Firenze', 'Perugia', 'Roma', 'Napoli', 'Palermo']:
    salva(Image.open(S(f'citta_{c}.png')), f'citta/{c}.webp', 1600)
for a, b in [('AB', 'A'), ('AB_retro', 'B'), ('CD', 'C'), ('CD_retro', 'D')]:
    salva(Image.open(S(f'gazzetta_{a}.png')), f'plance/gazzetta_{b}.webp', 1000)
salva(Image.open(S('mercato.png')), 'plance/mercato.webp', 500)
salva(Image.open(S('punteggio.png')), 'plance/punteggio.webp', 1000)
salva(Image.open(S('punteggio_retro.png')), 'plance/esperienze.webp', 1000)

# carte base: 6 per colore (la 7ª è il secondo Movimento)
for col, it in [('Red', 'rosso'), ('Yellow', 'giallo'), ('Green', 'verde'), ('Blue', 'blu'), ('Grey', 'grigio')]:
    for i, c in enumerate(foglio(S(f'base_{col}0.png'), 3, 2, 6)):
        salva(c, f'carte/base_{it}_{i}.webp', 300)
salva(Image.open(S('base_retro_Red0.png')), 'carte/retro.webp', 300)

# carte avanzate: indice nel foglio TTS -> numero del regolamento italiano
L1 = [1, 1, 2, 2, 3, 3, 4, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14]
L2 = [17, 17, 18, 19, 19, 20, 21, 21, 22, 22, 23, 23, 24, 24, 25, 25, 26, 26, 27, 28, 28, 29, 29, 30, 30]
L3 = list(range(33, 59))
fatti = set()
for nome, cols, rows, lista in [('avanzate_1_0', 6, 5, L1), ('avanzate_2_0', 6, 5, L2), ('avanzate_3_0', 5, 6, L3)]:
    for c, num in zip(foglio(S(nome + '.png'), cols, rows, len(lista)), lista):
        if num in fatti:
            continue
        fatti.add(num)
        salva(c, f'carte/av_{num:02d}.webp', 300)

# viaggiatori celebri (ordine del foglio TTS)
VIAG = ['montesquieu', 'montagu', 'addison', 'keats', 'byron', 'mary_shelley', 'dickens', 'twain',
        'blessington', 'craven', 'goethe', 'le_brun']
for c, n in zip(foglio(S('viaggiatori.png'), 4, 3, 12), VIAG):
    salva(c, f'viaggiatori/{n}.webp', 320)
SAG = ['byron', 'addison', 'dickens', 'goethe', 'keats', 'blessington', 'craven', 'montagu', 'le_brun',
       'montesquieu', 'twain', 'mary_shelley']
for i, n in enumerate(SAG):
    salva(Image.open(S(f'sagoma_{i}.png')), f'viaggiatori/sagoma_{n}.webp', 220)
salva(Image.open(S('sagoma_12.png')), 'segnalini/primo_giocatore.webp', 260)

# diari di viaggio: 8 per mazzo, foglio 2x4
CA = ['Bologna', 'Firenze', 'Napoli', 'Palermo', 'Perugia', 'Roma', 'Torino', 'Venezia']
CB = ['Perugia', 'Roma', 'Torino', 'Venezia', 'Bologna', 'Firenze', 'Napoli', 'Palermo']
for d, lista in [('A0', CA), ('B0', CB)]:
    for c, citta in zip(foglio(S(f'diari_{d}.png'), 2, 4, 8), lista):
        salva(c, f'diari/{d[0]}_{citta}.webp', 760)

# tessere
for f in glob.glob(S('espl_*.png')):
    salva(Image.open(f), 'tessere/' + os.path.basename(f).replace('.png', '.webp'), 200)
for f in glob.glob(S('favore_*.png')):
    salva(Image.open(f), 'tessere/' + os.path.basename(f).replace('.png', '.webp'), 360)
for f in glob.glob(S('amico_*.png')):
    salva(Image.open(f), 'tessere/' + os.path.basename(f).replace('.png', '.webp'), 200)
for f in glob.glob(S('lebrun_*.png')):
    salva(Image.open(f), 'tessere/' + os.path.basename(f).replace('.png', '.webp'), 200)

# segnalini
COL = {'Red': 'rosso', 'Yellow': 'giallo', 'Green': 'verde', 'Blue': 'blu', 'Grey': 'grigio'}
for en, it in COL.items():
    for t in ['duello', 'notte', 'ammirazione', 'affinita0', 'affinita1']:
        salva(Image.open(S(f'esp_{en}_{t}.png')), f'segnalini/esp_{it}_{t.rstrip("01")}{"" if t[-1] not in "01" else t[-1]}.webp', 160)
    for t in ['lettera', 'caffe', 'pv', 'coperta']:
        salva(Image.open(S(f'{t}_{en}.png')), f'segnalini/{t}_{it}.webp', 200)
for t in ['idea_Arte', 'idea_Storia', 'idea_Filosofia', 'idea_Scienza', 'moneta1', 'moneta5']:
    salva(Image.open(S(t + '.png')), f'segnalini/{t.lower()}.webp', 160)
print('fatto')
