#!/usr/bin/env bash
# Renderiza os mockups holográficos (T-180) em 375x812 @2x (750x1624) com o Chrome headless.
set -e
cd "$(dirname "$0")"
CHROME="/c/Program Files/Google/Chrome/Application/chrome.exe"
SRC="file:///$(pwd -W 2>/dev/null || pwd)/mockup_holo.html"
for s in menu menu_lvl1 result parts; do
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files \
    --force-device-scale-factor=2 --window-size=375,812 --virtual-time-budget=1500 \
    --screenshot="$(pwd -W 2>/dev/null || pwd)/../mockup_holo_${s}.png" "${SRC}#${s}"
done
