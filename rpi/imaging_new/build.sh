#!/bin/bash
# =============================================================================
# Polypod Image Builder
# Wraps rpi-image-gen with caching, validation, and convenience options.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="${SCRIPT_DIR}/config/polypod-kiosk.yaml"
RPI_IMAGE_GEN="${RPI_IMAGE_GEN:-rpi-image-gen}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[build]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[error]${NC} $*" >&2; }

usage() {
    cat << 'EOF'
Usage: ./build.sh [OPTIONS] [-- rpi-image-gen overrides...]

Options:
  --config <file>     Use alternate config YAML (default: config/polypod-kiosk.yaml)
  --dev-mode          Enable HDMI dev mode (no DSI display needed)
  --spi-fallback      Enable SPI fallback mode (bottom app bypasses Sway)
  --no-spi            Disable SPI display entirely
  --no-dsi            Disable DSI display entirely
  --cache-overlays    Download Waveshare overlays/firmware to overlays/ and firmware/
  --fs-only           Rebuild filesystem only (skip image generation)
  --image-only        Regenerate image from existing filesystem
  --password <pass>   Set the pi user password
  --ssh-key <file>    SSH public key file for remote access
  --hostname <name>   Set device hostname
  --debug             Enable debug logging in the built image
  --dry-run           Show what would be done without building
  --help              Show this help

Examples:
  # Full build with defaults
  ./build.sh

  # Dev build (HDMI instead of DSI, SPI fallback mode)
  ./build.sh --dev-mode --spi-fallback --debug

  # Pre-cache overlay files (useful for offline builds)
  ./build.sh --cache-overlays

  # Override rpi-image-gen settings
  ./build.sh -- IGconf_image_name=polypod-test IGconf_device_hostname=test-pi
EOF
    exit 0
}

# --- Parse arguments ---
DEV_MODE=0
SPI_FALLBACK=0
NO_SPI=0
NO_DSI=0
CACHE_ONLY=0
FS_ONLY=0
IMAGE_ONLY=0
DRY_RUN=0
DEBUG=0
PASSWORD=""
SSH_KEY=""
HOSTNAME_OVERRIDE=""
EXTRA_ARGS=()

while [ $# -gt 0 ]; do
    case "$1" in
        --config)       CONFIG="$2"; shift 2 ;;
        --dev-mode)     DEV_MODE=1; shift ;;
        --spi-fallback) SPI_FALLBACK=1; shift ;;
        --no-spi)       NO_SPI=1; shift ;;
        --no-dsi)       NO_DSI=1; shift ;;
        --cache-overlays) CACHE_ONLY=1; shift ;;
        --fs-only)      FS_ONLY=1; shift ;;
        --image-only)   IMAGE_ONLY=1; shift ;;
        --password)     PASSWORD="$2"; shift 2 ;;
        --ssh-key)      SSH_KEY="$2"; shift 2 ;;
        --hostname)     HOSTNAME_OVERRIDE="$2"; shift 2 ;;
        --debug)        DEBUG=1; shift ;;
        --dry-run)      DRY_RUN=1; shift ;;
        --help|-h)      usage ;;
        --)             shift; EXTRA_ARGS=("$@"); break ;;
        *)              err "Unknown option: $1"; usage ;;
    esac
done

# --- Validate prerequisites ---
if [ "$CACHE_ONLY" != "1" ]; then
    if ! command -v "$RPI_IMAGE_GEN" >/dev/null 2>&1; then
        err "rpi-image-gen not found. Install it or set RPI_IMAGE_GEN=/path/to/rpi-image-gen"
        err "  git clone https://github.com/raspberrypi/rpi-image-gen.git"
        exit 1
    fi
fi

# --- Cache overlay files ---
cache_overlays() {
    log "Caching Waveshare overlay files..."

    mkdir -p "${SCRIPT_DIR}/overlays" "${SCRIPT_DIR}/firmware"

    if [ ! -f "${SCRIPT_DIR}/overlays/Waveshare_35DSI.dtbo" ]; then
        log "  Downloading Waveshare_35DSI.dtbo..."
        wget -q -O "${SCRIPT_DIR}/overlays/Waveshare_35DSI.dtbo" \
            "https://files.waveshare.com/wiki/common/Waveshare_35DSI.dtbo"
    else
        log "  Waveshare_35DSI.dtbo already cached."
    fi

    if [ ! -f "${SCRIPT_DIR}/firmware/st7796s.bin" ]; then
        log "  Downloading ST7796S firmware..."
        cd /tmp
        wget -q "https://files.waveshare.com/wiki/common/St7796s.zip"
        unzip -o St7796s.zip
        cp st7796s.bin "${SCRIPT_DIR}/firmware/st7796s.bin"
        rm -f St7796s.zip st7796s.bin
        cd "${SCRIPT_DIR}"
    else
        log "  st7796s.bin already cached."
    fi

    log "Overlay cache complete."
}

if [ "$CACHE_ONLY" = "1" ]; then
    cache_overlays
    exit 0
fi

# --- Apply configuration patches ---
CONF_FILE="${SCRIPT_DIR}/layer/polypod/rootfs-overlay/etc/polypod/polypod.conf"
CONF_BACKUP="${CONF_FILE}.orig"

# Save original for clean builds
cp "$CONF_FILE" "$CONF_BACKUP"

patch_conf() {
    local key="$1" value="$2"
    sed -i "s|^${key}=.*|${key}=\"${value}\"|" "$CONF_FILE"
}

restore_conf() {
    if [ -f "$CONF_BACKUP" ]; then
        mv "$CONF_BACKUP" "$CONF_FILE"
    fi
}
trap restore_conf EXIT

if [ "$DEV_MODE" = "1" ]; then
    log "Enabling HDMI dev mode..."
    patch_conf "POLYPOD_HDMI_DEV_MODE" "1"
    patch_conf "POLYPOD_TOP_OUTPUT" "HDMI-A-1"
    patch_conf "POLYPOD_TOP_RES" "1920x1080"
fi

if [ "$SPI_FALLBACK" = "1" ]; then
    log "Enabling SPI fallback mode..."
    patch_conf "POLYPOD_SPI_FALLBACK" "1"
fi

if [ "$DEBUG" = "1" ]; then
    log "Enabling debug mode..."
    patch_conf "POLYPOD_DEBUG" "1"
fi

# --- Handle display disabling ---
CONFIG_TXT="${SCRIPT_DIR}/layer/polypod/rootfs-overlay/boot/firmware/config.txt"
CONFIG_TXT_BACKUP="${CONFIG_TXT}.orig"
cp "$CONFIG_TXT" "$CONFIG_TXT_BACKUP"

restore_config_txt() {
    if [ -f "$CONFIG_TXT_BACKUP" ]; then
        mv "$CONFIG_TXT_BACKUP" "$CONFIG_TXT"
    fi
}
trap 'restore_conf; restore_config_txt' EXIT

if [ "$NO_SPI" = "1" ]; then
    log "Disabling SPI display in config.txt..."
    sed -i '/^dtoverlay=mipi-dbi-spi/s/^/#/' "$CONFIG_TXT"
    sed -i '/^dtparam=compatible=st7796s/s/^/#/' "$CONFIG_TXT"
    sed -i '/^dtparam=width=320/s/^/#/' "$CONFIG_TXT"
    sed -i '/^dtparam=reset-gpio/s/^/#/' "$CONFIG_TXT"
    sed -i '/^dtoverlay=ads7846/s/^/#/' "$CONFIG_TXT"
    sed -i '/^extra_transpose_buffer/s/^/#/' "$CONFIG_TXT"
    patch_conf "POLYPOD_BOTTOM_OUTPUT" "HDMI-A-2"
    patch_conf "POLYPOD_BOTTOM_RES" "1920x1080"
fi

if [ "$NO_DSI" = "1" ]; then
    log "Disabling DSI display in config.txt..."
    sed -i '/^display_auto_detect=0/s/^/#/' "$CONFIG_TXT"
    sed -i '/^dtoverlay=vc4-kms-dsi-generic/s/^/#/' "$CONFIG_TXT"
    sed -i '/^dtoverlay=Waveshare_35DSI/s/^/#/' "$CONFIG_TXT"
    patch_conf "POLYPOD_TOP_OUTPUT" "HDMI-A-1"
    patch_conf "POLYPOD_TOP_RES" "1920x1080"
fi

# --- Build arguments ---
BUILD_ARGS=("build" "-S" "$SCRIPT_DIR" "-c" "$CONFIG")

if [ "$FS_ONLY" = "1" ]; then
    BUILD_ARGS+=("-f")
fi

if [ "$IMAGE_ONLY" = "1" ]; then
    BUILD_ARGS+=("-i")
fi

# Override settings via rpi-image-gen variables
if [ -n "$PASSWORD" ]; then
    EXTRA_ARGS+=("IGconf_device_user1pass=$PASSWORD")
fi
if [ -n "$SSH_KEY" ] && [ -f "$SSH_KEY" ]; then
    KEY_CONTENT=$(cat "$SSH_KEY")
    EXTRA_ARGS+=("IGconf_ssh_pubkey_user1=$KEY_CONTENT")
fi
if [ -n "$HOSTNAME_OVERRIDE" ]; then
    EXTRA_ARGS+=("IGconf_device_hostname=$HOSTNAME_OVERRIDE")
fi

if [ ${#EXTRA_ARGS[@]} -gt 0 ]; then
    BUILD_ARGS+=("--" "${EXTRA_ARGS[@]}")
fi

# --- Run build ---
if [ "$DRY_RUN" = "1" ]; then
    log "DRY RUN — would execute:"
    echo "  $RPI_IMAGE_GEN ${BUILD_ARGS[*]}"
    echo ""
    log "polypod.conf modifications:"
    diff "$CONF_BACKUP" "$CONF_FILE" || true
    echo ""
    log "config.txt modifications:"
    diff "$CONFIG_TXT_BACKUP" "$CONFIG_TXT" || true
    exit 0
fi

log "Starting build..."
log "  Config: $CONFIG"
log "  Source: $SCRIPT_DIR"
log "  Command: $RPI_IMAGE_GEN ${BUILD_ARGS[*]}"

"$RPI_IMAGE_GEN" "${BUILD_ARGS[@]}"

log "Build complete! Image is in work/ directory."
log ""
log "Flash with:"
log "  sudo dd if=work/polypod-kiosk.img of=/dev/sdX bs=4M status=progress"
log "  # or use Raspberry Pi Imager"
