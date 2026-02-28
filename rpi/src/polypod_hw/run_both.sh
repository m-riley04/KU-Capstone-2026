#!/usr/bin/env bash
# run_both.sh — Launch both Polypod windows in separate processes (development)
# Run from the polypod_hw directory.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Starting Polypod top window..."
flutter run --dart-define=POLYPOD_WINDOW=top &
TOP_PID=$!

# Small delay so the IPC server has time to start before the client connects.
sleep 3

echo "Starting Polypod bottom window..."
flutter run --dart-define=POLYPOD_WINDOW=bottom &
BOTTOM_PID=$!

echo "Both windows launched (top PID=$TOP_PID, bottom PID=$BOTTOM_PID)."
wait
