#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="${REPO_DIR:-/home/riley/KU-Capstone-2026}"
PODWORK_DIR="$REPO_DIR/podwork"
POLYPOD_HW_DIR="$REPO_DIR/rpi/src/polypod_hw"
WEB_ROOT="${WEB_ROOT:-/var/www/html}"
LOG_DIR="${LOG_DIR:-$REPO_DIR/logs}"
BACKEND_LOG="$LOG_DIR/backend.log"

echo "Deploying from: $PODWORK_DIR"
cd "$PODWORK_DIR"

mkdir -p "$LOG_DIR"

echo "Installing dependencies"
npm ci

echo "Building frontend"
npm run build:frontend

echo "publishing frontend"
sudo mkdir -p "$WEB_ROOT"
sudo cp ./packages/frontend/index.html "$WEB_ROOT/"
sudo rsync -a --delete ./packages/frontend/dist/ "$WEB_ROOT/"

npm run build:backend

echo "restarting backend"
# stop any previous backend
sudo pkill -f "node ./packages/backend/dist/server.js" || true

nohup npm run start:backend > "$BACKEND_LOG" 2>&1 &

echo "starting demo of hw"

# cd "$POLYPOD_HW_DIR"
# sudo flutter build web
# sudo rsync -a --delete ./build/web/ "$WEB_ROOT/demo/"

echo "deployed"