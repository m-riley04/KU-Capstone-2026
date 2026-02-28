#!/bin/bash
set -euo pipefail

APP_DIR="/opt/polypod/app"
BIN="$(find "${APP_DIR}" -maxdepth 1 -type f -executable | head -n 1 || true)"
if [[ -z "${BIN}" ]]; then
  echo "[startup_top] ERROR: No executable found in ${APP_DIR}"
  exit 1
fi

# Find the SPI display's DRM card dynamically
SPI_CARD=""
for connector in /sys/class/drm/card*-SPI-*; do
  if [[ -e "${connector}" ]]; then
    cardname="${connector##*/}"
    cardname="${cardname%%-SPI-*}"
    SPI_CARD="/dev/dri/${cardname}"
    break
  fi
done

if [[ -z "${SPI_CARD}" ]]; then
  echo "[startup_top] ERROR: No SPI display found"
  exit 1
fi

echo "[startup_top] SPI display: ${SPI_CARD}"
export WLR_DRM_DEVICES="${SPI_CARD}"

# SPI display has no GPU — use CPU rendering
export WLR_RENDERER=pixman

cd "${APP_DIR}"
export POLYPOD_WINDOW=top
exec cage -s -- "${BIN}"