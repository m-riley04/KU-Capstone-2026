#!/bin/sh
# =============================================================================
# /usr/local/bin/start-sway.sh — greetd → Sway launcher
# Sources polypod.conf and exports all env vars for Sway config.
# =============================================================================
set -e

CONF="/etc/polypod/polypod.conf"

if [ -f "$CONF" ]; then
    . "$CONF"
else
    echo "[start-sway] ERROR: $CONF not found, using defaults"
    POLYPOD_TOP_OUTPUT="HDMI-A-1"
    POLYPOD_BOTTOM_OUTPUT="HDMI-A-2"
    POLYPOD_TOP_RES="640x480"
    POLYPOD_BOTTOM_RES="320x480"
    POLYPOD_TOP_TRANSFORM="normal"
    POLYPOD_BOTTOM_TRANSFORM="normal"
    POLYPOD_TOP_APP_ID="polypod_hw"
    POLYPOD_BOTTOM_APP_ID="polypod_hw"
    POLYPOD_SPI_FALLBACK="0"
    POLYPOD_MAIN_DRM_DEVICE="/dev/dri/card1"
    POLYPOD_SPI_DRM_DEVICE="/dev/dri/card0"
    POLYPOD_HDMI_DEV_MODE="0"
    POLYPOD_DEBUG="0"
fi

# --- Dev mode: HDMI-A-1 replaces DSI-2 ---
if [ "$POLYPOD_HDMI_DEV_MODE" = "1" ]; then
    echo "[start-sway] Dev mode: Top Window → HDMI-A-1"
    POLYPOD_TOP_OUTPUT="HDMI-A-1"
    POLYPOD_TOP_RES="1920x1080"
fi

# --- Export for Sway config variable substitution ---
export POLYPOD_TOP_OUTPUT POLYPOD_BOTTOM_OUTPUT
export POLYPOD_TOP_RES POLYPOD_BOTTOM_RES
export POLYPOD_TOP_TRANSFORM POLYPOD_BOTTOM_TRANSFORM
export POLYPOD_TOP_APP_ID POLYPOD_BOTTOM_APP_ID
export POLYPOD_SPI_FALLBACK POLYPOD_DEBUG
export POLYPOD_APP_DIR="${POLYPOD_APP_DIR:-/opt/polypod}"
export POLYPOD_IPC_SOCKET="${POLYPOD_IPC_SOCKET:-${POLYPOD_APP_DIR}/shared/polypod.sock}"
export POLYPOD_SAME_APP_ID

# --- Wayland environment ---
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=sway
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# --- DRM device selection ---
if [ "$POLYPOD_SPI_FALLBACK" = "0" ]; then
    export WLR_DRM_DEVICES="${POLYPOD_MAIN_DRM_DEVICE}:${POLYPOD_SPI_DRM_DEVICE}"
    echo "[start-sway] Sway managing both DRM devices: $WLR_DRM_DEVICES"
else
    export WLR_DRM_DEVICES="${POLYPOD_MAIN_DRM_DEVICE}"
    echo "[start-sway] SPI fallback: Sway on $WLR_DRM_DEVICES only"
fi

export WLR_RENDERER=gles2

# --- Launch ---
if [ "$POLYPOD_DEBUG" = "1" ]; then
    export WAYLAND_DEBUG=1
    exec sway -d 2>&1 | tee /tmp/sway.log
else
    exec sway 2>/tmp/sway.log
fi
