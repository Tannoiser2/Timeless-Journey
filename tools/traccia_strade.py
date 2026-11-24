#!/usr/bin/env python3
"""Ricava dal tabellone il disegno vero di ogni strada (e delle rotte di mare tratteggiate) fra due luoghi,
così i percorsi dei Viaggiatori Celebri seguono le strade stampate. Scrive assets/dati/tracciati.json.
Uso: python3 tools/traccia_strade.py <tabellone.png originale 1080x1825>"""
import json, os, sys
import numpy as np
from PIL import Image
from skimage.graph import route_through_array

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
D = json.load(open(os.path.join(R, 'assets', 'dati', 'gioco.json')))
im = np.asarray(Image.open(sys.argv[1] if len(sys.argv) > 1 else '/home/claude/img/tabellone.png').convert('RGB')).astype(int)
H, W, _ = im.shape
r, g, b = im[..., 0], im[..., 1], im[..., 2]
crema = (r > 215) & (g > 205) & (b > 180) & (np.max(im, axis=2) - np.min(im, axis=2) < 45)
costo = np.where(crema, 1.0, 30.0)
nodi = {k: np.array(v, float) for k, v in D['nodi'].items()}
yy, xx = np.mgrid[0:H, 0:W]


def semplifica(pts, tol=1.2):
    """Douglas-Peucker"""
    if len(pts) < 3:
        return pts
    a, b = np.array(pts[0], float), np.array(pts[-1], float)
    ab = b - a
    n = np.linalg.norm(ab)
    dmax, k = 0, 0
    for i in range(1, len(pts) - 1):
        p = np.array(pts[i], float)
        d = abs(ab[0] * (p - a)[1] - ab[1] * (p - a)[0]) / n if n > 0 else np.linalg.norm(p - a)
        if d > dmax:
            dmax, k = d, i
    if dmax > tol:
        return semplifica(pts[:k + 1], tol)[:-1] + semplifica(pts[k:], tol)
    return [pts[0], pts[-1]]


out = {}
for a, b2, c, tipo in D['strade']:
    if tipo == 'nave':
        continue
    pa, pb = nodi[a], nodi[b2]
    m = 140
    x0 = int(max(0, min(pa[0], pb[0]) - m)); x1 = int(min(W, max(pa[0], pb[0]) + m))
    y0 = int(max(0, min(pa[1], pb[1]) - m)); y1 = int(min(H, max(pa[1], pb[1]) + m))
    cs = costo[y0:y1, x0:x1].copy()
    # gli altri luoghi non si attraversano
    for k, p in nodi.items():
        if k in (a, b2):
            continue
        mask = (xx[y0:y1, x0:x1] - p[0]) ** 2 + (yy[y0:y1, x0:x1] - p[1]) ** 2 < 34 ** 2
        cs[mask] = 5000
    # dentro i due cerchi di partenza e arrivo si passa liberi
    for p in (pa, pb):
        mask = (xx[y0:y1, x0:x1] - p[0]) ** 2 + (yy[y0:y1, x0:x1] - p[1]) ** 2 < 30 ** 2
        cs[mask] = 1.0
    path, tot = route_through_array(cs, (int(pa[1]) - y0, int(pa[0]) - x0), (int(pb[1]) - y0, int(pb[0]) - x0), fully_connected=True, geometric=True)
    pts = [(int(x + x0), int(y + y0)) for y, x in path]
    # liscia un poco (media mobile) e semplifica
    arr = np.array(pts, float)
    if len(arr) > 7:
        k = 5
        sm = arr.copy()
        for i in range(len(arr)):
            lo, hi = max(0, i - k), min(len(arr), i + k + 1)
            sm[i] = arr[lo:hi].mean(axis=0)
        sm[0], sm[-1] = arr[0], arr[-1]
        arr = sm
    pts = semplifica([(round(p[0], 1), round(p[1], 1)) for p in arr])
    out[f'{a}|{b2}'] = pts
    print(a, b2, len(pts), round(tot))
json.dump(out, open(os.path.join(R, 'assets', 'dati', 'tracciati.json'), 'w'), separators=(',', ':'))
