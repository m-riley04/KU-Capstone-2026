#!/bin/bash
set -euo pipefail

CONFIG="/opt/polypod/scripts/sway_config"

if [[ ! -f "${CONFIG}" ]]; then
  echo "[startup] ERROR: Sway config not found at ${CONFIG}"
  exit 1
fi

# Collect all DRM devices that have display connectors (skip v3d/render-only).
# This ensures sway sees both the SPI and DSI/HDMI displays.
DRM_DEVICES=""
for card in /sys/class/drm/card*-*; do
  [[ -e "${card}" ]] || continue
  cardname="${card##*/}"
  cardname="${cardname%%-*}"
  devpath="/dev/dri/${cardname}"
  # Deduplicate
  if [[ ":${DRM_DEVICES}:" != *":${devpath}:"* ]]; then
    if [[ -n "${DRM_DEVICES}" ]]; then
      DRM_DEVICES="${DRM_DEVICES}:${devpath}"
    else
      DRM_DEVICES="${devpath}"
    fi
  fi
done

if [[ -z "${DRM_DEVICES}" ]]; then
  echo "[startup] ERROR: No display DRM devices found"
  exit 1
fi

echo "[startup] DRM devices: ${DRM_DEVICES}"
export WLR_DRM_DEVICES="${DRM_DEVICES}"

exec sway --config "${CONFIG}"