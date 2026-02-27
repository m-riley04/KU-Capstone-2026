#!/bin/bash
set -euo pipefail

: "${POLYPOD_USER:=pod}"

OUT_DIR="/opt/polypod/app"
CACHE_DIR="${POLYPOD_CACHE:-}"

# ------------------------------------------------------------------
# FAST PATH: If a pre-built bundle exists in the source tree, just
# copy it and skip the entire Flutter build. This avoids the ~10min+
# QEMU-emulated arm64 compilation.
#
# To use: build on a real Pi or arm64 machine, then copy the
# build/linux/arm64/release/bundle/ folder to:
#   <your-imaging-dir>/prebuilt-app/
# ------------------------------------------------------------------
PREBUILT_DIR="${POLYPOD_PREBUILT:-}"
if [[ -n "${PREBUILT_DIR}" && -d "${PREBUILT_DIR}" ]]; then
  echo "[app-build] Using PRE-BUILT bundle from ${PREBUILT_DIR}"
  mkdir -p "${OUT_DIR}"
  rm -rf "${OUT_DIR:?}/"*
  cp -a "${PREBUILT_DIR}/." "${OUT_DIR}/"
  chown -R "${POLYPOD_USER}:${POLYPOD_USER}" "${OUT_DIR}"
  chmod +x "${OUT_DIR}/"* 2>/dev/null || true
  echo "[app-build] Installed pre-built bundle to ${OUT_DIR}"
  exit 0
fi

# ------------------------------------------------------------------
# FULL BUILD PATH: clone repo + flutter build (slow under QEMU)
# ------------------------------------------------------------------
REPO_URL="${POLYPOD_REPO_URL:-https://github.com/m-riley04/KU-Capstone-2026.git}"
REPO_DIR="/opt/polypod/src/KU-Capstone-2026"
APP_SUBDIR="rpi/src/polypod_hw"

export FLUTTER_HOME=/opt/flutter
export PATH="$PATH:$FLUTTER_HOME/bin"

echo "[app-build] Repo: ${REPO_URL}"
echo "[app-build] Dest: ${REPO_DIR}"
echo "[app-build] Out:  ${OUT_DIR}"

mkdir -p "$(dirname "$REPO_DIR")" "$OUT_DIR"

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

BUNDLE_DIR="$(find "${REPO_DIR}/${APP_SUBDIR}/build/linux" -type d -path '*/release/bundle' | head -n 1 || true)"
if [[ -z "${BUNDLE_DIR}" ]]; then
  echo '[app-build] ERROR: Could not find build/linux/*/release/bundle'
  exit 1
fi

echo "[app-build] Bundle at: ${BUNDLE_DIR}"
rm -rf "${OUT_DIR:?}/"*
cp -a "${BUNDLE_DIR}/." "${OUT_DIR}/"
chown -R "${POLYPOD_USER}:${POLYPOD_USER}" "${OUT_DIR}"
chmod +x "${OUT_DIR}/"* 2>/dev/null || true

# Cache the built bundle for next time
if [[ -n "${CACHE_DIR}" ]]; then
  echo "[app-build] Caching built bundle..."
  mkdir -p "${CACHE_DIR}/app-bundle"
  rm -rf "${CACHE_DIR}/app-bundle/"*
  cp -a "${OUT_DIR}/." "${CACHE_DIR}/app-bundle/"
fi

echo "[app-build] Installed bundle to ${OUT_DIR}"