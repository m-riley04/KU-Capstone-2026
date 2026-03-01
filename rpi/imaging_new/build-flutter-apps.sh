#!/bin/bash
# =============================================================================
# build-flutter-apps.sh
# Clones the Polypod repo and cross-compiles the Flutter app for arm64.
# All generated artifacts go into work/ (overlays, firmware, flutter-bundle, repo-cache).
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="${SCRIPT_DIR}/work"
STAGING_DIR="${WORK_DIR}/flutter-bundle"
REPO_CACHE="${WORK_DIR}/repo-cache"
REPO_URL="https://github.com/m-riley04/KU-Capstone-2026.git"
REPO_BRANCH="main"
FLUTTER_APP_SUBDIR="rpi/src/polypod_hw"
LOCAL_REPO=""
INSTALL_FELINUX=0
FLUTTER_ELINUX="${FLUTTER_ELINUX:-/opt/flutter-elinux/bin/flutter-elinux}"
SKIP_CLONE=0

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[flutter]${NC} $*"; }
warn() { echo -e "${YELLOW}[flutter]${NC} $*"; }
err()  { echo -e "${RED}[flutter]${NC} $*" >&2; }

usage() {
    cat << 'EOF'
Usage: ./build-flutter-apps.sh [OPTIONS]

Options:
  --install-flutter-elinux   Install flutter-elinux to /opt/flutter-elinux
  --branch <branch>          Git branch to build (default: main)
  --local <path>             Use a local repo checkout instead of cloning
  --skip-clone               Reuse previously cloned repo in work/repo-cache/
  --repo-url <url>           Override the git repo URL
  --app-subdir <path>        Override Flutter app subdirectory
  --help                     Show this help

All output goes into work/:
  work/flutter-bundle/       Cross-compiled arm64 Wayland bundle
  work/repo-cache/           Cloned repo (reused with --skip-clone)

Examples:
  ./build-flutter-apps.sh --install-flutter-elinux
  ./build-flutter-apps.sh
  ./build-flutter-apps.sh --skip-clone
  ./build-flutter-apps.sh --local ~/code/KU-Capstone-2026
  ./build-flutter-apps.sh --branch feature/new-ui
EOF
    exit 0
}

while [ $# -gt 0 ]; do
    case "$1" in
        --install-flutter-elinux) INSTALL_FELINUX=1; shift ;;
        --branch)        REPO_BRANCH="$2"; shift 2 ;;
        --local)         LOCAL_REPO="$2"; shift 2 ;;
        --skip-clone)    SKIP_CLONE=1; shift ;;
        --repo-url)      REPO_URL="$2"; shift 2 ;;
        --app-subdir)    FLUTTER_APP_SUBDIR="$2"; shift 2 ;;
        --help|-h)       usage ;;
        *)               err "Unknown option: $1"; usage ;;
    esac
done

mkdir -p "$WORK_DIR"

# =============================================================================
# Install flutter-elinux
# =============================================================================
install_flutter_elinux() {
    if [ -d "/opt/flutter-elinux" ]; then
        log "flutter-elinux already installed at /opt/flutter-elinux"
        return
    fi
    log "Installing flutter-elinux..."
    for cmd in git curl clang cmake pkg-config unzip; do
        command -v "$cmd" >/dev/null 2>&1 || { err "Missing: $cmd"; exit 1; }
    done
    sudo git clone https://github.com/sony/flutter-elinux.git /opt/flutter-elinux
    if ! echo "$PATH" | grep -q "/opt/flutter-elinux/bin"; then
        warn "Add to your shell profile:  export PATH=\$PATH:/opt/flutter-elinux/bin"
        export PATH="$PATH:/opt/flutter-elinux/bin"
    fi
    /opt/flutter-elinux/bin/flutter-elinux doctor || true
}

if [ "$INSTALL_FELINUX" = "1" ]; then
    install_flutter_elinux
    [ -z "$LOCAL_REPO" ] && [ "$SKIP_CLONE" = "0" ] && { log "Done. Run again to build."; exit 0; }
fi

# =============================================================================
# Verify flutter-elinux
# =============================================================================
if ! command -v flutter-elinux >/dev/null 2>&1; then
    if [ -x "/opt/flutter-elinux/bin/flutter-elinux" ]; then
        export PATH="/opt/flutter-elinux/bin:$PATH"
    else
        err "flutter-elinux not found. Run: ./build-flutter-apps.sh --install-flutter-elinux"
        exit 1
    fi
fi
log "Using: $(which flutter-elinux)"

# =============================================================================
# Get source code
# =============================================================================
if [ -n "$LOCAL_REPO" ]; then
    log "Using local repo: $LOCAL_REPO"
    APP_DIR="${LOCAL_REPO}/${FLUTTER_APP_SUBDIR}"
elif [ "$SKIP_CLONE" = "1" ] && [ -d "$REPO_CACHE" ]; then
    log "Reusing cached repo at $REPO_CACHE"
    cd "$REPO_CACHE"
    git fetch origin "$REPO_BRANCH" 2>/dev/null || true
    git checkout "$REPO_BRANCH" 2>/dev/null || true
    git pull origin "$REPO_BRANCH" 2>/dev/null || true
    cd "$SCRIPT_DIR"
    APP_DIR="${REPO_CACHE}/${FLUTTER_APP_SUBDIR}"
else
    log "Cloning $REPO_URL (branch: $REPO_BRANCH)..."
    rm -rf "$REPO_CACHE"
    git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$REPO_CACHE"
    APP_DIR="${REPO_CACHE}/${FLUTTER_APP_SUBDIR}"
fi

if [ ! -f "${APP_DIR}/pubspec.yaml" ]; then
    err "No pubspec.yaml found at ${APP_DIR}"
    ls -la "$(dirname "$APP_DIR")" 2>/dev/null || true
    exit 1
fi
log "Flutter project: $APP_DIR"

# =============================================================================
# Build for arm64 Wayland
# =============================================================================
cd "$APP_DIR"
log "Getting dependencies..."
flutter-elinux pub get

log "Building for arm64 (Wayland, release)..."
flutter-elinux build elinux \
    --target-arch=arm64 \
    --target-backend-type=wayland \
    --release

BUILD_OUTPUT="${APP_DIR}/build/elinux/arm64/release/bundle"
[ ! -d "$BUILD_OUTPUT" ] && { err "Build output not found: $BUILD_OUTPUT"; exit 1; }

# =============================================================================
# Stage bundle into work/
# =============================================================================
cd "$SCRIPT_DIR"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -a "$BUILD_OUTPUT/." "$STAGING_DIR/"
chmod +x "$STAGING_DIR"/* 2>/dev/null || true

log "Bundle staged at: $STAGING_DIR ($(du -sh "$STAGING_DIR" | cut -f1))"
ls -la "$STAGING_DIR/"
log ""
log "Next: ./build.sh --password 'yourpass'"
