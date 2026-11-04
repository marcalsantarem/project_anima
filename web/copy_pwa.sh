#!/usr/bin/env bash
# T-175: copia o manifesto e os ícones de web/pwa/ para o build Web (o export do Godot não copia extras).
# Uso: bash web/copy_pwa.sh [build/web]          (depois do --export-release)
#      bash web/copy_pwa.sh --sync-icons         (atualiza web/pwa/ a partir de assets/app/, AG08)
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
pwa="$root/web/pwa"
icons=(apple-touch-icon-180.png icon-192.png icon-512.png icon-maskable-512.png favicon-32.png favicon-48.png favicon.ico)

if [ "${1:-}" = "--sync-icons" ]; then
	for f in "${icons[@]}"; do
		if [ -f "$root/assets/app/$f" ]; then cp "$root/assets/app/$f" "$pwa/$f"; else echo "falta assets/app/$f" >&2; fi
	done
	exit 0
fi

out="${1:-$root/build/web}"
test -s "$out/index.html" || { echo "sem $out/index.html: rode o export antes" >&2; exit 1; }
cp "$pwa/manifest.webmanifest" "$out/"
for f in "${icons[@]}"; do
	test -s "$pwa/$f" || { echo "falta web/pwa/$f" >&2; exit 1; }
	cp "$pwa/$f" "$out/"
done
# O preset (html/export_icon) injeta index.apple-touch-icon.png e index.icon.png com o ícone do projeto:
# sobrescreve com os ícones do app para o iOS não pegar o errado.
cp "$pwa/apple-touch-icon-180.png" "$out/index.apple-touch-icon.png"
cp "$pwa/icon-192.png" "$out/index.icon.png"
echo "PWA: manifesto e ${#icons[@]} ícones copiados para $out"
