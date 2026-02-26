#!/bin/bash
set -euo pipefail

APP_DIR="/opt/polypod/app"

# Find the first executable file in the bundle root (Flutter’s bundle puts the main binary there).
BIN="$(find "${APP_DIR}" -maxdepth 1 -type f -executable | head -n 1 || true)"
if [[ -z "${BIN}" ]]; then
  echo "[startup] ERROR: No executable found in ${APP_DIR}"
  exit 1
fi

cd "${APP_DIR}"
exec "${BIN}"