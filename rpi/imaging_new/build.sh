#!/bin/bash
# =============================================================================
# Polypod Image Builder
# All generated artifacts go into work/ (the only gitignored directory).
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="${SCRIPT_DIR}/work"
CONFIG="${SCRIPT_DIR}/config/polypod-kiosk.yaml"
RPI_IMAGE_GEN="${RPI_IMAGE_GEN:-rpi-image-gen}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[build]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[error]${NC} $*" >&2; }

usage() {
    cat << 'EOF'
Usage: ./build.sh [OPTIONS] [-- rpi-image-gen overrides...]

Options:
  --config <file>     Alternate config YAML
  --dev-mode          HDMI-A-1 replaces DSI-2 for top window
  --spi-fallback      Bottom app renders directly to SPI DRM
  --no-spi            Disable SPI display
  --no-dsi            Disable DSI display
  --build-flutter     Run build-flutter-apps.sh before image build
  --flutter-branch <b> Git branch for Flutter app (default: main)
  --flutter-local <p> Use local Flutter project checkout
  --cache-overlays    Download overlays/firmware into work/ for offline builds
  --fs-only           Rebuild filesystem only
  --image-only        Regenerate image from existing filesystem
  --password <pass>   Pi user password
  --ssh-key <file>    SSH public key file
  --hostname <name>   Device hostname
  --debug             Enable debug logging in built image
  --dry-run           Show commands without executing
  --help              Show this help

All build artifacts go into work/ (the only gitignored directory):
  work/flutter-bundle/   Pre-built Flutter app
  work/overlays/         Cached .dtbo files
  work/firmware/         Cached firmware binaries
  work/repo-cache/       Cloned source repo
  work/chroot-*/         rpi-image-gen filesystem
  work/image-*/          rpi-image-gen output image
EOF
    exit 0
}

DEV_MODE=0; SPI_FALLBACK=0; NO_SPI=0; NO_DSI=0; CACHE_ONLY=0
FS_ONLY=0; IMAGE_ONLY=0; DRY_RUN=0; DEBUG=0; BUILD_FLUTTER=0
PASSWORD=""; SSH_KEY=""; HOSTNAME_OVERRIDE=""
FLUTTER_BRANCH="main"; FLUTTER_LOCAL=""
EXTRA_ARGS=()

while [ $# -gt 0 ]; do
    case "$1" in
        --config)          CONFIG="$2"; shift 2 ;;
        --dev-mode)        DEV_MODE=1; shift ;;
        --spi-fallback)    SPI_FALLBACK=1; shift ;;
        --no-spi)          NO_SPI=1; shift ;;
        --no-dsi)          NO_DSI=1; shift ;;
        --build-flutter)   BUILD_FLUTTER=1; shift ;;
        --flutter-branch)  FLUTTER_BRANCH="$2"; shift 2 ;;
        --flutter-local)   FLUTTER_LOCAL="$2"; shift 2 ;;
        --cache-overlays)  CACHE_ONLY=1; shift ;;
        --fs-only)         FS_ONLY=1; shift ;;
        --image-only)      IMAGE_ONLY=1; shift ;;
        --password)        PASSWORD="$2"; shift 2 ;;
        --ssh-key)         SSH_KEY="$2"; shift 2 ;;
        --hostname)        HOSTNAME_OVERRIDE="$2"; shift 2 ;;
        --debug)           DEBUG=1; shift ;;
        --dry-run)         DRY_RUN=1; shift ;;
        --help|-h)         usage ;;
        --)                shift; EXTRA_ARGS=("$@"); break ;;
        *)                 err "Unknown option: $1"; usage ;;
    esac
done

mkdir -p "$WORK_DIR"

# --- Cache overlays into work/ ---
cache_overlays() {
    log "Caching overlay files into work/..."
    mkdir -p "${WORK_DIR}/overlays" "${WORK_DIR}/firmware"
    if [ ! -f "${WORK_DIR}/overlays/Waveshare_35DSI.dtbo" ]; then
        log "  Downloading Waveshare_35DSI.dtbo..."
        wget -q -O "${WORK_DIR}/overlays/Waveshare_35DSI.dtbo" \
            "https://files.waveshare.com/wiki/common/Waveshare_35DSI.dtbo"
    else
        log "  Waveshare_35DSI.dtbo already cached."
    fi
    if [ ! -f "${WORK_DIR}/firmware/st7796s.bin" ]; then
        log "  Downloading ST7796S firmware..."
        cd /tmp; wget -q "https://files.waveshare.com/wiki/common/St7796s.zip"
        unzip -o St7796s.zip; cp st7796s.bin "${WORK_DIR}/firmware/st7796s.bin"
        rm -f St7796s.zip st7796s.bin; cd "$SCRIPT_DIR"
    else
        log "  st7796s.bin already cached."
    fi
    log "Done."
}

[ "$CACHE_ONLY" = "1" ] && { cache_overlays; exit 0; }

# --- Build Flutter if requested ---
if [ "$BUILD_FLUTTER" = "1" ]; then
    log "Building Flutter app..."
    FLUTTER_ARGS=("--branch" "$FLUTTER_BRANCH")
    [ -n "$FLUTTER_LOCAL" ] && FLUTTER_ARGS=("--local" "$FLUTTER_LOCAL")
    "${SCRIPT_DIR}/build-flutter-apps.sh" "${FLUTTER_ARGS[@]}"
fi

# --- Check for pre-built bundle ---
if [ ! -d "${WORK_DIR}/flutter-bundle" ] || [ -z "$(ls -A "${WORK_DIR}/flutter-bundle" 2>/dev/null)" ]; then
    warn "No work/flutter-bundle/ found. The image will boot but apps won't start."
    warn "Run: ./build-flutter-apps.sh   (or use --build-flutter)"
fi

# --- Validate rpi-image-gen ---
if ! command -v "$RPI_IMAGE_GEN" >/dev/null 2>&1; then
    err "rpi-image-gen not found. Clone from https://github.com/raspberrypi/rpi-image-gen"
    exit 1
fi

# --- Apply config patches (temporary, restored after build) ---
CONF_FILE="${SCRIPT_DIR}/layer/polypod/rootfs-overlay/etc/polypod/polypod.conf"
CONFIG_TXT="${SCRIPT_DIR}/layer/polypod/rootfs-overlay/boot/firmware/config.txt"
cp "$CONF_FILE" "${CONF_FILE}.orig"; cp "$CONFIG_TXT" "${CONFIG_TXT}.orig"
trap 'mv "${CONF_FILE}.orig" "$CONF_FILE" 2>/dev/null; mv "${CONFIG_TXT}.orig" "$CONFIG_TXT" 2>/dev/null' EXIT

patch_conf() { sed -i "s|^${1}=.*|${1}=\"${2}\"|" "$CONF_FILE"; }

[ "$DEV_MODE" = "1" ]     && { patch_conf POLYPOD_HDMI_DEV_MODE 1; patch_conf POLYPOD_TOP_OUTPUT HDMI-A-1; patch_conf POLYPOD_TOP_RES 1920x1080; }
[ "$SPI_FALLBACK" = "1" ] && patch_conf POLYPOD_SPI_FALLBACK 1
[ "$DEBUG" = "1" ]        && patch_conf POLYPOD_DEBUG 1

if [ "$NO_SPI" = "1" ]; then
    sed -i '/^dtoverlay=mipi-dbi-spi/s/^/#/;/^dtparam=compatible=st7796s/s/^/#/;/^dtparam=width=320/s/^/#/' "$CONFIG_TXT"
    sed -i '/^dtparam=reset-gpio/s/^/#/;/^dtoverlay=ads7846/s/^/#/;/^extra_transpose_buffer/s/^/#/' "$CONFIG_TXT"
    patch_conf POLYPOD_BOTTOM_OUTPUT HDMI-A-2; patch_conf POLYPOD_BOTTOM_RES 1920x1080
fi
if [ "$NO_DSI" = "1" ]; then
    sed -i '/^display_auto_detect=0/s/^/#/;/^dtoverlay=vc4-kms-dsi-generic/s/^/#/;/^dtoverlay=Waveshare_35DSI/s/^/#/' "$CONFIG_TXT"
    patch_conf POLYPOD_TOP_OUTPUT HDMI-A-1; patch_conf POLYPOD_TOP_RES 1920x1080
fi

# --- Build args ---
BUILD_ARGS=("build" "-S" "$SCRIPT_DIR" "-c" "$CONFIG")
[ "$FS_ONLY" = "1" ]    && BUILD_ARGS+=("-f")
[ "$IMAGE_ONLY" = "1" ] && BUILD_ARGS+=("-i")
[ -n "$PASSWORD" ]       && EXTRA_ARGS+=("IGconf_device_user1pass=$PASSWORD")
[ -n "$SSH_KEY" ] && [ -f "$SSH_KEY" ] && EXTRA_ARGS+=("IGconf_ssh_pubkey_user1=$(cat "$SSH_KEY")")
[ -n "$HOSTNAME_OVERRIDE" ] && EXTRA_ARGS+=("IGconf_device_hostname=$HOSTNAME_OVERRIDE")
[ ${#EXTRA_ARGS[@]} -gt 0 ] && BUILD_ARGS+=("--" "${EXTRA_ARGS[@]}")

if [ "$DRY_RUN" = "1" ]; then
    log "DRY RUN: $RPI_IMAGE_GEN ${BUILD_ARGS[*]}"
    diff "${CONF_FILE}.orig" "$CONF_FILE" || true
    exit 0
fi

log "Building image..."
"$RPI_IMAGE_GEN" "${BUILD_ARGS[@]}"

log "Done! Flash with: sudo dd if=work/polypod-kiosk.img of=/dev/sdX bs=4M status=progress"
