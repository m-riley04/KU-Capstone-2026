#!/bin/bash
set -euo pipefail

SCRIPTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
INIT_DIR="$SCRIPTS_DIR/initializations"

echo "[init] POLYPOD_USER=${POLYPOD_USER:-pod}"

# 1) Display provisioning (downloads during build)
bash "$INIT_DIR/init_waveshare35e.sh"
bash "$INIT_DIR/init_waveshare35g.sh"

# 2) Flutter install (clone + basic init) as non-root user
bash "$INIT_DIR/init_flutter.sh"

# 3) Clone/build your app and install bundle into /opt/polypod/app
bash "$INIT_DIR/init_app_build.sh"

echo "[init] Complete."