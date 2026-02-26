#!/bin/bash
set -euo pipefail

CFG="/boot/firmware/config.txt"
OVERLAYS_DIR="/boot/firmware/overlays"

TITLE="#---- Waveshare 3.5in DSI E Display ----"
read -r -d '' BLOCK <<'EOF' || true
#---- Waveshare 3.5in DSI E Display ----
dtoverlay=vc4-kms-v3d
#DSI1 Use
dtoverlay=waveshare_35DSI,35E,dsi1
#DSI0 Use
#dtoverlay=waveshare_35DSI,35E,dsi0
EOF

mkdir -p /tmp/ws35e
cd /tmp/ws35e
wget -nv -O Waveshare_35DSI.dtbo https://files.waveshare.com/wiki/common/Waveshare_35DSI.dtbo

mkdir -p "${OVERLAYS_DIR}"
install -m 0644 Waveshare_35DSI.dtbo "${OVERLAYS_DIR}/Waveshare_35DSI.dtbo"

mkdir -p "$(dirname "${CFG}")"
touch "${CFG}"
if ! grep -qF "${TITLE}" "${CFG}"; then
  printf "\n%s\n" "${BLOCK}" >> "${CFG}"
fi