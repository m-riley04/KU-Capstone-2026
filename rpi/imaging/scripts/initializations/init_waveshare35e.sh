#!/bin/bash
set -euo pipefail

# Waveshare 3.5" DSI LCD (E) — for Bookworm on Pi 5
# The driver is merged into the official kernel. We only need:
#   1. The overlay .dtbo file (if not already in the kernel tree)
#   2. config.txt entries

CFG="/boot/firmware/config.txt"
OVERLAYS_DIR="/boot/firmware/overlays"

echo "[ws35e] Provisioning Waveshare 3.5in DSI LCD (E)"

# Download the overlay
mkdir -p /tmp/ws35e
cd /tmp/ws35e
wget -nv -O Waveshare_35DSI.dtbo \
  https://files.waveshare.com/wiki/common/Waveshare_35DSI.dtbo || true

mkdir -p "${OVERLAYS_DIR}"
if [[ -f Waveshare_35DSI.dtbo ]]; then
  install -m 0644 Waveshare_35DSI.dtbo "${OVERLAYS_DIR}/Waveshare_35DSI.dtbo"
fi

# Ensure vc4-kms-v3d is present (the base template may already have it)
if ! grep -q '^dtoverlay=vc4-kms-v3d' "${CFG}" 2>/dev/null; then
  echo "[ws35e] Adding vc4-kms-v3d overlay"
  printf "\ndtoverlay=vc4-kms-v3d\n" >> "${CFG}"
else
  echo "[ws35e] vc4-kms-v3d already present in config.txt — skipping"
fi

# DSI display overlay (always add)
TITLE="#---- Waveshare 3.5in DSI E Display ----"
read -r -d '' BLOCK <<'CFGEOF' || true
#---- Waveshare 3.5in DSI E Display ----
# DSI1 (default on Pi 5)
dtoverlay=Waveshare_35DSI,35E,dsi1
# To use DSI0 instead, comment the above and uncomment:
#dtoverlay=Waveshare_35DSI,35E,dsi0
CFGEOF

if ! grep -qF "${TITLE}" "${CFG}"; then
  printf "\n%s\n" "${BLOCK}" >> "${CFG}"
fi

echo "[ws35e] Done."