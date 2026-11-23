# Timeless Journey — Il Grand Tour Italiano

Versione digitale in Godot 4 del gioco da tavolo *Timeless Journeys: The Italian Grand Tour*.

## Giocare

- Aprire `project.godot` con Godot 4.4 o successivo e premere **F6/F5**.
- Modalità incluse: solitario con due automi, partita contro 3 IA, pass-and-play 2–5 giocatori.
- Le partite vengono salvate automaticamente in `user://partita.json`.

## Firebase e multiplayer

1. Creare un progetto Firebase e abilitare **Realtime Database**.
2. Copiare `firebase_config.example.json` in `firebase_config.json`.
3. Inserire `database_url` e la chiave Web.
4. Applicare regole Firebase autenticate/temporanee adatte al proprio ambiente prima della pubblicazione.

Senza configurazione Firebase il gioco rimane completamente giocabile in locale. La modalità online crea una stanza e usa il Realtime Database per persisterne lo stato.

## Esportazione Web

```bash
godot --headless --path . --export-release Web build/web/index.html
```

Il workflow GitHub Pages esporta e pubblica automaticamente il progetto a ogni push su `main`.

## Crediti e materiali
