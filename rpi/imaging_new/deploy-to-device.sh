#!/bin/bash
# =============================================================================
# deploy-to-device.sh — Run on your DEVELOPMENT machine
# Cross-compiles and deploys Flutter apps to a Polypod device.
# =============================================================================
set -euo pipefail

DEVICE="${POLYPOD_DEVICE:-pi@polypod.local}"
TOP_PROJECT="${1:-}"
BOTTOM_PROJECT="${2:-}"
BACKEND="${FLUTTER_BACKEND:-wayland}"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log()  { echo -e "${GREEN}[deploy]${NC} $*"; }
err()  { echo -e "${RED}[deploy]${NC} $*" >&2; }

usage() {
    cat << 'EOF'
Usage: ./deploy-to-device.sh [TOP_PROJECT_DIR] [BOTTOM_PROJECT_DIR]

Environment:
  POLYPOD_DEVICE=pi@polypod.local    SSH target (default: pi@polypod.local)
  FLUTTER_BACKEND=wayland            Flutter backend (default: wayland)

Examples:
  # Deploy both apps
  ./deploy-to-device.sh ./polypod_top_window ./polypod_bottom_window

  # Deploy only top app
  ./deploy-to-device.sh ./polypod_top_window

  # Deploy to specific device
  POLYPOD_DEVICE=pi@192.168.1.50 ./deploy-to-device.sh ./top ./bottom
EOF
    exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && usage

# Verify flutter-elinux is available
if ! command -v flutter-elinux >/dev/null 2>&1; then
    err "flutter-elinux not found. Install with: flutter pub global activate flutter-elinux"
    exit 1
fi

# Verify SSH connectivity
log "Checking connectivity to $DEVICE..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$DEVICE" true 2>/dev/null; then
    err "Cannot reach $DEVICE. Check SSH config and device network."
    exit 1
fi

build_and_deploy() {
    local project_dir="$1"
    local target_name="$2"  # "top" or "bottom"
    local remote_dir="/opt/polypod/${target_name}"

    if [ ! -d "$project_dir" ]; then
        err "Project directory not found: $project_dir"
        return 1
    fi

    log "Building $target_name from $project_dir..."
    cd "$project_dir"

    flutter-elinux build elinux \
        --target-arch=arm64 \
        --target-backend-type="$BACKEND" \
        --release

    local bundle_dir="build/elinux/arm64/release/bundle"
    if [ ! -d "$bundle_dir" ]; then
        err "Build output not found: $bundle_dir"
        return 1
    fi

    log "Deploying $target_name to $DEVICE:$remote_dir..."
    rsync -az --delete --progress \
        "$bundle_dir/" \
        "${DEVICE}:${remote_dir}/"

    cd - >/dev/null
    log "$target_name deployed successfully."
}

# Build and deploy
if [ -n "$TOP_PROJECT" ]; then
    build_and_deploy "$TOP_PROJECT" "top"
fi

if [ -n "$BOTTOM_PROJECT" ]; then
    build_and_deploy "$BOTTOM_PROJECT" "bottom"
fi

if [ -z "$TOP_PROJECT" ] && [ -z "$BOTTOM_PROJECT" ]; then
    usage
fi

# Restart apps on device
log "Restarting apps on device..."
ssh "$DEVICE" "polypod-deploy.sh --restart"

log "Done! Apps should be running on the device."
