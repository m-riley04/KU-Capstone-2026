#!/bin/sh
# =============================================================================
# /usr/local/bin/polypod-setup-system.sh — Boot-time hardware detection
# =============================================================================
set -e
. /etc/polypod/polypod.conf

log() { echo "[setup] $*"; }

# Ensure directories
mkdir -p "${POLYPOD_APP_DIR}/app" "${POLYPOD_APP_DIR}/shared" "${POLYPOD_APP_DIR}/.backups"
chown -R pi:pi "${POLYPOD_APP_DIR}"

# XDG runtime dir
mkdir -p /run/user/1000
chown pi:pi /run/user/1000; chmod 700 /run/user/1000

# Watchdog
if [ -n "$POLYPOD_WATCHDOG_SEC" ] && [ "$POLYPOD_WATCHDOG_SEC" -gt 0 ] 2>/dev/null; then
    mkdir -p /etc/systemd/system.conf.d
    cat > /etc/systemd/system.conf.d/watchdog.conf << EOF
[Manager]
RuntimeWatchdogSec=${POLYPOD_WATCHDOG_SEC}
RebootWatchdogSec=180
EOF
fi

# Detect DRM devices
log "DRM devices:"
for card in /dev/dri/card*; do
    driver=$(basename "$(readlink -f "/sys/class/drm/$(basename "$card")/device/driver")" 2>/dev/null || echo "?")
    conns=$(ls /sys/class/drm/ 2>/dev/null | grep "^$(basename "$card")-" | sed "s/$(basename "$card")-//" | tr '\n' ' ')
    log "  $card: driver=$driver connectors=[$conns]"
done

# Display status
DSI_STATUS="disconnected"; HDMI1_STATUS="disconnected"
for c in /sys/class/drm/card*-DSI-*;    do [ -f "$c/status" ] && DSI_STATUS=$(cat "$c/status"); done
for c in /sys/class/drm/card*-HDMI-A-1; do [ -f "$c/status" ] && HDMI1_STATUS=$(cat "$c/status"); done
log "Displays: DSI=$DSI_STATUS HDMI-A-1=$HDMI1_STATUS"

# Auto dev-mode detection
if [ "$POLYPOD_HDMI_DEV_MODE" = "auto" ]; then
    if [ "$DSI_STATUS" = "disconnected" ] && [ "$HDMI1_STATUS" = "connected" ]; then
        log "Auto-detected dev mode (DSI absent, HDMI present)"
        sed -i 's/^POLYPOD_HDMI_DEV_MODE=.*/POLYPOD_HDMI_DEV_MODE="1"/' /etc/polypod/polypod.conf
    fi
fi

log "Setup complete."
