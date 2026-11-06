#!/bin/bash
# Gera build/perf (cena de estresse, separada do build do jogo). Uso: bash tests/perf/export_perf.sh
# O template release não aceita override de cena por argumento, então exporta de uma cópia
# temporária do projeto com main_scene trocada e sem autoloads (project.godot original intacto).
set -e
GODOT="${GODOT:-/c/Program Files/Godot/Godot_v4.7.2-stable_win64.exe}"
cd "$(dirname "$0")/../.."
ROOT="$PWD"
TMP="${TMPDIR:-/tmp}/anima_perf_proj"
rm -rf "$TMP"; mkdir -p "$TMP"
for d in assets src tests .godot web; do [ -e "$d" ] && cp -r "$d" "$TMP/"; done
cp project.godot export_presets.cfg icon.svg "$TMP/" 2>/dev/null || cp project.godot export_presets.cfg "$TMP/"
sed -i 's#^run/main_scene=.*#run/main_scene="res://tests/perf/stress.tscn"#; /^\[autoload\]/,/^$/{/^\[autoload\]/d;/^[A-Za-z_]*=/d}' "$TMP/project.godot"
mkdir -p "$ROOT/build/perf"
"$GODOT" --headless --path "$TMP" --import >/dev/null 2>&1 || true
"$GODOT" --headless --path "$TMP" --export-release "Web Perf" "$ROOT/build/perf/index.html"
echo "OK: build/perf/index.html"
