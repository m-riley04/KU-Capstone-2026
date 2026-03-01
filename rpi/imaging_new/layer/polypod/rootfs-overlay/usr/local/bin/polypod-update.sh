#!/bin/sh
# =============================================================================
# /usr/local/bin/polypod-update.sh — Called by app-update.timer
# =============================================================================
set -e
. /etc/polypod/polypod.conf

log() { echo "[update] $(date '+%Y-%m-%d %H:%M:%S') $*"; }

[ "$POLYPOD_UPDATE_ENABLED" != "1" ] && { log "Disabled."; exit 0; }
[ -z "$POLYPOD_UPDATE_SERVER" ] && { log "ERROR: No server set"; exit 1; }

SRC="${POLYPOD_UPDATE_USER}@${POLYPOD_UPDATE_SERVER}:${POLYPOD_UPDATE_PATH}"

log "Checking $SRC..."
ssh -o ConnectTimeout=10 -o BatchMode=yes \
    "${POLYPOD_UPDATE_USER}@${POLYPOD_UPDATE_SERVER}" true 2>/dev/null || { log "Unreachable."; exit 0; }

STAGING="${POLYPOD_APP_DIR}/.update-staging"
mkdir -p "$STAGING"

if rsync -az --delete --dry-run "${SRC}/" "$STAGING/" 2>/dev/null | grep -q .; then
    log "Updates found, deploying..."
    rsync -az --delete "${SRC}/" "$STAGING/"
    polypod-deploy.sh "$STAGING"
else
    log "No updates."
fi
