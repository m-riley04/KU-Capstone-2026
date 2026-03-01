#!/bin/sh
# =============================================================================
# /usr/local/bin/polypod-identify-displays.sh
# Enumerates displays and maps touch inputs to correct outputs.
# =============================================================================
set -e
. /etc/polypod/polypod.conf

log() { echo "[identify] $*"; }

list_drm() {
    log "=== DRM Connectors ==="
    for card in /sys/class/drm/card*-*; do
        name=$(basename "$card" | sed 's/card[0-9]*-//')
        status=$(cat "$card/status" 2>/dev/null || echo "unknown")
        log "  $name: $status"
    done
}

list_sway() {
    if command -v swaymsg >/dev/null 2>&1 && [ -n "$SWAYSOCK" ]; then
        log "=== Sway Outputs ==="
        swaymsg -t get_outputs 2>/dev/null | jq -r '.[] | "  \(.name): \(.current_mode.width)x\(.current_mode.height) active=\(.active)"' || true
    fi
}

map_touch() {
    [ -z "$SWAYSOCK" ] && return

    log "=== Mapping Touch Inputs ==="
    INPUTS=$(swaymsg -t get_inputs 2>/dev/null || echo "[]")

    # Goodix (DSI capacitive) → top output
    GOODIX_ID=$(echo "$INPUTS" | jq -r '.[] | select(.name | contains("Goodix")) | .identifier' | head -1)
    [ -n "$GOODIX_ID" ] && [ "$GOODIX_ID" != "null" ] && {
        log "  Goodix ($GOODIX_ID) → $POLYPOD_TOP_OUTPUT"
        swaymsg "input \"$GOODIX_ID\" map_to_output $POLYPOD_TOP_OUTPUT" 2>/dev/null || true
    }

    # ADS7846 (SPI resistive) → bottom output
    ADS_ID=$(echo "$INPUTS" | jq -r '.[] | select(.name | contains("ADS7846")) | .identifier' | head -1)
    [ -n "$ADS_ID" ] && [ "$ADS_ID" != "null" ] && {
        log "  ADS7846 ($ADS_ID) → $POLYPOD_BOTTOM_OUTPUT"
        swaymsg "input \"$ADS_ID\" map_to_output $POLYPOD_BOTTOM_OUTPUT" 2>/dev/null || true
    }
}

case "${1:-}" in
    --label)
        list_drm; list_sway
        swaymsg -t get_outputs 2>/dev/null | jq -r '.[] | .name' | while read -r out; do
            swaynag -m "Output: $out" --output "$out" &
        done
        sleep 5; pkill swaynag 2>/dev/null || true ;;
    --map) map_touch ;;
    *)     list_drm; list_sway; map_touch ;;
esac
