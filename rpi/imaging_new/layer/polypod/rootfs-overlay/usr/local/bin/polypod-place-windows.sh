#!/bin/sh
# =============================================================================
# /usr/local/bin/polypod-place-windows.sh
# Watches Sway for new windows and moves them to the correct output.
#
# Because both top and bottom are the SAME binary (same app_id), we can't
# use Sway assign rules. Instead, this script subscribes to Sway window
# events and moves the second window of the same app_id to the bottom output.
# =============================================================================
set -e

. /etc/polypod/polypod.conf

log() { echo "[place] $(date '+%H:%M:%S') $*"; }

# Wait for Sway to be ready
sleep 2

WINDOW_COUNT=0

log "Watching for polypod_hw windows..."
log "  First  → $POLYPOD_TOP_OUTPUT"
log "  Second → $POLYPOD_BOTTOM_OUTPUT"

# Subscribe to window events
swaymsg -t subscribe '["window"]' --monitor | while read -r event; do
    # Only act on "new" window events for our app
    CHANGE=$(echo "$event" | jq -r '.change // empty' 2>/dev/null)
    APP_ID=$(echo "$event" | jq -r '.container.app_id // empty' 2>/dev/null)
    CON_ID=$(echo "$event" | jq -r '.container.id // empty' 2>/dev/null)

    if [ "$CHANGE" != "new" ] || [ -z "$APP_ID" ]; then
        continue
    fi

    if [ "$APP_ID" = "$POLYPOD_TOP_APP_ID" ]; then
        WINDOW_COUNT=$((WINDOW_COUNT + 1))
        log "Window #${WINDOW_COUNT} opened: app_id=$APP_ID con_id=$CON_ID"

        if [ "$WINDOW_COUNT" -eq 1 ]; then
            # First window → top output
            log "Moving window $CON_ID → $POLYPOD_TOP_OUTPUT (top)"
            swaymsg "[con_id=$CON_ID] move to output $POLYPOD_TOP_OUTPUT" 2>/dev/null || true
            swaymsg "[con_id=$CON_ID] fullscreen enable" 2>/dev/null || true
        elif [ "$WINDOW_COUNT" -eq 2 ]; then
            # Second window → bottom output
            log "Moving window $CON_ID → $POLYPOD_BOTTOM_OUTPUT (bottom)"
            swaymsg "[con_id=$CON_ID] move to output $POLYPOD_BOTTOM_OUTPUT" 2>/dev/null || true
            swaymsg "[con_id=$CON_ID] fullscreen enable" 2>/dev/null || true
        fi
    fi
done
