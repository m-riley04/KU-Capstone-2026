#!/bin/sh
# =============================================================================
# /usr/local/bin/polypod-deploy.sh
# Deploy Flutter app bundle and restart services.
# =============================================================================
set -e
. /etc/polypod/polypod.conf

log() { echo "[deploy] $*"; }
die() { echo "[deploy] ERROR: $*" >&2; exit 1; }

BUNDLE_DIR="${POLYPOD_APP_BUNDLE}"
BACKUP_DIR="${POLYPOD_APP_DIR}/.backups"

backup() {
    if [ -d "$BUNDLE_DIR" ] && [ "$(ls -A "$BUNDLE_DIR" 2>/dev/null)" ]; then
        local ts=$(date +%Y%m%d_%H%M%S)
        log "Backing up → ${BACKUP_DIR}/app_${ts}"
        mkdir -p "$BACKUP_DIR"
        cp -a "$BUNDLE_DIR" "${BACKUP_DIR}/app_${ts}"
    fi
}

restart_apps() {
    log "Restarting Flutter app services..."
    systemctl --user restart polypod-top.service || true
    if [ "$POLYPOD_SPI_FALLBACK" = "1" ]; then
        systemctl --user restart polypod-bottom-spi.service || true
    else
        systemctl --user restart polypod-bottom.service || true
    fi
    log "Done. Check: systemctl --user status polypod-top polypod-bottom"
}

rollback() {
    local latest=$(ls -1dt "${BACKUP_DIR}/app_"* 2>/dev/null | head -1)
    [ -z "$latest" ] && die "No backup found"
    log "Rolling back from $latest"
    rm -rf "$BUNDLE_DIR"
    cp -a "$latest" "$BUNDLE_DIR"
}

prune() {
    ls -1dt "${BACKUP_DIR}/app_"* 2>/dev/null | tail -n +4 | while read -r old; do
        log "Pruning: $old"; rm -rf "$old"
    done
}

case "${1:-}" in
    --restart)      restart_apps ;;
    --rollback)     rollback; restart_apps ;;
    --status)
        log "=== Bundle ==="; ls -la "$BUNDLE_DIR/" 2>/dev/null || log "  empty"
        log "=== Backups ==="; ls -1dt "${BACKUP_DIR}/app_"* 2>/dev/null || log "  none"
        log "=== Services ==="
        systemctl --user status polypod-top --no-pager 2>/dev/null || true
        systemctl --user status polypod-bottom --no-pager 2>/dev/null || true ;;
    --help|-h)
        echo "Usage: polypod-deploy.sh [--restart|--rollback|--status|<src_dir>]"
        echo "  <src_dir>  Deploy bundle from this directory"
        echo "  --restart  Restart app services only"
        echo "  --rollback Roll back to previous bundle"
        echo "  --status   Show deployment status" ;;
    *)
        SRC="${1:-}"
        [ -z "$SRC" ] && die "Provide source directory. Use --help for usage."
        [ ! -d "$SRC" ] && die "Not a directory: $SRC"
        backup
        log "Deploying $SRC → $BUNDLE_DIR"
        mkdir -p "$BUNDLE_DIR"
        rsync -a --delete "$SRC/" "$BUNDLE_DIR/"
        chmod +x "$BUNDLE_DIR/"* 2>/dev/null || true
        prune; restart_apps ;;
esac
