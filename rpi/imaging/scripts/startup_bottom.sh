#!/bin/bash
set -euo pipefail

APP_DIR="/opt/polypod/app"
BIN="$(find "${APP_DIR}" -maxdepth 1 -type f -executable | head -n 1 || true)"
if [[ -z "${BIN}" ]]; then
  echo "[startup_bottom] ERROR: No executable found in ${APP_DIR}"
  exit 1
fi

# Find the DSI display's DRM card dynamically
DSI_CARD=""
for connector in /sys/class/drm/card*-DSI-*; do
  if [[ -e "${connector}" ]]; then
    cardname="${connector##*/}"
    cardname="${cardname%%-DSI-*}"
    DSI_CARD="/dev/dri/${cardname}"
    break
  fi
done

if [[ -z "${DSI_CARD}" ]]; then
  echo "[startup_bottom] ERROR: No DSI display found"
  exit 1
fi

echo "[startup_bottom] DSI display: ${DSI_CARD}"
export WLR_DRM_DEVICES="${DSI_CARD}"

# DSI uses rp1-dsi driver which may lack EGL — use CPU rendering to be safe
export WLR_RENDERER=pixman

cd "${APP_DIR}"
export POLYPOD_WINDOW=bottom
exec cage -s -- "${BIN}"