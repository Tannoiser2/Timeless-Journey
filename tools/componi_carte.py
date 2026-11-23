#!/usr/bin/env python3
"""Ritocchi alle carte Azione Avanzata per allinearle al regolamento italiano.

- Le carte 47, 50 e 54 valgono 3 PV ogni 2 carte (il modulo TTS, più vecchio, diceva 4): corretto il numero.
- Le carte 15, 16, 31, 32 e 59 dell'edizione italiana non sono nel modulo TTS: composte con le icone delle altre carte.
- In basso a destra il numero della carta è quello del regolamento italiano (il modulo usava la vecchia numerazione).
Da lanciare una volta sola dopo tools/prepara_grafica.py.
"""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont

D = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'img', 'carte')
F = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'font', 'EBGaramond-Bold.ttf')


def apri(n):
    return Image.open(os.path.join(D, n + '.webp')).convert('RGB')


def salva(im, n):
    im.save(os.path.join(D, n + '.webp'), 'WEBP', quality=88)


def icona(src, box, soglia=38):
    """Ritaglia un'icona togliendo lo sfondo della carta (colore preso ai bordi del ritaglio)."""
    c = src.crop(box)
    a = np.asarray(c).astype(int)
    bordo = np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]])
    bg = np.median(bordo, axis=0)
    diff = np.abs(a - bg).sum(axis=2)
    m = np.clip((diff - soglia) * 6, 0, 255).astype(np.uint8)
    rgba = c.convert('RGBA')
    rgba.putalpha(Image.fromarray(m))
    return rgba


def cerchio(src, centro, r):
    c = src.crop((centro[0] - r, centro[1] - r, centro[0] + r, centro[1] + r)).convert('RGBA')
    m = Image.new('L', c.size, 0)
    ImageDraw.Draw(m).ellipse((1, 1, 2 * r - 2, 2 * r - 2), fill=255)
    c.putalpha(m)
    return c


def copia(dst, src, box):
    dst.paste(src.crop(box), box[:2])


def metti(dst, ic, centro, scala=1.0):
    if scala != 1.0:
        ic = ic.resize((round(ic.size[0] * scala), round(ic.size[1] * scala)), Image.LANCZOS)
    dst.paste(ic, (centro[0] - ic.size[0] // 2, centro[1] - ic.size[1] // 2), ic)


VIOLA = apri('base_giallo_5')      # carta viola con il centro libero sopra e sotto
TEAL = apri('base_rosso_2')        # carta verde acqua con il fumetto al centro
ARANCIO = apri('base_rosso_0')     # carta arancione con la freccia al centro
CIFRA = (141, 378, 161, 402)       # interno della ghirlanda dei PV


def pulisci(dst, box, src, banda=(98, 168)):
    """Copre un riquadro con lo sfondo della carta src preso da una fascia vuota (righe banda), ripetuta."""
    x0, y0, x1, y1 = box
    y = y0
    while y < y1:
        h = min(banda[1] - banda[0], y1 - y)
        dst.paste(src.crop((x0, banda[0], x1, banda[0] + h)), (x0, y))
        y += h


def cifra_da(dst, nome):
    copia(dst, apri(nome), CIFRA)


# 47, 50, 54: 3 PV ogni 2 carte
for n in ['av_47', 'av_50', 'av_54']:
    im = apri(n)
    if True:
        copia(im, apri('av_56'), CIFRA)
    salva(im, n)

# 15 - Ispirazione: 1 Storia OPPURE Discuti (1 PV)
im = apri('av_23')
pulisci(im, (90, 95, 210, 215), VIOLA)
metti(im, icona(VIOLA, (112, 178, 188, 272)), (150, 158))
cifra_da(im, 'av_21')
salva(im, 'av_15')

# 16 - Amicizia: 1 Scienza OPPURE 3 monete (1 PV)
im = apri('av_08')
pulisci(im, (95, 95, 205, 212), TEAL)
pulisci(im, (90, 248, 210, 352), TEAL)
metti(im, icona(apri('base_verde_5'), (105, 175, 195, 275)), (150, 158))
tess = Image.open(os.path.join(D, '..', 'tessere', 'espl_Perugia_5.webp')).convert('RGB')
moneta = cerchio(tess, (100, 100), 47)
metti(im, moneta, (150, 300), 0.85)
salva(im, 'av_16')

# 31 - Viaggio: 1 Arte + Muovi di 1 (2 PV)
im = apri('av_17')
pulisci(im, (90, 90, 215, 222), ARANCIO)
metti(im, icona(apri('base_rosso_5'), (105, 180, 195, 272)), (150, 160), 1.1)
copia(im, apri('av_18'), (118, 372, 182, 434))
salva(im, 'av_31')

# 32 - Amicizia: 1 Filosofia + Invia una lettera (2 PV)
im = apri('av_10')
pulisci(im, (95, 105, 205, 215), TEAL)
metti(im, icona(apri('base_blu_5'), (110, 178, 190, 272)), (150, 160), 1.05)
copia(im, apri('av_08'), (118, 372, 182, 434))
cifra_da(im, 'av_23')
salva(im, 'av_32')

# 59 - Amicizia: 1 Idea a scelta + 2 lettere diverse | 3 PV ogni 2 carte di livello I
im = apri('av_54')
basso = im.crop((40, 160, 260, 270))
pulisci(im, (40, 100, 260, 280), TEAL, (290, 345))
im.paste(basso, (40, 250))
metti(im, icona(apri('av_23'), (110, 100, 192, 198)), (150, 160), 0.95)
pulisci(im, (66, 372, 119, 406), TEAL, (300, 334))
d = ImageDraw.Draw(im)
d.rounded_rectangle((100, 376, 116, 400), radius=2, fill=(236, 228, 205), outline=(90, 78, 60), width=1)
d.text((108, 388), 'I', font=ImageFont.truetype(F, 15), fill=(70, 60, 45), anchor='mm')
d.text((93, 389), '2', font=ImageFont.truetype(F, 17), fill=(60, 50, 40), anchor='mm')
salva(im, 'av_59')

# carte scansionate dall'edizione italiana (tools/scansioni): sostituiscono quelle del modulo
SCAN = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'scansioni')
scansionate = set()
for f in sorted(os.listdir(SCAN)):
    if f.startswith('av_') and f.endswith('.png'):
        n = f[:-4]
        Image.open(os.path.join(SCAN, f)).convert('RGB').save(os.path.join(D, n + '.webp'), 'WEBP', quality=88)
        scansionate.add(int(n[3:]))

# numero italiano in basso a destra sulle altre avanzate
fnt = ImageFont.truetype(F, 13)
for n in range(1, 60):
    p = os.path.join(D, f'av_{n:02d}.webp')
    if n in scansionate or not os.path.exists(p):
        continue
    im = Image.open(p).convert('RGB')
    d = ImageDraw.Draw(im)
    d.rectangle((269, 422, 287, 438), fill=im.getpixel((264, 431)))
    d.text((278, 430), f'{n:02d}', font=fnt, fill=(95, 82, 66), anchor='mm')
    im.save(p, 'WEBP', quality=88)
print('carte ritoccate')
