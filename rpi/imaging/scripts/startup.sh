#!/bin/bash
set -euo pipefail

APP_DIR="/opt/polypod/app"

# Find the Flutter binary
BIN="$(find "${APP_DIR}" -maxdepth 1 -type f -executable | head -n 1 || true)"
if [[ -z "${BIN}" ]]; then
  echo "[startup] ERROR: No executable found in ${APP_DIR}"
  exit 1
fi

cd "${APP_DIR}"

if command -v cage &>/dev/null; then
  echo "[startup] Launching via Cage (Wayland kiosk)"
  exec cage -s -- "${BIN}"
elif [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
  echo "[startup] Launching on existing Wayland session"
  exec "${BIN}"
elif [[ -n "${DISPLAY:-}" ]]; then
  echo "[startup] Launching on existing X11 session"
  exec "${BIN}"
else
  echo "[startup] ERROR: No display server available"
  exit 1
fi