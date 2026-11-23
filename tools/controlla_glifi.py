#!/usr/bin/env python3
"""Controlla che ogni carattere usato nei testi del gioco esista in tutti i font (niente quadratini).

Uso: python3 tools/controlla_glifi.py
Legge le stringhe di scripts/*.gd, i dati in assets/dati/*.json e la pagina web, e le confronta
con i font in assets/font. Esce con errore se manca qualcosa.
"""
import glob, json, os, re, sys
from fontTools.ttLib import TTFont

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
testi = []
for f in glob.glob(R + '/scripts/*.gd'):
    src = open(f, encoding='utf-8').read()
    src = '\n'.join(l for l in src.splitlines() if not l.strip().startswith('#'))
    testi += re.findall(r'"((?:[^"\\]|\\.)*)"', src)
def raccogli(v):
    if isinstance(v, str): testi.append(v); testi.append(v.upper())
    elif isinstance(v, list): [raccogli(x) for x in v]
    elif isinstance(v, dict): [raccogli(x) for x in v.values()]
for f in glob.glob(R + '/assets/dati/*.json'):
    raccogli(json.load(open(f, encoding='utf-8')))
src = open(R + '/web/shell.html', encoding='utf-8').read()
testi += re.findall(r'>([^<>{}]+)<', src)
caratteri = set(''.join(testi)) - set('\n\t\r')
errori = 0
for f in sorted(glob.glob(R + '/assets/font/*.ttf')):
    cmap = TTFont(f).getBestCmap()
    manca = sorted(c for c in caratteri if ord(c) not in cmap and c not in ' ')
    if manca:
        errori += 1
        print('MANCANO in', os.path.basename(f), ':', ' '.join(f'{c}(U+{ord(c):04X})' for c in manca))
print('Caratteri controllati:', len(caratteri), '- font:', len(glob.glob(R + '/assets/font/*.ttf')))
sys.exit(1 if errori else 0)
