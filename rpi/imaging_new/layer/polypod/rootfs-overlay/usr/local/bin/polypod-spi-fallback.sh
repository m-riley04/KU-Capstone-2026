#!/bin/sh
# =============================================================================
# /usr/local/bin/polypod-spi-fallback.sh
# Runs the bottom window directly on the SPI DRM device, bypassing Sway.
# =============================================================================
set -e
. /etc/polypod/polypod.conf

log() { echo "[spi-fallback] $*"; }

log "Starting bottom window on $POLYPOD_SPI_DRM_DEVICE"
export FLUTTER_DRM_DEVICE="${POLYPOD_SPI_DRM_DEVICE}"

APP="${POLYPOD_APP_BUNDLE}/${POLYPOD_APP_BINARY}"

# Wait for binary to exist
MAX_WAIT=60; WAITED=0
while [ ! -x "$APP" ] && [ "$WAITED" -lt "$MAX_WAIT" ]; do
    log "Waiting for $APP... ($WAITED/$MAX_WAIT)"
    sleep 2; WAITED=$((WAITED + 2))
done

[ ! -x "$APP" ] && { log "ERROR: $APP not found"; exit 1; }

exec "$APP" ${POLYPOD_BOTTOM_ELINUX_ARGS} -- ${POLYPOD_BOTTOM_ARGS}
