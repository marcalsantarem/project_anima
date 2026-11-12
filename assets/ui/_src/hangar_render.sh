#!/usr/bin/env bash
# T-198 (BRF-143): renderiza o mockup do hangar em docs/img/ com o Chrome headless.
set -e
cd "$(dirname "$0")"
CHROME="/c/Program Files/Google/Chrome/Application/chrome.exe"
HERE="$(pwd -W 2>/dev/null || pwd)"
OUT="$HERE/../../../docs/img"
shot() { "$CHROME" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files \
  --force-device-scale-factor=$3 --window-size=$2 --virtual-time-budget=1500 \
  --screenshot="$OUT/$4" "file:///$HERE/hangar_mockup.html#$1"; }
shot a 375,812 2 hangar-opcao-a-375x812.png
shot b 375,812 2 hangar-opcao-b-375x812.png
shot a_child 375,812 2 hangar-opcao-a-tela-filha-375x812.png
shot wide 1280,720 1 hangar-1280x720.png
