#!/bin/bash
# =============================================================================
# deploy-to-device.sh — Run on your DEVELOPMENT machine
# Cross-compiles the Flutter app and deploys to a Polypod device.
#
# Prerequisites: flutter-elinux installed at /opt/flutter-elinux
#   git clone https://github.com/sony/flutter-elinux.git
#   sudo mv flutter-elinux /opt/
#   export PATH=$PATH:/opt/flutter-elinux/bin
# =============================================================================
set -euo pipefail

DEVICE="${POLYPOD_DEVICE:-pi@polypod.local}"
PROJECT_DIR="${1:-}"
BACKEND="${FLUTTER_BACKEND:-wayland}"

log()  { echo -e "\033[0;32m[deploy]\033[0m $*"; }
err()  { echo -e "\033[0;31m[deploy]\033[0m $*" >&2; }

usage() {
    cat << 'EOF'
Usage: ./deploy-to-device.sh <FLUTTER_PROJECT_DIR>

Environment:
  POLYPOD_DEVICE=pi@polypod.local   SSH target
  FLUTTER_BACKEND=wayland            flutter-elinux backend

Examples:
  ./deploy-to-device.sh ~/code/KU-Capstone-2026/rpi/src/polypod_hw
  POLYPOD_DEVICE=pi@192.168.1.50 ./deploy-to-device.sh ./polypod_hw
EOF
    exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && usage
[ -z "$PROJECT_DIR" ] && { err "Provide project directory"; usage; }
[ ! -f "$PROJECT_DIR/pubspec.yaml" ] && { err "No pubspec.yaml in $PROJECT_DIR"; exit 1; }

# Verify flutter-elinux
if ! command -v flutter-elinux >/dev/null 2>&1; then
    if [ -x "/opt/flutter-elinux/bin/flutter-elinux" ]; then
        export PATH="/opt/flutter-elinux/bin:$PATH"
    else
        err "flutter-elinux not found. Install:"
        err "  git clone https://github.com/sony/flutter-elinux.git"
        err "  sudo mv flutter-elinux /opt/"
        err "  export PATH=\$PATH:/opt/flutter-elinux/bin"
        exit 1
    fi
fi

# Verify SSH
log "Checking connectivity to $DEVICE..."
ssh -o ConnectTimeout=5 -o BatchMode=yes "$DEVICE" true 2>/dev/null || { err "Can't reach $DEVICE"; exit 1; }

# Build
cd "$PROJECT_DIR"
log "Getting dependencies..."
flutter-elinux pub get

log "Building for arm64 ($BACKEND)..."
flutter-elinux build elinux \
    --target-arch=arm64 \
    --target-backend-type="$BACKEND" \
    --release

BUNDLE="build/elinux/arm64/release/bundle"
[ ! -d "$BUNDLE" ] && { err "Build failed — no output at $BUNDLE"; exit 1; }

# Deploy
log "Deploying to $DEVICE:/opt/polypod/app/..."
rsync -az --delete --progress "$BUNDLE/" "${DEVICE}:/opt/polypod/app/"

# Restart
log "Restarting apps..."
ssh "$DEVICE" "polypod-deploy.sh --restart"
log "Done!"
