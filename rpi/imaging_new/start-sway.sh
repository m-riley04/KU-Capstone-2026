#!/bin/sh
# =============================================================================
# /usr/local/bin/start-sway.sh
# Called by greetd to start Sway with Polypod environment variables.
# =============================================================================
set -e

CONF="/etc/polypod/polypod.conf"

# Source configuration
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
    POLYPOD_TOP_APP_ID="Polypod_Top_Window"
    POLYPOD_BOTTOM_APP_ID="Polypod_Bottom_Window"
    POLYPOD_SPI_FALLBACK="0"
    POLYPOD_MAIN_DRM_DEVICE="/dev/dri/card1"
    POLYPOD_SPI_DRM_DEVICE="/dev/dri/card0"
    POLYPOD_HDMI_DEV_MODE="0"
    POLYPOD_DEBUG="0"
fi

# --- Dev mode override: use HDMI-A-1 instead of DSI-2 ---
if [ "$POLYPOD_HDMI_DEV_MODE" = "1" ]; then
    echo "[start-sway] Dev mode: routing Top Window to HDMI-A-1"
    POLYPOD_TOP_OUTPUT="HDMI-A-1"
    POLYPOD_TOP_RES="1920x1080"
fi

# --- Export all variables for Sway config ---
export POLYPOD_TOP_OUTPUT
export POLYPOD_BOTTOM_OUTPUT
export POLYPOD_TOP_RES
export POLYPOD_BOTTOM_RES
export POLYPOD_TOP_TRANSFORM
export POLYPOD_BOTTOM_TRANSFORM
export POLYPOD_TOP_APP_ID
export POLYPOD_BOTTOM_APP_ID
export POLYPOD_SPI_FALLBACK
export POLYPOD_DEBUG

# --- Export for Flutter apps (they need these to find each other via IPC) ---
export POLYPOD_APP_DIR="${POLYPOD_APP_DIR:-/opt/polypod}"
export POLYPOD_IPC_SOCKET="${POLYPOD_APP_DIR}/shared/polypod.sock"

# --- Wayland environment ---
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=sway
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# --- Tell Sway which DRM devices to use ---
# Primary GPU (vc4 — HDMI + DSI) must be first.
# SPI DRM device (mipi-dbi-spi) is secondary.
if [ "$POLYPOD_SPI_FALLBACK" = "0" ]; then
    # Let Sway manage BOTH displays
    export WLR_DRM_DEVICES="${POLYPOD_MAIN_DRM_DEVICE}:${POLYPOD_SPI_DRM_DEVICE}"
    echo "[start-sway] Sway managing both DRM devices: $WLR_DRM_DEVICES"
else
    # Sway only manages the main GPU; SPI is handled separately
    export WLR_DRM_DEVICES="${POLYPOD_MAIN_DRM_DEVICE}"
    echo "[start-sway] SPI fallback mode: Sway on $WLR_DRM_DEVICES only"
fi

# --- GPU renderer ---
# Force OpenGL ES for better Pi 5 compatibility
export WLR_RENDERER=gles2

# --- Debug logging ---
if [ "$POLYPOD_DEBUG" = "1" ]; then
    export WAYLAND_DEBUG=1
    export WLR_DRM_DEBUG=1
    exec sway -d 2>&1 | tee /tmp/sway.log
else
    exec sway 2>/tmp/sway.log
fi
