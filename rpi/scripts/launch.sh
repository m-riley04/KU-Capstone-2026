#!/bin/bash

# This script launches the Polypod application in release mode.

echo "Date: $(date)"
echo "PATH: $PATH"
echo "Flutter path: $(whereis flutter)"

DEVELOP_DIR=$HOME/develop
REPO_DIR=$DEVELOP_DIR/KU-Capstone-2026
POLYPOD_UI_ROOT=$REPO_DIR/rpi/src/polypod_hw

# Error handling
if [ ! -d "$POLYPOD_UI_ROOT" ]; then
    echo "Error: Directory $POLYPOD_UI_ROOT does not exist."
    exit 1
fi

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

# Launch the Polypod application with flutter
cd $POLYPOD_UI_ROOT
flutter run --release

echo "Polypod application has exited. Check launch.log for output and errors."