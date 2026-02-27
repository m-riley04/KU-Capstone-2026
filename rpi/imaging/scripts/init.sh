#!/bin/bash
set -euo pipefail

SCRIPTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
INIT_DIR="$SCRIPTS_DIR/initializations"

echo "[init] POLYPOD_USER=${POLYPOD_USER:-pod}"
echo "[init] POLYPOD_CACHE=${POLYPOD_CACHE:-<not set>}"
echo "[init] POLYPOD_PREBUILT=${POLYPOD_PREBUILT:-<not set>}"

# 1) Display drivers (fast — just downloads + config.txt edits)
bash "$INIT_DIR/init_waveshare35e.sh"
bash "$INIT_DIR/init_waveshare35g.sh"

# 2) Flutter install
bash "$INIT_DIR/init_flutter.sh"

# 3) Build/install the Flutter app
bash "$INIT_DIR/init_app_build.sh"

# 4) Install cage for kiosk mode
if ! command -v cage &>/dev/null; then
  apt-get install -y cage || echo "[init] WARNING: cage not available in repo"
fi

echo "[init] Complete."