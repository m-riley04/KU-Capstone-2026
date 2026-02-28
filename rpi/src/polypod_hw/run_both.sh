#!/usr/bin/env bash
# run_both.sh — Development launcher for Polypod dual-window mode.
#
# This script kills any leftover polypod_hw zombie processes BEFORE
# launching flutter run, preventing the hangflutter run's debugger
# race condition where it discovers a stale VM service.
#
# Usage:
#   ./run_both.sh            # default: both windows (auto-spawn)
#   ./run_both.sh --single   # single combined window
#   ./run_both.sh --top      # top window only
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ── Kill zombies from previous runs ─────────────────────────────────────────
PIDFILE="/tmp/polypod_bottom.pid"
if [[ -f "$PIDFILE" ]]; then
  OLD_PID=$(<"$PIDFILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    echo "[run_both] Killing leftover bottom window (pid=$OLD_PID)"
    kill -9 "$OLD_PID" 2>/dev/null || true
  fi
  rm -f "$PIDFILE"
fi

# Also sweep any stale polypod_hw binaries (belt-and-suspenders).
pkill -9 -x polypod_hw 2>/dev/null || true
sleep 0.5

# ── Launch ──────────────────────────────────────────────────────────────────
flutter run "$@"
