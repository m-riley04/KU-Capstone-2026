#!/bin/bash

# This script launches the Polypod application in release mode.

echo "Date: $(date)"
echo "PATH: $PATH"
echo "Flutter path: $(whereis flutter)"

DEVELOP_DIR=$HOME/develop
REPO_DIR=$DEVELOP_DIR/KU-Capstone-2026
POLYPOD_UI_ROOT=$REPO_DIR/rpi/src/polypod_hw
CAMERA_STREAM_ROOT=$REPO_DIR/rpi/src/camera_stream
MEDIAMTX_BIN=$CAMERA_STREAM_ROOT/mediamtx
MEDIAMTX_CONFIG=$CAMERA_STREAM_ROOT/mediamtx.yml
MEDIAMTX_PID=""

# Error handling
if [ ! -d "$POLYPOD_UI_ROOT" ]; then
    echo "Error: Directory $POLYPOD_UI_ROOT does not exist."
    exit 1
fi

if [ ! -x "$MEDIAMTX_BIN" ]; then
    echo "Error: MediaMTX binary $MEDIAMTX_BIN is missing or not executable."
    echo "Try running: chmod +x $MEDIAMTX_BIN"
    exit 1
fi

if [ ! -f "$MEDIAMTX_CONFIG" ]; then
    echo "Error: MediaMTX config file $MEDIAMTX_CONFIG does not exist."
    exit 1
fi

cleanup() {
    if [ -n "$MEDIAMTX_PID" ] && kill -0 "$MEDIAMTX_PID" > /dev/null 2>&1; then
        echo "Stopping MediaMTX (PID: $MEDIAMTX_PID)..."
        kill "$MEDIAMTX_PID" > /dev/null 2>&1
        wait "$MEDIAMTX_PID" 2>/dev/null
    fi
}

trap cleanup EXIT INT TERM

# Ensure Wayland environment is set when labwc is running.
# When launched from autostart these are already present, but when launched
# manually (e.g. from SSH) they may be missing.
if pgrep -x labwc > /dev/null 2>&1; then
    export XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-wayland}"
    export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
    export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    echo "Detected labwc - Wayland env: WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
fi

echo "Launching Polypod application in release mode..."

# TODO: add more error handling or dependency checking?

echo "Starting MediaMTX..."
cd "$CAMERA_STREAM_ROOT"
"$MEDIAMTX_BIN" "$MEDIAMTX_CONFIG" &
MEDIAMTX_PID=$!

# Give MediaMTX a moment to start and fail fast if it immediately exits.
sleep 1
if ! kill -0 "$MEDIAMTX_PID" > /dev/null 2>&1; then
    echo "Error: MediaMTX failed to start."
    exit 1
fi

# Launch the Polypod application with flutter
cd "$POLYPOD_UI_ROOT"
flutter run --release
FLUTTER_EXIT_CODE=$?

echo "Polypod application has exited. Check launch.log for output and errors."
exit "$FLUTTER_EXIT_CODE"