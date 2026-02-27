#!/bin/bash
set -euo pipefail

: "${POLYPOD_USER:=pod}"

FLUTTER_DIR="/opt/flutter"
PROFILE_D="/etc/profile.d/flutter.sh"

# Cache dir — rpi-image-gen's work/ persists between builds.
# If POLYPOD_CACHE is set (by the customize hook), reuse cached Flutter SDK.
CACHE_DIR="${POLYPOD_CACHE:-}"

echo "[flutter-init] Installing Flutter into ${FLUTTER_DIR}"

if [[ -n "${CACHE_DIR}" && -d "${CACHE_DIR}/flutter/.git" ]]; then
  echo "[flutter-init] Restoring Flutter from build cache (skipping clone + downloads)"
  cp -a "${CACHE_DIR}/flutter" "${FLUTTER_DIR}"
elif [[ ! -d "${FLUTTER_DIR}/.git" ]]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
else
  echo "[flutter-init] Flutter already present; skipping clone."
fi

chown -R "${POLYPOD_USER}:${POLYPOD_USER}" "${FLUTTER_DIR}"

if [[ ! -f "${PROFILE_D}" ]] || ! grep -q "FLUTTER_HOME" "${PROFILE_D}"; then
  cat > "${PROFILE_D}" <<'EOF'
export FLUTTER_HOME=/opt/flutter
export PATH="$PATH:$FLUTTER_HOME/bin"
EOF
  chmod 0644 "${PROFILE_D}"
fi

echo "[flutter-init] Running flutter precache as ${POLYPOD_USER} (non-root)."
su - "${POLYPOD_USER}" -c '
  set -e
  export FLUTTER_HOME=/opt/flutter
  export PATH="$PATH:$FLUTTER_HOME/bin"
  flutter --version
  flutter config --enable-linux-desktop
  flutter precache --linux
'
# NOTE: "flutter doctor" removed — it wastes time and the [✗] Android/Chrome
# warnings are irrelevant. "flutter precache --linux" gets what we actually need.

# Save to cache for next build
if [[ -n "${CACHE_DIR}" ]]; then
  echo "[flutter-init] Saving Flutter SDK to build cache..."
  mkdir -p "${CACHE_DIR}"
  rm -rf "${CACHE_DIR}/flutter"
  cp -a "${FLUTTER_DIR}" "${CACHE_DIR}/flutter"
fi