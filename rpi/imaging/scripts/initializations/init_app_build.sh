#!/bin/bash
set -euo pipefail

: "${POLYPOD_USER:=pod}"

REPO_URL="${POLYPOD_REPO_URL:-https://github.com/m-riley04/KU-Capstone-2026.git}"
REPO_DIR="/opt/polypod/src/KU-Capstone-2026"
APP_SUBDIR="rpi/src/polypod_hw" # project root containing pubspec.yaml for the Linux app

OUT_DIR="/opt/polypod/app"
TMP_BUILD="/tmp/polypod_build"

export FLUTTER_HOME=/opt/flutter
export PATH="$PATH:$FLUTTER_HOME/bin"

echo "[app-build] Repo: ${REPO_URL}"
echo "[app-build] Dest: ${REPO_DIR}"
echo "[app-build] Out:  ${OUT_DIR}"

mkdir -p "$(dirname "$REPO_DIR")" "$OUT_DIR" "$TMP_BUILD"

if [[ ! -d "${REPO_DIR}/.git" ]]; then
  git clone --depth 1 "${REPO_URL}" "${REPO_DIR}"
else
  echo "[app-build] Repo already present; pulling latest."
  git -C "${REPO_DIR}" fetch --depth 1 origin
  git -C "${REPO_DIR}" reset --hard origin/HEAD
fi

chown -R "${POLYPOD_USER}:${POLYPOD_USER}" "$(dirname "$REPO_DIR")"

echo "[app-build] Building as ${POLYPOD_USER} (non-root)."
su - "${POLYPOD_USER}" -c "
  set -e
  export FLUTTER_HOME=/opt/flutter
  export PATH=\"\$PATH:\$FLUTTER_HOME/bin\"
  cd '${REPO_DIR}/${APP_SUBDIR}'
  flutter pub get
  flutter build linux --release
"

# Find the release bundle (path varies: x64 vs arm64 directory names)
BUNDLE_DIR="$(find "${REPO_DIR}/${APP_SUBDIR}/build/linux" -type d -path '*/release/bundle' | head -n 1 || true)"
if [[ -z "${BUNDLE_DIR}" ]]; then
  echo '[app-build] ERROR: Could not find build/linux/*/release/bundle'
  exit 1
fi

echo "[app-build] Bundle at: ${BUNDLE_DIR}"
rm -rf "${OUT_DIR:?}/"*
cp -a "${BUNDLE_DIR}/." "${OUT_DIR}/"

# Ensure ownership and execute bit on main binary (name should match your app)
chown -R "${POLYPOD_USER}:${POLYPOD_USER}" "${OUT_DIR}"
chmod +x "${OUT_DIR}/"*

echo "[app-build] Installed bundle to ${OUT_DIR}"