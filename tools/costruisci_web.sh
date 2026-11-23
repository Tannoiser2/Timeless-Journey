#!/bin/bash
# Esporta il gioco (Godot web) in build/web.
# Uso: tools/costruisci_web.sh [comando godot]
set -e
cd "$(dirname "$0")/.."
GODOT=${1:-godot}
rm -rf build/web
mkdir -p build/web
$GODOT --headless --path . --import >/dev/null 2>&1 || true
$GODOT --headless --path . --export-release "Web" build/web/index.html
test -f build/web/index.pck
cp -r web/js web/font web/img build/web/
# numero di versione (data e ora) per non far usare al browser i file vecchi
V=$(date -u +%Y%m%d%H%M)
sed -i "s/__VERSIONE__/$V/g" build/web/index.html
touch build/web/.nojekyll
echo "Pronto in build/web"
